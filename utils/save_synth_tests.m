outputDir = 'results/test_grid';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

types = {'gradient', 'sinusoidal', 'checkerboard'};
lambdaList = [0.5, 1.0, 2.0];
epsilonList = [0.005, 0.01, 0.02];

for t = 1:length(types)
    imgType = types{t};

    switch imgType
        case 'gradient'
            f_clean = generate_synthetic_image(imgType, [128 128]);
            f_noisy = f_clean;  % No noise
        case 'sinusoidal'
            f_clean = generate_synthetic_image(imgType, [128 128]);
            f_noisy = add_noise(f_clean, 'gaussian', 0.1);
        case 'checkerboard'
            f_clean = generate_synthetic_image(imgType, [128 128]);
            f_noisy = add_noise(f_clean, 'gaussian', 0.05);
    end

    for i = 1:length(lambdaList)
        for j = 1:length(epsilonList)
            lam = lambdaList(i);
            eps = epsilonList(j);

            u = smooth_image_rof(f_noisy, lam, eps);

            fig = figure('Visible','off');
            subplot(1,3,1); imagesc(f_noisy); title('Noisy'); axis image off; colormap gray;
            subplot(1,3,2); imagesc(u); title(sprintf('λ=%.2f, ε=%.3f', lam, eps)); axis image off;
            subplot(1,3,3); imagesc(abs(u - f_clean)); title('|u - f|'); axis image off;

            fname = sprintf('%s_lam%.2f_eps%.3f.png', imgType, lam, eps);
            exportgraphics(fig, fullfile(outputDir, fname), 'Resolution', 150);
            close(fig);
        end
    end
end
