function plot_msd_surface(msd, lambdas, epsilons)
    [Λ, Ε] = meshgrid(lambdas, epsilons);
    mesh(Λ, Ε, msd');  % transpose because MSD is K×L
    xlabel('\lambda');
    ylabel('\epsilon');
    zlabel('MSD');
    title('MSD(\lambda, \epsilon)');
    grid on;
end
% This function plots the Mean Squared Deviation (MSD) surface for given