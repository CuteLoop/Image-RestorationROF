%% test_smart_search.m  –  sanity & timing checks for smart‑grid helpers
clc; fprintf('\n=== Running smart‑search unit test ===\n');

% -------------------------------------------------- tiny 4‑plane toy image
H = 64; W = 64;
[X,Y]  = meshgrid(linspace(0,1,W), linspace(0,1,H));
base   = 0.6*X + 0.4*Y;
Iplanar = cat(3, ...
   single(base + 0.02*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.03*randn(H,W)));

% -------------------------------------------------- grid / solver structs
grid   = struct('lambdaRange',[1e-4,1], 'epsilonRange',[1e-5,1e-2], ...
                'coarseN',6,'refineN',8,'halfDecades',0.3);
solver = struct('nIter',50,'dt',0.2);          % light settings
run_one = @(img) smart_grid_search(img, ...
                   grid.lambdaRange, grid.epsilonRange, ...
                   grid.coarseN, grid.refineN, grid.halfDecades, ...
                   solver.nIter, solver.dt);

%% ================ 1) sequential CPU baseline ===========================
fprintf('• Sequential smart_grid_search (CPU)…\n');
set_temp_useGPU(false);                % <‑‑ TEMPORARILY DISABLE GPU
delete(gcp('nocreate')); wait_for_pool_close();

tic
res_seq = run_one(Iplanar(:,:,1));
t_seq   = toc;
fprintf('  time = %.3f s\n', t_seq);

delete(gcp('nocreate')); wait_for_pool_close();
set_temp_useGPU();                     % restore default GPU setting

%% ================ 2) parallel CPU timing ==============================
fprintf('• Parallel CPU run (parfor)…\n');
set_temp_useGPU(false);                % ensure workers stay on CPU
numW   = max(2, feature('numCores'));  % at least 2
pool   = parpool("Processes", numW, "SpmdEnabled", false);

resPar = cell(1,4);
tic
parfor p = 1:4
    resPar{p} = run_one(Iplanar(:,:,p));
end
t_par   = toc;
nWorkers = pool.NumWorkers;            % store before deleting
delete(pool); wait_for_pool_close();
set_temp_useGPU();                     % restore default

fprintf('  time = %.3f s  (workers = %d)\n', t_par, nWorkers);

%% ================ 3) explicit GPU timing (optional) ===================
gpuDone = false;
if exist('rof_config','file') && rof_config() && gpuDeviceCount>0
    fprintf('• GPU run (single plane)…\n');
    try
        tic
        set_temp_useGPU(true);         % force helpers to GPU
        res_gpu = run_one(Iplanar(:,:,1));
        t_gpu   = toc;
        fprintf('  GPU time = %.3f s\n', t_gpu);
        gpuDone = true;
    catch ME
        warning('GPU test failed: %s', ME.message);
    end
    set_temp_useGPU();                 % restore original flag
else
    fprintf('• GPU test skipped (no rof_config() or no GPU available)\n');
end

%% ================ summary =============================================
fprintf('\nSpeed‑ups vs sequential:\n');
fprintf('  Parallel CPU : ×%.2f\n', t_seq / t_par);
if gpuDone
    fprintf('  GPU          : ×%.2f\n', t_seq / t_gpu);
end
fprintf('\n✅  All tests executed.\n');

% =======================================================================
% Local helper functions  (available since R2016b scripts can hold them)
% =======================================================================
function wait_for_pool_close()
% Block until any interactive pool is completely shut down (≤30 s)
t0 = tic;
while ~isempty(gcp('nocreate'))
    pause(0.1);
    if toc(t0) > 30
        warning('Parallel pool did not shut down within 30 s.');
        break
    end
end
end

function set_temp_useGPU(flag)
% Temporarily override rof_config() without editing the file.
% Usage: set_temp_useGPU(true/false) to override, set_temp_useGPU() to clear.
if nargin
    setappdata(0,'rof_test_useGPU_override',logical(flag));
else
    if isappdata(0,'rof_test_useGPU_override')
        rmappdata(0,'rof_test_useGPU_override');
    end
end
end
