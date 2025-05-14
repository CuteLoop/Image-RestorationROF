%% test_smart_search.m  –  sanity, correctness & performance benchmarks for ROF helpers
clc; fprintf('\n=== Running smart-search unit test ===\n');

% -------------------------------------------------- tiny 4-plane toy image
H = 64; W = 64;
[X,Y] = meshgrid(linspace(0,1,W), linspace(0,1,H));
base   = 0.6*X + 0.4*Y;
Iplanar = cat(3, ...
   single(base + 0.02*randn(H,W)), ...  % R plane
   single(base + 0.01*randn(H,W)), ...  % G1 plane
   single(base + 0.01*randn(H,W)), ...  % G2 plane
   single(base + 0.03*randn(H,W)));     % B plane

% -------------------------------------------------- grid / solver structs
grid   = struct('lambdaRange',[1e-4,1],'epsilonRange',[1e-5,1e-2], ...
                'coarseN',6,'refineN',8,'halfDecades',0.3);
solver = struct('nIter',50,'dt',0.2);  % lightweight for test
run_one = @(img) smart_grid_search(img, ...
                   grid.lambdaRange, grid.epsilonRange, ...
                   grid.coarseN, grid.refineN, grid.halfDecades, ...
                   solver.nIter, solver.dt);

%% 1) CPU SEQUENTIAL BASELINE =========================================
fprintf('\n[1] CPU sequential baseline...\n');
% No setup for CPU sequential
set_temp_useGPU(false);
delete(gcp('nocreate')); wait_for_pool_close();

tic;
res_seq = run_one(Iplanar(:,:,1));
t_seq = toc;
fprintf('  CPU seq time   : %6.3f s\n', t_seq);

%% 2) CPU PARALLEL PERFORMANCE =======================================
fprintf('\n[2] CPU parallel (parfor over 4 planes)...\n');
set_temp_useGPU(false);
delete(gcp('nocreate')); wait_for_pool_close();

numW = max(2, feature('numCores'));
pool = parpool('Processes', numW, 'SpmdEnabled', false);
resPar = cell(1,4);
tic;
parfor p = 1:4
    resPar{p} = run_one(Iplanar(:,:,p));
end
t_par = toc;
nW = pool.NumWorkers;
delete(pool); wait_for_pool_close();

fprintf('  CPU par time   : %6.3f s  (workers=%d)\n', t_par, nW);

%% 3) GPU SETUP VS COMPUTE ============================================
fprintf('\n[3] GPU performance...\n');
if exist('rof_config','file') && rof_config() && gpuDeviceCount>0
    % GPU setup (once)
    delete(gcp('nocreate')); wait_for_pool_close();
    t_gpu_setup = tic;
    set_temp_useGPU(true);
    g = gpuDevice;             % select and reset GPU
    run_one(Iplanar(1:2,1:2,1));  % warm‑up for JIT and memory alloc
    t_setup = toc(t_gpu_setup);
    
    % GPU compute (benchmark)  
    t_gpu_compute = tic;
    res_gpu = run_one(Iplanar(:,:,1));
    t_compute = toc(t_gpu_compute);
    
    set_temp_useGPU();
    fprintf('  GPU setup time  : %6.3f s  (JIT + data transfer)\n', t_setup);
    fprintf('  GPU compute time: %6.3f s  (pure ROF solve)\n', t_compute);
    gpuDone = true;
else
    fprintf('  GPU test skipped (no config or no GPU)\n');
    gpuDone = false;
end

%% 4) SANITY & CORRECTNESS CHECK ======================================
fprintf('\n[4] Sanity & correctness check...\n');
f = Iplanar(:,:,1);
% For very small lambda/epsilon, u ≈ f
u = smooth_image_rof(single(f), 1e-6, 1e-3, solver.nIter, solver.dt);
maxErr = max(abs(u(:)-f(:)));
fprintf('  max|u - f|     : %6.3e\n', maxErr);
assert(maxErr < 1e-2, 'Correctness check failed: smoothing deviates too much.');
fprintf('  Sanity check OK.\n');

%% SUMMARY ===========================================================
fprintf('\n=== Test Summary ===\n');
fprintf(' CPU seq time   : %6.3f s\n', t_seq);
fprintf(' CPU par time   : %6.3f s  (workers=%d)\n', t_par, nW);
if gpuDone
    fprintf(' GPU setup time  : %6.3f s\n', t_setup);
    fprintf(' GPU compute time: %6.3f s\n', t_compute);
    fprintf(' Speed-ups: CPU-par=×%.2f, GPU=×%.2f\n', t_seq/t_par, t_seq/t_compute);
else
    fprintf(' GPU test skipped.\n');
end
fprintf('\n✅  All tests executed successfully.\n');

% ======================================================================
function wait_for_pool_close()
    t0 = tic;
    while ~isempty(gcp('nocreate'))
        pause(0.1);
        if toc(t0) > 30, warning('Pool did not close within 30s.'); break; end
    end
end

function set_temp_useGPU(flag)
    if nargin
        setappdata(0,'rof_overrideGPU',logical(flag));
    else
        if isappdata(0,'rof_overrideGPU')
            rmappdata(0,'rof_overrideGPU');
        end
    end
end
