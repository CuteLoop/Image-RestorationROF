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
%   gpu_plane_sweep  (safe‑memory version)
%   • processes the (λ,ε) grid in blocks to stay under GPU limits
% ---------------------------------------------------------------------
function msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt)

    g  = gpuDevice;                       % lock & query this GPU
    freeMem = g.AvailableMemory;          % bytes

    f = gpuArray(single(f));              % H×W  (≈ 24 MB single)

    % ---- estimate per‑pixel bytes we’ll allocate in the solver ----
    H = size(f,1);  W = size(f,2);
    bytesPerImage = 4 * H * W;            % u, ux, uy, gmag  (single)
    safetyFactor  = 1.2;                  % head‑room for other arrays
    bytesAvail    = freeMem / safetyFactor;

    % maximum #parameter‑pairs we can fit at once
    maxPairs = floor( bytesAvail / bytesPerImage );

    % choose a block size (powers of two keep things neat)
    blk   = max(2, 2^floor(log2(maxPairs)));     % e.g. 8,16,…

    % pre‑allocate final MSD surface (K×L)
    msd = zeros(numel(lambda), numel(epsilon), 'single','gpuArray');

    % iterate over blocks of (λ,ε)
    for k0 = 1:blk:numel(lambda)
        kIdx = k0 : min(k0+blk-1, numel(lambda));
        lamSub = lambda(kIdx);

        for l0 = 1:blk:numel(epsilon)
            lIdx = l0 : min(l0+blk-1, numel(epsilon));
            epsSub = epsilon(lIdx);

            % ---- solve ROF on this sub‑grid ----
            u = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

            % ---- MSD for the sub‑grid ----
            err2 = (u - f).^2;
            msd(kIdx,lIdx) = sqrt( mean(mean(err2,1), 2) );
        end
    end

    msd = gather(msd);                    % back to host RAM
end


%% --------------------------------------------------------------------
%  Helper – CPU version (plain calculate_msd)
% --------------------------------------------------------------------
function msd = cpu_plane_sweep(f, lambda, epsilon, nIter, dt)
    msd = calculate_msd(single(f), lambda, epsilon, nIter, dt);
end

