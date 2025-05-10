%% --------------------------------------------------------------------
%  run_rof_hpc.m  —  resource‑aware ROF TV sweep
% --------------------------------------------------------------------
%  * Detects:  #GPUs  (gpuDeviceCount)
%              #CPU workers available in local profile
%  * Splits the four RGGB planes across GPUs first, remaining planes
%    on a CPU pool (vectorised calculate_msd).
%  * Works even if 0 GPUs are present (all planes go to CPUs).
% --------------------------------------------------------------------

clear; clc; format compact

%% 1.  Load RAW and extract planes
raw_img_filename = fullfile('.', 'images', 'DSC00099.ARW');
fprintf('Reading %s …\n', raw_img_filename);
cfa      = rawread(raw_img_filename);
Iplanar  = raw2planar(cfa);              % H×W×4   (R,G1,G2,B)

colourName = ["R","G1","G2","B"];
fPlanes    = {Iplanar(:,:,1), Iplanar(:,:,2), ...
              Iplanar(:,:,3), Iplanar(:,:,4)};

%% 2.  Parameter grid
lambda   = logspace(-3, 0, 20);          % 1e‑3 … 1
epsilon  = logspace(-4, -1, 20);         % 1e‑4 … 0.1
[K, L]   = deal(numel(lambda), numel(epsilon));

nIter = 300;   dt = 0.25;                % solver controls

%% 3.  Discover resources
numGPU = gpuDeviceCount("available");
cpuLocal = parcluster('local');
maxCPUWorkers = cpuLocal.NumWorkers;

fprintf('\n===== RESOURCE SUMMARY =====\n');
fprintf('GPUs available : %d\n', numGPU);
fprintf('CPU workers    : %d\n', maxCPUWorkers);
fprintf('============================\n\n');

%% 4.  Decide plane assignment
gpuPlaneIdx   = 1:min(numGPU,4);             % planes handled on GPUs
cpuPlaneIdx   = setdiff(1:4, gpuPlaneIdx);   % remaining planes

%% 5.  Spin up pools
% -- GPU pool (if any) -------------------------------------------------
if numGPU > 0
    gpool = parpool("Processes", numGPU, "SpmdEnabled", true);
    fprintf('GPU pool with %d labs started.\n', numGPU);
else
    gpool = [];                             %#ok<NASGU>
    fprintf('No GPUs detected – running everything on CPUs.\n');
end

% -- CPU pool ----------------------------------------------------------
% Leave one core free per GPU lab for host‑to‑device traffic (rule‑of‑thumb)
cpuReserve = 2 * numGPU;
cpuWorkers = max(maxCPUWorkers - cpuReserve, 1);
cpuPool    = parpool("Processes", cpuWorkers, "SpmdEnabled", false);
fprintf('CPU pool with %d workers started.\n\n', cpuWorkers);

%% 6.  Launch GPU jobs (non‑blocking)
F = parallel.FevalFuture.empty(0, numel(gpuPlaneIdx));
for k = 1:numel(gpuPlaneIdx)
    pIdx = gpuPlaneIdx(k);
    F(k) = parfeval(gpool,@gpu_plane_sweep,1, ...
                    fPlanes{pIdx}, lambda, epsilon, nIter, dt);
    fprintf('GPU‑lab %d handling %s‑plane\n', k, colourName(pIdx));
end

%% 7.  CPU pool processes remaining planes
msdCPU = zeros(K,L,numel(cpuPlaneIdx),'single');
parfor (idx = 1:numel(cpuPlaneIdx), cpuWorkers)
    pIdx = cpuPlaneIdx(idx);
    fprintf('CPU worker denoising %s‑plane …\n', colourName(pIdx));
    msdCPU(:,:,idx) = calculate_msd( ...
                fPlanes{pIdx}, lambda, epsilon, nIter, dt );
end

%% 8.  Collect GPU results
msdGPU = cell(1,numel(gpuPlaneIdx));
for k = 1:numel(gpuPlaneIdx)
    msdGPU{k} = fetchOutputs(F(k));
end

%% 9.  Assemble MSD cube in RGGB order
msdCube = nan(K,L,4,'single');
msdCube(:,:,gpuPlaneIdx) = cat(3, msdGPU{:});
msdCube(:,:,cpuPlaneIdx) = msdCPU;

%% 10.  Plot
figure('Name','MSD surfaces – RGGB (resource‑aware)');
hold on
for p = 1:4
    surf(lambda, epsilon, msdCube(:,:,p).', ...
        'EdgeColor','none','FaceAlpha',0.6);
end
set(gca,'XScale','log','YScale','log'), view(45,25)
xlabel('\lambda'), ylabel('\epsilon'), zlabel('MSD')
legend(colourName), title('ROF MSD surfaces for raw planes')

%% 11.  Save & shutdown
save('rof_results_auto.mat','lambda','epsilon','msdCube','-v7.3');
fprintf('\nResults saved in  rof_results_auto.mat\n');

delete(gpool);            % OK if gpool is []
delete(gcp('nocreate'));  % closes CPU pool
fprintf('Pools shut down.  All done.\n');

%% --------------------------------------------------------------------
%  Helper (GPU) -------------------------------------------------------
%  Each GPU lab receives ONE plane & full grid, returns K×L MSD.
% --------------------------------------------------------------------
function msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt)
    gpuDevice(labindex);                     % lock a unique GPU
    f = gpuArray(single(f));
    u = smooth_image_rof(f, lambda, epsilon, nIter, dt);
    err2 = (u - f).^2;
    msd  = gather( sqrt( mean(mean(err2,1), 2) ) );  % K×L
end
