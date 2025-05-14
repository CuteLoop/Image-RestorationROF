function test_plot_rof_grid_planes(Iplanar)
% TEST_PLOT_ROF_GRID_PLANES Generates ROF grids for each Bayer plane
%
% Usage:
%   Iplanar = raw2planar(rawread('images/DSC00099.ARW'));
%   test_plot_rof_grid_planes(Iplanar);

    assert(size(Iplanar,3) == 4, 'Expected 4 Bayer planes (R, G1, G2, B)');

    planeNames = ["R", "G1", "G2", "B"];

    outDir = 'results';
    if ~isfolder(outDir)
        mkdir(outDir);
    end

    for p = 1:4
        fprintf('📸 Generating ROF grid for Plane %s...\n', planeNames(p));
        f = Iplanar(:,:,p);
        outFile = fullfile(outDir, sprintf('rof_grid_plane_%s.png', planeNames(p)));
        plot_rof_grid(f, outFile);
    end

    fprintf('✅ All 4 ROF grid images saved to %s/\n', outDir);
end
