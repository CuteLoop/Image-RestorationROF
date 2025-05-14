f = generate_synthetic_image('gradient');
lambdas = [0.5, 1.0];
epsilons = [0.01, 0.1];
u = smooth_image_rof(f, lambdas, epsilons);
expected_shape = [size(f), length(lambdas), length(epsilons)];
assert(isequal(size(u), expected_shape), 'Output shape test failed');
disp('✅ Output shape test passed.');
