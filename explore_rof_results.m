function explore_rof_results(matFile, showImages)
%EXPLORE_ROF_RESULTS  Visual diagnostics for ROF MSD cube.
%
%   explore_rof_results('rof_results_singlepool.mat')
%   explore_rof_results('rof_results_singlepool.mat', true)
%
% INPUT
%   matFile     : MAT‑file containing  lambda, epsilon, msdCube
%   showImages  : (optional) true  → will call smooth_image_rof and show
%                 the denoised plane at the optimal (λ*,ε*).  Requires the
%                 raw plane in workspace as variable Iplanar.
%
% OUTPUT
%   Figures with MSD surfaces, bar chart, and (optionally) images.
%
% ---------------------------------------------------------------------

if nargin<2, showImages = false; end

S = load(matFile);           % expects lambda, epsilon, msdCube
lambda  = S.lambda(:);
epsilon = S.epsilon(:);
msdCube = S.msdCube;         % K×L×4

planes = ["R" "G1" "G2" "B"];
[K,L,~] = size(msdCube);

% ----- 1.  Full surfaces ---------------------------------------------
figure('Name','ROF MSD Surfaces'), tiledlayout(2,2,"Padding","compact")
for p = 1:4
    nexttile
    surf(lambda, epsilon, msdCube(:,:,p).','EdgeColor','none',...
         'FaceAlpha',0.8), shading interp
    set(gca,'XScale','log','YScale','log'), view(45,25)
    title("MSD – " + planes(p)), xlabel('\lambda'), ylabel('\epsilon')
end

% ----- 2.  Arg‑min per plane -----------------------------------------
bestIdx = zeros(4,2);         % [k*  l*]
bestVal = zeros(4,1);
fprintf('\nOptimal (λ*, ε*) per plane:\n');
for p = 1:4
    [val, idx] = min(msdCube(:,:,p), [], 'all', 'linear');
    [kStar,lStar] = ind2sub([K,L], idx);
    bestIdx(p,:) = [kStar lStar];
    bestVal(p)   = val;
    fprintf('  %-2s : MSD=%.4f  λ*=%.3g  ε*=%.3g\n',...
            planes(p), val, lambda(kStar), epsilon(lStar));
end

% ----- 3.  Bar chart ranking -----------------------------------------
figure('Name','Noise ranking'), bar(bestVal), grid on
set(gca,'XTick',1:4,'XTickLabel',planes), ylabel('min MSD')
title('Least → most noisy colour planes')

% ----- 4.  Optional: reconstruct denoised images ---------------------
if showImages
    if ~evalin("base","exist('Iplanar','var')")
        warning('Iplanar not found in base workspace. Skipping images.');
        return
    end
    Iplanar = evalin("base","Iplanar");
    nIter = 300;  dt = 0.25;
    figure('Name','Optimal denoised planes')
    tiledlayout(2,2)
    for p = 1:4
        f  = single(Iplanar(:,:,p));
        k  = bestIdx(p,1);  l = bestIdx(p,2);
        lam = lambda(k);    eps = epsilon(l);
        uOpt = smooth_image_rof(f, lam, eps, nIter, dt);

        nexttile, imshow(uOpt,[]), title(sprintf('%s  λ=%.3g ε=%.3g',...
                  planes(p),lam,eps))
    end
end
end
