clear; clc; format compact
delete(gcp('nocreate'));

% Image and parameter setup
raw_img = './images/DSC00099.ARW';
fprintf('Reading %s …\n', raw_img);
cfa = rawread(raw_img);
Iplanar = raw2planar(cfa);

lambda = logspace(-3, 0, 20);
epsilon = logspace(-4, -1, 20);
nIter = 300;
dt = 0.25;

% Initialize
useGPU = gpuDeviceCount > 0;
msdCube = zeros(numel(lambda), numel(epsilon), 4, 'single');

if useGPU
    % === SERIAL GPU EXECUTION (safe from memory overflow) ===
    for p = 1:4
        fprintf("🟦 Running GPU smoothing for plane %d...\n", p);
        setappdata(0, 'rof_overrideGPU', true);  % Force GPU
        msdCube(:,:,p) = calculate_msd(Iplanar(:,:,p), lambda, epsilon, nIter, dt);
        gpuDevice([]);  % ✅ Reset GPU to release memory
    end
    rmappdata(0, 'rof_overrideGPU');

else
    % === CPU MULTITHREAD PARALLEL EXECUTION ===
    fprintf("🟧 Running CPU smoothing using parallel pool...\n");
    localC = parcluster('local');
    pool = parpool(localC, localC.NumWorkers);
    
    setappdata(0, 'rof_overrideGPU', false);  % Force CPU
    parfor p = 1:4
        msdCube(:,:,p) = calculate_msd(Iplanar(:,:,p), lambda, epsilon, nIter, dt);
    end
    delete(pool);
    rmappdata(0, 'rof_overrideGPU');
end

% Save results
save('rof_results_singlepool.mat', 'lambda', 'epsilon', 'msdCube');
disp('🏁 Done – results saved');
