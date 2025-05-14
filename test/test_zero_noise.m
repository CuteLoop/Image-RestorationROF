f = generate_synthetic_image('gradient');
u = smooth_image_rof(f, 1.0, 0.01);
msd = calculate_msd(f, 1.0, 0.01);
assert_near(msd, 0, 1e-6, 'Zero noise test failed');
disp('✅ Zero noise test passed.');
