function plot_rof_grid(f, outFile, planeLabel, colorize)
% PLOT_ROF_GRID Visualize 4x4 grid of ROF denoised images
%   f         — grayscale image
%   outFile   — optional file path to save PNG
%   planeLabel— string for color plane ("R", "G1", etc.)
%   colorize  — true to apply fake color for presentation

    if nargin < 2, outFile = ''; end
    if nargin < 3, planeLabel = ''; end
    if nargin < 4, colorize = false; end

    lambdas  = logspace(0, -3, 4);     % 1 → 0.001
    epsilons = logspace(-1, -4, 4);    % 0.1 → 0.0001

    if isa(f, 'uint8') || isa(f, 'uint16')
        f = im2single(f);
    end

    u = smooth_image_rof(f, lambdas, epsilons);

    figure;
    tiledlayout(4, 4, 'Padding','compact','TileSpacing','compact');

    for i = 1:4
        for j = 1:4
            nexttile;
            img = u(:,:,i,j);
            if colorize
                rgb = fake_colorize(img, planeLabel);
                imshow(rgb);
            else
                imagesc(img); colormap gray;
            end
            axis image off;
            title(sprintf('\\lambda=%.3g\\newline\\epsilon=%.3g', ...
                          lambdas(i), epsilons(j)));
        end
    end

    if colorize
        sgtitle(['Fake Colorized – Plane: ', planeLabel]);
    elseif planeLabel ~= ""
        sgtitle(['ROF Output – Plane: ', planeLabel]);
    else
        sgtitle('ROF Output Grid (\lambda, \epsilon)');
    end

    if ~isempty(outFile)
        folder = fileparts(outFile);
        if ~isempty(folder) && ~isfolder(folder)
            mkdir(folder);
        end
        exportgraphics(gcf, outFile, 'Resolution', 150);
        fprintf('✅ Saved grid to %s\n', outFile);
    end
end
