addpath('../')

outputDir = 'results/test_grid_5x5';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

types = {'gradient', 'sinusoidal', 'checkerboard'};
lambdaList = [0.1, 0.3, 0.5, 1.0, 2.0];
epsilonList = [0.0001, 0.002, 0.005, 0.01, 0.02];
nL = length(lambdaList);
nE = length(epsilonList);

for t = 1:length(types)
    imgType = types{t};

    % Generate clean and noisy images
    f_clean = generate_synthetic_image(imgType, [128 128]);
    switch imgType
        case 'gradient'
            f_noisy = f_clean;  % No noise
        case 'sinusoidal'
            f_noisy = add_noise(f_clean, 'gaussian', 0.1);
        case 'checkerboard'
            f_noisy = add_noise(f_clean, 'gaussian', 0.05);
    end

    % Create a grid of nL x nE denoised outputs
    fig = figure('Visible','off');
    tiledlayout(nL, nE, 'Padding','compact', 'TileSpacing','compact');

    for i = 1:nL
        for j = 1:nE
            lam = lambdaList(i);
            eps = epsilonList(j);

            u = smooth_image_rof(f_noisy, lam, eps);

            nexttile;
            imagesc(u); colormap gray; axis image off;
            title(sprintf('\\lambda=%.2f, \\epsilon=%.4f', lam, eps), ...
                  'FontSize', 7, 'Interpreter','tex');
        end
    end

    % Save figure
    filename = sprintf('%s_grid.png', imgType);
    exportgraphics(fig, fullfile(outputDir, filename), ...
        'Resolution', 150, 'BackgroundColor', 'white');
    close(fig);
    fprintf(' Saved: %s\n', fullfile(outputDir, filename));
end
