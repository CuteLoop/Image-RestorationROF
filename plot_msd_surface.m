function plot_msd_surface(msd, lambdas, epsilons)
    [LAMBDA, EPSILON] = meshgrid(lambdas, epsilons);  % use ASCII variable names
    mesh(LAMBDA, EPSILON, msd');  % transpose because MSD is K×L
    xlabel('\lambda');
    ylabel('\epsilon');
    zlabel('MSD');
    title('MSD(\lambda, \epsilon)');
    grid on;
end