f = generate_synthetic_image('checkerboard');
eps = 0.01;
lambdas = [0.1, 1, 10];
msd_vals = arrayfun(@(l) calculate_msd(f, l, eps), lambdas);
assert(issorted(msd_vals), 'MSD should increase with lambda');
disp('✅ Monotonic lambda test passed.');
