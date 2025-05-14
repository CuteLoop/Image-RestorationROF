f = generate_synthetic_image('gradient', [128, 128]);
eps = 0.01;
lambdas = [0.1, 1, 10];
msds = arrayfun(@(l) double(calculate_msd(single(f), l, eps)), lambdas);

fprintf('MSD vs lambda: [%.3f] → [%.5f %.5f %.5f]\n', eps, msds);
assert(issorted(msds), 'MSD should increase with lambda');
disp('✅ MSD monotonicity w.r.t. lambda passed.');
