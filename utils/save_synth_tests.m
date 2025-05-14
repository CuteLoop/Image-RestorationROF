outputDir = 'results/test_images';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% ---------- Test 1: Zero Noise on Gradient ----------
f1 = generate_synthetic_image('gradient', [128 128]);
u1 = smooth_image_rof(f1, 1.0, 0.01);

figure('Visible','off');
subplot(1,3,1); imagesc(f1); title('Original (Gradient)'); axis image off; colormap gray;
subplot(1,3,2); imagesc(u1); title('Denoised'); axis image off;
subplot(1,3,3); imagesc(abs(f1 - u1)); title('|Original - Denoised|'); axis image off;
exportgraphics(gcf, fullfile(outputDir, 'zero_noise_gradient.png'), 'Resolution', 150);
close(gcf);

% ---------- Test 2: High Noise Recovery ----------
f2_clean = generate_synthetic_image('sinusoidal', [128 128]);
f2_noisy = add_noise(f2_clean, 'gaussian', 0.1);
u2 = smooth_image_rof(f2_noisy, 2.0, 0.01);

figure('Visible','off');
subplot(1,3,1); imagesc(f2_noisy); title('Noisy (Sinusoidal)'); axis image off; colormap gray;
subplot(1,3,2); imagesc(u2); title('Denoised'); axis image off;
subplot(1,3,3); imagesc(abs(u2 - f2_clean)); title('|Clean - Denoised|'); axis image off;
exportgraphics(gcf, fullfile(outputDir, 'high_noise_sinusoidal.png'), 'Resolution', 150);
close(gcf);

% ---------- Test 3: Checkerboard Visual Check ----------
f3 = generate_synthetic_image('checkerboard', [128 128]);
f3_noisy = add_noise(f3, 'gaussian', 0.05);
u3 = smooth_image_rof(f3_noisy, 1.5, 0.01);

figure('Visible','off');
subplot(1,3,1); imagesc(f3_noisy); title('Noisy (Checkerboard)'); axis image off;
subplot(1,3,2); imagesc(u3); title('Denoised'); axis image off;
subplot(1,3,3); imagesc(abs(u3 - f3)); title('|Original - Denoised|'); axis image off;
exportgraphics(gcf, fullfile(outputDir, 'checkerboard_denoising.png'), 'Resolution', 150);
close(gcf);
