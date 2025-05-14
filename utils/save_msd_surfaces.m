% === Plot and Save MSD surfaces for each plane and multiple angles ===
load('../rof_results_singlepool.mat');  % Loads: lambda, epsilon, msdCube

[LAMBDA, EPSILON] = meshgrid(lambda, epsilon);  % For surface plotting
planeNames = {'Red', 'Green1', 'Green2', 'Blue'};
outputDir = 'results/msd_surfaces';

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Define view angles (azimuth, elevation)
viewAngles = [...
    135, 30;  % default
    90, 60;
    180, 45;
    225, 30;
];

for p = 1:4
    msd = msdCube(:,:,p);
    name = lower(planeNames{p});

    for a = 1:size(viewAngles,1)
        az = viewAngles(a,1); el = viewAngles(a,2);

        fig = figure('Visible','off');
        surf(LAMBDA, EPSILON, msd', ...
            'EdgeColor', 'none', ...
            'FaceAlpha', 0.9);
        title(sprintf('MSD Surface - %s', planeNames{p}), 'FontWeight', 'bold');
        xlabel('\lambda'); ylabel('\epsilon'); zlabel('MSD');
        colorbar; grid on; view(az, el);
        set(gca, 'FontSize', 10);

        filename = fullfile(outputDir, ...
            sprintf('msd_surface_%s_angle_%d_%d.png', name, az, el));
        exportgraphics(fig, filename, 'BackgroundColor', 'white', 'Resolution', 150);
        close(fig);

        fprintf('✅ Saved: %s\n', filename);
    end
end
