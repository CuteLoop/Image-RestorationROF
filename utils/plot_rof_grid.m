function plot_rof_grid(f, outFile)
% PLOT_ROF_GRID Visualize 4x4 denoising results over log grid of (lambda, epsilon)
%   f        — grayscale input image (single or double)
%   outFile  — optional path to save PNG image of result

    if nargin < 2, outFile = ''; end

    lambdas  = logspace(0, -3, 4);    % 1, 0.1, 0.01, 0.001
    epsilons = logspace(-1, -4, 4);   % 0.1, 0.01, 0.001, 0.0001

    if isa(f, 'uint8') || isa(f, 'uint16')
        f = im2single(f);  % Normalize to [0,1]
    end

    u = smooth_image_rof(f, lambdas, epsilons);

    figure;
    t = tiledlayout(4, 4, 'Padding','compact','TileSpacing','compact');

    for i = 1:4
        for j = 1:4
            nexttile;
            imagesc(u(:,:,i,j)); colormap gray; axis image off;
            title(sprintf('\\lambda=%.3g\\newline\\epsilon=%.3g', ...
                          lambdas(i), epsilons(j)));
        end
    end

    sgtitle('ROF Output Across (\lambda, \epsilon) Grid');

    if ~isempty(outFile)
        [folder,~,~] = fileparts(outFile);
        if ~isempty(folder) && ~isfolder(folder)
            mkdir(folder);
        end
        exportgraphics(gcf, outFile, 'Resolution', 150);
        fprintf('✅ Saved ROF grid to %s\n', outFile);
    end
end
