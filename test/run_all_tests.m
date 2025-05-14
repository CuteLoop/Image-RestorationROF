addpath('..');        % Adds the project root to the path
addpath('../utils');  % (Optional) Add utilities if needed

rng(42);  % or any fixed integer seed
% Set the random seed for reproducibility

disp('=== Running all ROF image restoration tests ===');
test_zero_noise
test_high_noise_recovery
test_monotonic_lambda
test_output_shape
test_boundary_conditions
test_numerical_stability
test_gpu_fallback
test_batch_speedup
test_visual_check
test_msd_surface_plot
disp('=== ✅ All tests complete ===');
