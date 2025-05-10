function explore_rof_results(matFile, showImages)
%EXPLORE_ROF_RESULTS  Visualise ROF MSD cube & pick optimal TV params
%
%   explore_rof_results()  
%       → auto-detect latest 'rof_results*.mat' in pwd  
%   explore_rof_results(matFile)  
%       → load from the given .mat file  
%   explore_rof_results(matFile, true)  
%       → also show denoised images at the optimal (λ*,ε*)
%
% The MAT-file must contain variables: lambda (K×1), epsilon (L×1), msdCube (K×L×4).

    % --- 1) Handle default inputs -------------------------------------
    if nargin<1 || isempty(matFile)
        D = dir('rof_results*.mat');
        if isempty(D)
            error('No rof_results*.mat found in current folder.');
        end
        [~, idxNewest] = max([D.datenum]);
        matFile = D(idxNewest).name;
        fprintf('✔ Auto-using: %s\n', matFile);
    end
    if nargin<2
        showImages = false;
    end

    % --- 2) Load results ----------------------------------------------
    S = load(matFile);
    lambda   = S.lambda(:);
    epsilon  = S.epsilon(:);
    msdCube  = S.msdCube;     % size K×L×4
    planes   = ["R","G1","G2","B"];
    [K,L,~]  = size(msdCube);

    % --- 3) Plot MSD surfaces -----------------------------------------
    figure('Name','ROF MSD Surfaces'), tiledlayout(2,2,"Padding","compact");
    for p = 1:4
        nexttile
        surf(lambda, epsilon, msdCube(:,:,p).', 'EdgeColor','none','FaceAlpha',0.8)
        shading interp
        set(gca,'XScale','log','YScale','log'), view(45,25)
        xlabel('\lambda'), ylabel('\epsilon'), zlabel('MSD')
        title("Plane "+planes(p))
    end

    % --- 4) Find & print optimal (λ*,ε*) per plane -------------------
    bestIdx = zeros(4,2);
    bestVal = zeros(4,1);
    fprintf('\nOptimal (λ*, ε*) per plane:\n');
    for p = 1:4
        [minVal, linIdx] = min(msdCube(:,:,p), [], 'all', 'linear');
        [kStar,lStar]    = ind2sub([K,L], linIdx);
        bestIdx(p,:)     = [kStar, lStar];
        bestVal(p)       = minVal;
        fprintf('  %-2s : MSD = %.4f   λ* = %.3g   ε* = %.3g\n', ...
                planes(p), minVal, lambda(kStar), epsilon(lStar));
    end

    % --- 5) Bar chart ranking -----------------------------------------
    figure('Name','Noise Ranking'), bar(bestVal), grid on
    set(gca,'XTick',1:4,'XTickLabel',planes), ylabel('Min MSD')
    title('Cleanest (lowest MSD) → Noisiest (highest MSD)')

    % --- 6) (Optional) Show denoised planes --------------------------
    if showImages
        % Require Iplanar in base workspace
        if evalin('base','exist(''Iplanar'',''var'')')
            Iplanar = evalin('base','Iplanar');
            nIter = 300;  dt = 0.25;
            figure('Name','Optimal Denoised Planes')
            tiledlayout(2,2,"Padding","compact");
            for p = 1:4
                f = single(Iplanar(:,:,p));
                k = bestIdx(p,1); l = bestIdx(p,2);
                lam = lambda(k); eps = epsilon(l);
                uOpt = smooth_image_rof(f, lam, eps, nIter, dt);
                nexttile
                imshow(uOpt,[]), title(sprintf("%s: λ=%.3g, ε=%.3g", ...
                       planes(p), lam, eps))
            end
        else
            warning("Iplanar not found in base workspace; skipping images.");
        end
    end
end
