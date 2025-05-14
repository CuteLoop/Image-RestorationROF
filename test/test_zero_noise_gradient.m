rng(42);  % for consistency
f = generate_synthetic_image('gradient', [128, 128]);
u = smooth_image_rof(f, 1.0, 0.01);
msd = calculate_msd(f, 1.0, 0.01);

fprintf('[Gradient] MSD: %.6e\n', msd);
assert(msd > 0.5, 'ROF did not significantly smooth gradient image');
disp('✅ Zero noise test with gradient passed.');
