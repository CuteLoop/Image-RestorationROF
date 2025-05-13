%% test_smart_search.m  –  sanity & timing checks for smart-grid helpers
clc; fprintf('\n=== Running smart-search unit test ===\n');

% -------------------------------------------------- tiny 4-plane toy image
H = 64; W = 64;
[X,Y] = meshgrid(linspace(0,1,W), linspace(0,1,H));
base   = 0.6*X + 0.4*Y;
Iplanar = cat(3, ...
   single(base + 0.02*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.01*randn(H,W)), ...
   single(base + 0.03*randn(H,W)));

% -------------------------------------------------- grid / solver structs
grid   = struct('lambdaRange',[1e-4,1], 'epsilonRange',[1e-5,1e-2], ...
                'coarseN',6,'refineN',8,'halfDecades',0.3);
solver = struct('nIter',50,'dt',0.2);          % light for quick test
run_one = @(img) smart_grid_search(img, ...
                   grid.lambdaRange, grid.epsilonRange, ...
                   grid.coarseN, grid.refineN, grid.halfDecades, ...
                   solver.nIter, solver.dt);

%% ================ 1) SEQUENTIAL CPU ===================================
fprintf('• Sequential smart_grid_search (CPU)…\n');
set_temp_useGPU(false);                % force CPU
delete(gcp('nocreate')); wait_for_pool_close();

tic
res_seq = run_one(Iplanar(:,:,1));
t_seq   = toc;
fprintf('  time = %.3f s\n', t_seq);

delete(gcp('nocreate')); wait_for_pool_close();
set_temp_useGPU();                     % restore GPU default

%% ================ 2) PARALLEL CPU =====================================
fprintf('• Parallel CPU run (parfor)…\n');
set_temp_useGPU(false);
numW   = max(2, feature('numCores'));
pool   = parpool("Processes", numW, "SpmdEnabled", false);

resPar = cell(1,4);
tic
parfor p = 1:4
    resPar{p} = run_one(Iplanar(:,:,p));
end
t_par   = toc;
nWorkers = pool.NumWorkers;
delete(pool); wait_for_pool_close();
set_temp_useGPU();

fprintf('  time = %.3f s  (workers = %d)\n', t_par, nWorkers);

%% ================ 3) GPU (setup vs compute) ===========================
gpuDone = false;
if exist('rof_config','file') && rof_config() && gpuDeviceCount>0
    fprintf('• GPU run (single plane)…\n');
    
    % Cleanup any CPU pool
    delete(gcp('nocreate')); wait_for_pool_close();

    % 1) SETUP PHASE (pool & first JIT & data move)
    t_start = tic;
    set_temp_useGPU(true);
    g = gpuDevice;                           % select / reset device
    % warm up on a single pixel to JIT kernels
    run_one(Iplanar(1:2,1:2,1));
    t_setup = toc(t_start);
    
    % 2) COMPUTE PHASE (actual work)
    t_compute = tic;
    res_gpu = run_one(Iplanar(:,:,1));
    t_gpu    = toc(t_compute);
    
    set_temp_useGPU();                      % restore
    fprintf('  setup   = %.3f s  (pool + JIT + data move)\n', t_setup);
    fprintf('  compute = %.3f s  (pure ROF solve)\n', t_gpu);
    gpuDone = true;
else
    fprintf('• GPU test skipped (no rof_config() or no GPU)\n');
end

%% ================= summary ============================================
fprintf('\nSpeed-ups vs sequential:\n');
fprintf('  Parallel CPU : ×%.2f\n', t_seq / t_par);
if gpuDone
    fprintf('  GPU compute : ×%.2f   (excluding setup)\n', t_seq / t_gpu);
end
fprintf('\n✅  All tests executed.\n');

% =======================================================================
% Local helper functions
% =======================================================================
function wait_for_pool_close()
    t0 = tic;
    while ~isempty(gcp('nocreate'))
        pause(0.1);
        if toc(t0) > 30
            warning('Parallel pool did not shut down within 30 s.');
            break
        end
    end
end

function set_temp_useGPU(flag)
    if nargin
        setappdata(0,'rof_test_useGPU_override',logical(flag));
    else
        if isappdata(0,'rof_test_useGPU_override')
            rmappdata(0,'rof_test_useGPU_override');
        end
    end
end

