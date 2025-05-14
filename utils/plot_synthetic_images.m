function plot_synthetic_images()
    types = {'gradient', 'checkerboard', 'sinusoidal'};
    sz = [128, 128];
    t = tiledlayout(1, numel(types), 'Padding','compact','TileSpacing','compact');

    for i = 1:numel(types)
        nexttile;
        img = generate_synthetic_image(types{i}, sz);
        imagesc(img); axis image off; colormap gray;
        title(types{i});
    end

    % ✅ Ensure the output folder exists
    outputDir = 'utils';
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    outputPath = fullfile(outputDir, 'synthetic_images.png');
    exportgraphics(gcf, outputPath, 'Resolution', 150);
    disp(['✅ Saved to ', outputPath]);
end
