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

    % ✅ Ensure the output directory exists before saving
    outputDir = 'utils';
    if ~isfolder(outputDir)
        fprintf('Creating output directory: %s\n', outputDir);
        mkdir(outputDir);
    end

    outputPath = fullfile(outputDir, 'synthetic_images.png');
    try
        exportgraphics(gcf, outputPath, 'Resolution', 150);
        fprintf('✅ Saved synthetic image plot to %s\n', outputPath);
    catch ME
        fprintf('❌ Failed to save figure: %s\n', ME.message);
    end
end
