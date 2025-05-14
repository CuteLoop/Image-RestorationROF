function plot_synthetic_images(outputPath)
    if nargin < 1
        outputPath = fullfile('utils', 'synthetic_images.png');
    end
    types = {'gradient', 'checkerboard', 'sinusoidal'};
    figure('Name','Synthetic Test Images','Visible','off');
    for i = 1:length(types)
        img = generate_synthetic_image(types{i}, [128, 128]);
        subplot(1, length(types), i);
        imagesc(img); colormap gray; axis image off;
        title(types{i});
    end
    exportgraphics(gcf, outputPath, 'Resolution', 150);
    close(gcf);
    fprintf('✅ Synthetic images saved to %s\n', outputPath);
end
