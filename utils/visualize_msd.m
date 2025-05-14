load('rof_results_singlepool.mat');
colors = {'r', 'g', 'c', 'b'};
labels = {'Red', 'Green1', 'Green2', 'Blue'};
offsets = [0.00, 0.03, 0.06, 0.09];  % optional vertical offsets

[LAMBDA, EPSILON] = meshgrid(lambda, epsilon);
figure('Name', 'MSD Surfaces for Color Planes');
hold on;

for p = 1:4
    surf(LAMBDA, EPSILON, msdCube(:,:,p)' + offsets(p), ...
        'FaceAlpha', 0.5, ...
        'EdgeColor', colors{p}, ...
        'DisplayName', labels{p});
end

xlabel('\lambda'); ylabel('\epsilon'); zlabel('MSD + offset');
title('MSD Surfaces for Color Planes');
legend('Location', 'best');
grid on;
view(135, 30);
