function plot_rof_grid_comparison(f, lambdas, epsilons, outpath)
% Plots ROF outputs for combinations of λ and ε

if nargin < 4
    outpath = fullfile('test', 'rof_grid_comparison.png');
end

u = smooth_image_rof(single(f), lambdas, epsilons);
figure('Name','ROF Grid Comparison','Visible','off');

for i = 1:length(lambdas)
    for j = 1:length(epsilons)
        subplot(length(lambdas), length(epsilons), (i-1)*length(epsilons)+j);
        imagesc(u(:,:,i,j)); axis image off;
        title(sprintf('\\lambda=%.2g, \\epsilon=%.2g', lambdas(i), epsilons(j)));
        colormap gray;
    end
end

exportgraphics(gcf, outpath, 'Resolution', 150);
fprintf('✅ Grid comparison saved to %s\n', outpath);
close(gcf);
end
