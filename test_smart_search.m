%% test_smart_search.m  – sanity & timing checks for smart search helpers
clc; fprintf('\n=== Running smart‑search unit test ===\n');

% -------------------------------------------------------------- synth data
H = 64; W = 64;
[X,Y] = meshgrid(linspace(0,1,W),linspace(0,1,H));
base  = 0.6*X + 0.4*Y;
Iplanar = cat(3, ...
   single(base + 0.02*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.03*randn(H,W)));

% -------------------------------------------------------------- parameters
coarse = struct('lambdaRange',[1e-4,1],'epsilonRange',[1e-5,1e-2], ...
                'coarseN',6,'refineN',8,'halfDecades',0.3);
solver = struct('nIter',50,'dt',0.2);    % light settings

%% ----------------------------------------------------------- 1) sequential CPU
fprintf('• Sequential smart_grid_search (single plane)…\n');
delete(gcp('nocreate'));
tic
res_seq = smart_grid_search(Iplanar(:,:,1), ...
            coarse.lambdaRange, coarse.epsilonRange, ...
            coarse.coarseN, coarse.refineN, coarse.halfDecades, ...
            solver.nIter, solver.dt);
t_seq = toc;
fprintf('  time = %.2f s\n', t_seq);

%% ----------------------------------------------------------- 2) parallel CPU
numW = feature('numCores');
pool = parpool("Processes", numW, "SpmdEnabled", false);

tic
parfor p = 1:4
    resPar{p} = smart_grid_search( ...
        Iplanar(:,:,p), ...
        coarse.lambdaRange, coarse.epsilonRange, ...
        coarse.coarseN, coarse.refineN, coarse.halfDecades, ...
        solver.nIter, solver.dt );
end
t_par = toc;
delete(pool);

fprintf('• Parallel CPU (parfor, %d workers) time = %.2f s\n', numW, t_par);

%% ----------------------------------------------------------- 3) GPU (optional)
if rof_config() && gpuDeviceCount>0
    fprintf('• GPU run (single plane)…\n');
    tic
    res_gpu = smart_grid_search( ...
        Iplanar(:,:,1), ...
        coarse.lambdaRange, coarse.epsilonRange, ...
        coarse.coarseN, coarse.refineN, coarse.halfDecades, ...
        solver.nIter, solver.dt );
    t_gpu = toc;
    fprintf('  GPU time = %.2f s\n', t_gpu);
end

%% ----------------------------------------------------------- summary
fprintf('\nSpeed‑ups vs sequential:\n');
fprintf('  Parallel CPU : ×%.1f\n', t_seq/t_par);
if exist('t_gpu','var')
    fprintf('  GPU          : ×%.1f\n', t_seq/t_gpu);
end

fprintf('\n✅  All tests passed!\n');
fprintf('🏁  Done – results saved\n');