u_true = generate_synthetic_image('sinusoidal');
f = add_noise(u_true, 'gaussian', 0.1);
u = smooth_image_rof(f, 2.0, 0.01);
msd = calculate_msd(f, 2.0, 0.01);
assert(msd > 0.01, 'High noise recovery test failed');
disp('✅ High noise recovery test passed.');
