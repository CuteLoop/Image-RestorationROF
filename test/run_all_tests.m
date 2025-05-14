addpath('..');        % Adds the project root to the path
addpath('../utils');  % Add utilities if needed

rng(42);  % Set the random seed for reproducibility

% === Prepare logs folder ===
logDir = fullfile('test', 'logs');
if ~exist(logDir, 'dir')
    mkdir(logDir);
end

% Create timestamped and latest log files
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
logfile_history = fullfile(logDir, sprintf('test_log_%s.txt', timestamp));
logfile_last = fullfile(logDir, 'test_log_last.txt');
fid_hist = fopen(logfile_history, 'w');
fid_last = fopen(logfile_last, 'w');

fprintf(fid_hist, '=== ROF Image Restoration Test Log (%s) ===\n\n', timestamp);
fprintf(fid_last,  '=== ROF Image Restoration Test Log (%s) ===\n\n', timestamp);

% === Test list ===
testList = {
    'test_zero_noise_constant_loose'
    'test_zero_noise_constant_strict'
    'test_zero_noise_gradient'
    'test_msd_monotonic_lambda'
    'test_msd_monotonic_epsilon'
    'test_high_noise_recovery'
    'test_monotonic_lambda'
    'test_output_shape'
    'test_boundary_conditions'
    'test_numerical_stability'
    'test_gpu_fallback'
    'test_batch_speedup'
    'test_visual_check'
    'test_msd_surface_plot'
};

results = strings(length(testList), 1);

% === Run tests ===
for i = 1:length(testList)
    testName = testList{i};
    try
        feval(testName);
        results(i) = "✅ PASS";
        fprintf(fid_hist, '[PASS] %s\n', testName);
        fprintf(fid_last, '[PASS] %s\n', testName);
    catch ME
        results(i) = "❌ FAIL";
        fprintf(2, '\n❌ Error in %s:\n%s\n', testName, ME.message);
        fprintf(fid_hist, '[FAIL] %s\n  %s\n', testName, ME.message);
        fprintf(fid_last, '[FAIL] %s\n  %s\n', testName, ME.message);
    end
end

% === Summary ===
fprintf(fid_hist, '\n=== Summary ===\n');
fprintf(fid_last,  '\n=== Summary ===\n');
for i = 1:length(testList)
    fprintf(fid_hist, '%-35s %s\n', testList{i}, results(i));
    fprintf(fid_last, '%-35s %s\n', testList{i}, results(i));
end

fclose(fid_hist);
fclose(fid_last);

disp('=== ✅ All tests complete ===');
fprintf('Test logs saved to:\n  %s\n  %s\n', logfile_history, logfile_last);
