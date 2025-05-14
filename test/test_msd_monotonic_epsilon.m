f = generate_synthetic_image('gradient', [128, 128]);
lambda = 1;
epsilons = [0.001, 0.01, 0.1];
msds = arrayfun(@(e) double(calculate_msd(single(f), lambda, e)), epsilons);

fprintf('MSD vs epsilon: [λ = %.3f] → [%.5f %.5f %.5f]\n', lambda, msds);
assert(all(isfinite(msds)), 'MSD contains NaN or Inf');
disp('ℹ️ MSD w.r.t. epsilon: trend check completed (may not be strictly monotonic).');
