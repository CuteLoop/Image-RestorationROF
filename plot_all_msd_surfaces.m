function plot_all_msd_surfaces(lambda, epsilon)
% PLOT_ALL_MSD_SURFACES - Plot MSD surfaces for 4 color planes with offsets

    colors = {'r', 'g', 'c', 'b'};
    labels = {'Red', 'Green1', 'Green2', 'Blue'};
    offsets = [0.00, 0.03, 0.06, 0.09];  % vertical offset for visual clarity

    [LAMBDA, EPSILON] = meshgrid(lambda, epsilon);
    figure('Name','MSD Surfaces for Color Planes');
    hold on;

    for p = 1:4
        fname = sprintf('plane_%d_msd.mat', p);
        if ~isfile(fname)
            warning('Missing file: %s', fname);
            continue;
        end

        data = load(fname);
        msd = data.msd;

        surf(LAMBDA, EPSILON, msd' + offsets(p), ...
            'FaceAlpha', 0.5, ...
            'EdgeColor', colors{p}, ...
            'DisplayName', labels{p});
    end

    xlabel('\lambda');
    ylabel('\epsilon');
    zlabel('MSD + offset');
    title('MSD Surfaces for Color Planes');
    legend('Location', 'best');
    grid on;
    view(135, 30);  % angled view
end
