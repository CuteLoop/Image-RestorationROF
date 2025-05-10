%% ------------------------------------------------------------
%  ROF parameter sweep    (add below the existing visualisations)
% --------------------------------------------------------------
fprintf('\n==== ROF TV parameter sweep ==================================\n');

lambda  = logspace(-3, 0, 20);     % 1e‑3 … 1      (K = 20)
epsilon = logspace(-4, -1, 20);    % 1e‑4 … 0.1    (L = 20)

K = numel(lambda);  L = numel(epsilon);

colourName = ["R" "G1" "G2" "B"];
msdCube    = zeros(K, L, 4, 'single');   % K×L×4   MSD surfaces
u4D        = cell(1,4);                  % each will be H×W×K×L

nIter = 300;   dt = 0.25;                % solver controls

for kPlane = 1:4
    f = single(Iplanar(:,:,kPlane));     % current raw plane

    fprintf('  denoising %-2s plane … ', colourName(kPlane));
    tic

    % ---- full 4‑D stack of restorations (H×W×K×L) ----
    u4D{kPlane} = smooth_image_rof(f, lambda, epsilon, nIter, dt);

    % ---- MSD surface (K×L) ----
    err2               = (u4D{kPlane} - repmat(f,1,1,K,L)).^2;
    msdCube(:,:,kPlane)= sqrt( squeeze( mean(mean(err2,1), 2) ) );

    fprintf('done in %.1f s\n', toc);

    % ---- surface plot ----
    figure('Name',['MSD ',colourName(kPlane)]);
    surf(lambda, epsilon, msdCube(:,:,kPlane).', ...
         'EdgeColor','none','FaceAlpha',0.65);
    set(gca,'XScale','log','YScale','log');
    xlabel('\lambda'), ylabel('\epsilon'), zlabel('MSD');
    title(['MSD surface – ', colourName(kPlane),' plane']);
    view(45,30)
end

% -------- optional: save results to a .mat file ---------------
save('rof_sweep_results.mat', 'lambda', 'epsilon', ...
     'msdCube', 'u4D','-v7.3');

fprintf('All four planes processed.\n');
fprintf('Results saved in  rof_sweep_results.mat  (large file, ~GB).\n');
fprintf('============================================================\n');
% ----------------------------------------------------------------  