function plot_rof_grid(f, outFile, planeLabel, colorize)
    if nargin < 2, outFile = ''; end
    if nargin < 3, planeLabel = ''; end
    if nargin < 4, colorize = false; end

    lambdas  = logspace(0, -3, 4);
    epsilons = logspace(-1, -4, 4);

    if isa(f, 'uint8') || isa(f, 'uint16')
        f = im2single(f);
    end

    % ✅ Explicit figure handle
    fig = figure('Visible', 'on');  % force visible even in remote
    tiledlayout(4, 4, 'Padding','compact','TileSpacing','compact');

    u = smooth_image_rof(f, lambdas, epsilons);

    for i = 1:4
        for j = 1:4
            nexttile;
            img = u(:,:,i,j);
            if colorize
                imshow(fake_colorize(img, planeLabel));
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
    end

    if ~isempty(outFile)
        try
            folder = fileparts(outFile);
            if ~isempty(folder) && ~isfolder(folder)
                mkdir(folder);
            end
            exportgraphics(fig, outFile, 'Resolution', 150);
            fprintf('✅ Saved grid to %s\n', outFile);
        catch ME
            fprintf('❌ Failed to export image: %s\n', ME.message);
        end
    end
end
