%% --------------------------------------------------------------------
%  run_rof_hpc.m  —  ROF TV sweep on whatever resources MATLAB sees
%                   (single parallel pool only)
% --------------------------------------------------------------------
clear;  clc;  format compact

%% 0. Close any stray pool from a previous run
delete(gcp('nocreate'));

%% 1. Load RAW and split into RGGB
raw_img_filename = fullfile('.', 'images', 'DSC00099.ARW');
fprintf('Reading %s …\n', raw_img_filename);
cfa      = rawread(raw_img_filename);
Iplanar  = raw2planar(cfa);
fPlanes  = {Iplanar(:,:,1), Iplanar(:,:,2), ...
            Iplanar(:,:,3), Iplanar(:,:,4)};
colourName = ["R","G1","G2","B"];

%% 2. Parameter grid
lambda   = logspace(-3, 0, 20);
epsilon  = logspace(-4, -1, 20);
[K,L]    = deal(numel(lambda), numel(epsilon));
nIter = 300;  dt = 0.25;

%% 3. Detect resources and open ONE pool
numGPU = gpuDeviceCount("available");
localC = parcluster('local');
maxW   = localC.NumWorkers;              % e.g. 16 on your node

% Reserve up to one host thread per GPU (rule‑of‑thumb)
cpuWorkers = max(maxW - numGPU, 1);
totalWorkers = cpuWorkers + numGPU;      % <= maxW
pool = parpool("Processes", totalWorkers, "SpmdEnabled", true);
fprintf('Pool started with %d workers  (%d GPUs, %d CPU workers)\n',...
        totalWorkers, numGPU, cpuWorkers);

%% 4. Assign planes to workers with PARFEVAL
% We will launch FOUR tasks (one per plane).  The first 'numGPU' workers
% lock GPUs 1..numGPU and process the heaviest planes (R, B here).
planeOrder = [1 4 2 3];   % R, B go first (GPU); G1, G2 next (CPU)
F = parallel.FevalFuture.empty(0,4);

for t = 1:4
    pIdx = planeOrder(t);
    if t <= numGPU          % send to GPU‑designated worker
        F(t) = parfeval(pool, @gpu_plane_sweep, 1, ...
                        fPlanes{pIdx}, lambda, epsilon, nIter, dt);
        fprintf('  Worker %d → GPU task on %s‑plane\n', t, colourName(pIdx));
    else                    % CPU task
        F(t) = parfeval(pool, @cpu_plane_sweep, 1, ...
                        fPlanes{pIdx}, lambda, epsilon, nIter, dt);
        fprintf('  Worker %d → CPU task on %s‑plane\n', t, colourName(pIdx));
    end
end

%% 5. Gather results in original RGGB order
msdCube = nan(K,L,4,'single');
for f = 1:4
    [completedIdx, msd] = fetchNext(F);
    pIdx = planeOrder(completedIdx);
    msdCube(:,:,pIdx) = msd;
    fprintf('Finished %s‑plane (task %d of 4)\n', colourName(pIdx), f);
end

%% 6. Plot stacked MSD surfaces
figure('Name','MSD surfaces – RGGB');
hold on, alphaVal = 0.65;
for p = 1:4
    surf(lambda, epsilon, msdCube(:,:,p).', ...
         'EdgeColor','none','FaceAlpha',alphaVal);
end
set(gca,'XScale','log','YScale','log'), view(45,25)
xlabel('\lambda'), ylabel('\epsilon'), zlabel('MSD')
legend(colourName), title('ROF MSD surfaces for raw sensor planes')

%% 7. Save & tidy up
save('rof_results_singlepool.mat','lambda','epsilon','msdCube','-v7.3');
fprintf('Saved results to  rof_results_singlepool.mat\n');

