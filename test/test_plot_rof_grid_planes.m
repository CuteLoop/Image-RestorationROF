function test_plot_rof_grid_planes()
% TEST_PLOT_ROF_GRID_PLANES Self-contained test to generate ROF grid for each Bayer plane
    addpath('..');        % Adds the project root to the path
    addpath('../utils');  % Add utilities if needed
    rawFile = './images/DSC00099.ARW';
    fprintf('📥 Reading raw image: %s\n', rawFile);

    cfa = rawread(rawFile);
    Iplanar = raw2planar(cfa);
    planeNames = ["R", "G1", "G2", "B"];

    outDir = 'results';
    if ~isfolder(outDir)
        mkdir(outDir);
    end

for p = 1:4
    fprintf('📸 Grayscale for Plane %s...\n', planeNames(p));
    f = Iplanar(:,:,p);
    outGray = fullfile(outDir, sprintf('rof_grid_plane_%s_gray.png', planeNames(p)));
    outColor = fullfile(outDir, sprintf('rof_grid_plane_%s_color.png', planeNames(p)));

    plot_rof_grid(f, outGray, planeNames(p), false);  % grayscale
    plot_rof_grid(f, outColor, planeNames(p), true);  % colorized
end


    fprintf('✅ All 4 ROF grid images saved to %s/\n', outDir);
end
