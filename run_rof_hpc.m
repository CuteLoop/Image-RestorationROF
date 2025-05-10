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

%% --------------------------------------------------------------------
%  Helper – GPU version (locks one device, returns K×L MSD)
% --------------------------------------------------------------------
function msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt)
    gpuDevice;                        % lock the worker's assigned GPU
    f = gpuArray(single(f));
    u = smooth_image_rof(f, lambda, epsilon, nIter, dt);
    err2 = (u - f).^2;
    msd = gather( sqrt( mean(mean(err2,1), 2) ) );  % K×L
end

%% --------------------------------------------------------------------
%  Helper – CPU version (plain calculate_msd)
% --------------------------------------------------------------------
function msd = cpu_plane_sweep(f, lambda, epsilon, nIter, dt)
    msd = calculate_msd(single(f), lambda, epsilon, nIter, dt);
end