delete(pool);
fprintf('All done.\n');
% ---------------------------------------------------------------------
%  gpu_plane_sweep  –  memory‑adaptive ROF sweep on ONE colour plane
% ---------------------------------------------------------------------
function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)

    %-- lock the GPU assigned to this worker and query memory -----------
    g = gpuDevice;
    freeBytes = g.AvailableMemory;            % what CUDA reports
    maxBytesOneVar = 0.8 * g.TotalMemory;     % MATLAB guard (≈ 80 %)

    fprintf('[GPU%d]  Free: %.1f GB   MaxPerVar: %.1f GB\n', ...
            g.Index, freeBytes/2^30, maxBytesOneVar/2^30);

    %-- move the current plane to device (single precision) -------------
    f = gpuArray(single(fHost));
    [H,W] = size(f);

    %-- bytes required for one additional image in smooth_image_rof -----
    %   (u, ux, uy, gmag  → 4 arrays; plus a small overhead factor)
    bytesPerImage = 4 * H * W * 4 * 1.10;    % (~1.1 safety)

    %-- choose #pairs that can fit under both limits --------------------
    avail      = min(freeBytes, maxBytesOneVar) - numel(f)*4;  % leave f in RAM
    maxPairs   = floor( avail / bytesPerImage );
    blk        = max(1, 2^floor(log2(maxPairs)));  % power of two, at least 1

    fprintf('[GPU%d]  Processing %d×%d grid in blocks of %d×%d pairs\n', ...
            g.Index, numel(lambda), numel(epsilon), blk, blk);

    %-- container for final MSD surface (host side) ---------------------
    msd = zeros(numel(lambda), numel(epsilon), 'single');

    %-- iterate over blocks ---------------------------------------------
    for k0 = 1:blk:numel(lambda)
        kIdx = k0 : min(k0+blk-1, numel(lambda));
        lamSub = lambda(kIdx);

        for l0 = 1:blk:numel(epsilon)
            lIdx  = l0 : min(l0+blk-1, numel(epsilon));
            epsSub = epsilon(lIdx);

            % --- ROF solver for this sub‑grid (vectorised inside) -----
            uSub = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

            % --- accumulate MSD for the sub‑grid ----------------------
            err2 = (uSub - f).^2;
            msd(kIdx,lIdx) = gather( sqrt( mean(mean(err2,1), 2) ) );
        end
    end
end


% ---------------------------------------------------------------------
%  cpu_plane_sweep  –  memory‑adaptive ROF sweep on ONE colour plane
%                      (robust free‑RAM detection)
% ---------------------------------------------------------------------
function msd = cpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)

    % -------------------------------------------------------------- 1 --
    %  Free‑RAM query with three fallbacks
    % --------------------------------------------------------------
    freeBytes = NaN;

    % 1A.  First choice: memory() (Windows & many Linux w/ Java)
    if exist('memory','file') == 2
        try
            m = memory;                         % struct
            freeBytes = m.MemAvailableAllArrays;
        catch
        end
    end

    % 1B.  Second choice: /proc/meminfo (Linux)
    if isnan(freeBytes) && isunix
        try
            fid = fopen('/proc/meminfo','r');
            txt = textscan(fid,'%s%s%s');
            fclose(fid);
            idx = find(strcmp(txt{1},'MemAvailable:'));
            if ~isempty(idx)
                freeBytes = str2double(txt{2}{idx}) * 1024;  % kB → B
            end
        catch
        end
    end

    % 1C.  Last resort: assume 4 GB free
    if isnan(freeBytes) || freeBytes<=0
        warning('Could not query free host RAM – assuming 4 GB.');
        freeBytes = 4 * 2^30;
    end

    freeBytes = 0.8 * double(freeBytes);     % keep 20 % safety margin

    % -------------------------------------------------------------- 2 --
    %  Memory model: how many (λ,ε) pairs fit simultaneously?
    % --------------------------------------------------------------
    f = single(fHost);               % work in single precision
    [H,W] = size(f);

    bytesPerImage = 4 * H * W * 4 * 1.10;   % u,ux,uy,gmag +10 %

    maxPairs = floor( (freeBytes - bytesPerImage) / bytesPerImage );
    blk      = max(1, 2^floor(log2(maxPairs)));      % ≥1, power‑of‑two

    fprintf('[CPU]  Free ≈ %.1f GB → block %d×%d pairs\n',...
            freeBytes/2^30, blk, blk);

    % -------------------------------------------------------------- 3 --
    %  Block‑wise loop over grid
    % --------------------------------------------------------------
    K = numel(lambda);   L = numel(epsilon);
    msd = zeros(K, L, 'single');

    for k0 = 1:blk:K
        kIdx = k0 : min(k0+blk-1, K);
        lamSub = lambda(kIdx);

        for l0 = 1:blk:L
            lIdx  = l0 : min(l0+blk-1, L);
            epsSub = epsilon(lIdx);

            uSub = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

            err2 = (uSub - f).^2;
            msd(kIdx,lIdx) = sqrt( mean(mean(err2,1), 2) );
        end
    end
end
