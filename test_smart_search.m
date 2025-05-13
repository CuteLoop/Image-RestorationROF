%% test_smart_search.m  – sanity & timing checks for smart‑grid helpers
clc; fprintf('\n=== Running smart‑search unit test ===\n');

% ------------------------- synthetic 4‑plane toy data ------------------
H = 64; W = 64;
[X,Y] = meshgrid(linspace(0,1,W), linspace(0,1,H));
base   = 0.6*X + 0.4*Y;
Iplanar = cat(3, ...
   single(base + 0.02*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.03*randn(H,W)));

% ------------------------- parameter structs ---------------------------
grid   = struct('lambdaRange',[1e-4,1], 'epsilonRange',[1e-5,1e-2], ...
                'coarseN',6,'refineN',8,'halfDecades',0.3);
solver = struct('nIter',50,'dt',0.2);    % light for quick test

run_one = @(img) smart_grid_search(img, ...
                   grid.lambdaRange, grid.epsilonRange, ...
                   grid.coarseN, grid.refineN, grid.halfDecades, ...
                   solver.nIter, solver.dt);

%% === 1) SEQUENTIAL CPU ===============================================
fprintf('• Sequential smart_grid_search (single plane)…\n');
delete(gcp('nocreate'));  wait_for_pool_close();

tic
res_seq = run_one(Iplanar(:,:,1));
t_seq   = toc;
fprintf('  time = %.3f s\n', t_seq);

delete(gcp('nocreate'));  wait_for_pool_close();

%% === 2) PARALLEL CPU ==================================================
fprintf('• Parallel CPU run (parfor)…\n');
numW = max(2, feature('numCores'));
pool = parpool("Processes", numW, "SpmdEnabled", false);

resPar = cell(1,4);
tic
parfor p = 1:4
    resPar{p} = run_one(Iplanar(:,:,p));
end
t_par = toc;
nWorkers = pool.NumWorkers;   % grab count before deleting
delete(pool);  wait_for_pool_close();

fprintf('  time = %.3f s  (workers = %d)\n', t_par, nWorkers);

%% === 3) GPU (optional) ===============================================
gpuDone = false;
if exist('rof_config','file') && rof_config() && gpuDeviceCount>0
    try
        fprintf('• GPU run (single plane)…\n');
        tic
        res_gpu = run_one(Iplanar(:,:,1));
        t_gpu = toc;
        fprintf('  GPU time = %.3f s\n', t_gpu);
        gpuDone = true;
    catch ME
        warning('GPU test failed: %s', ME.message);
    end
else
    fprintf('• GPU test skipped (no rof_config() or no GPU available)\n');
end

%% === summary ==========================================================
fprintf('\nSpeed‑ups vs sequential:\n');
fprintf('  Parallel CPU : ×%.2f\n', t_seq / t_par);
if gpuDone
    fprintf('  GPU          : ×%.2f\n', t_seq / t_gpu);
end
fprintf('\n✅  All tests executed.\n');

% ======================================================================
% Local helper functions
% ======================================================================
function wait_for_pool_close()
% Block until MATLAB's current parallel pool is fully shut down
t0 = tic;
while ~isempty(gcp('nocreate'))
    pause(0.1);
    if toc(t0) > 30      % 30‑second safety timeout
        warning('Pool did not shut down within 30 s.');
        break
    end
end
end
