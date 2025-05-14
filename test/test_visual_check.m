f = generate_synthetic_image('checkerboard');
f = add_noise(f, 'gaussian', 0.1);
u = smooth_image_rof(f, 2.0, 0.01);
plot_rof_result(f, u);
title('Visual Test: Denoising');
disp('✅ Visual test (manual check).');
