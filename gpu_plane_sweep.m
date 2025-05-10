% ---------------------------------------------------------------------
%  gpu_plane_sweep  –  memory‑adaptive ROF sweep on ONE colour plane
% ---------------------------------------------------------------------
function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)

    g         = gpuDevice;              % lock this GPU
    elemCap   = 2^31 - 1;               % 32‑bit indexing limit
    oneVarCap = 0.8 * g.TotalMemory;    % MATLAB per‑array cap (≈80 %)
    freeB     = g.AvailableMemory;      % bytes free right now

    f = gpuArray(single(fHost));        % H×W on device
    [H,W] = size(f);

    % ---------- working‑set model ------------------------------------
    overheadArrays = 7;                 % u, ux, uy, gmag, px, py, div
    bytesPlane     = 4 * H * W;         % single precision

    K = numel(lambda);   L = numel(epsilon);
    msd = zeros(K,L,'single');          % host result

    % ---------- choose block size blk --------------------------------
    blk = 32;                           % start aggressive
    while blk > 1
        elems4D    = double(H) * W * blk * blk;
        bytes4D    = elems4D * 4;
        bytesTotal = overheadArrays * bytes4D + bytesPlane; % +f itself
        if elems4D<=elemCap && ...
           bytes4D<oneVarCap && ...
           bytesTotal < 0.8*freeB
            break                                % safe blk found
        end
        blk = blk / 2;                           % shrink by /2
    end
    if blk < 1, blk = 1; end

    fprintf('[GPU%u] free %.1f GB | using blk %d×%d '
            '(%.2f GB working‑set)\n', ...
            g.Index, freeB/2^30, blk, blk, ...
            (overheadArrays*bytes4D + bytesPlane)/2^30);

    % ---------- iterate over λ×ε tiles -------------------------------
    for k0 = 1:blk:K
        kIdx   = k0 : min(k0+blk-1, K);
        lamSub = lambda(kIdx);
        for l0 = 1:blk:L
            lIdx   = l0 : min(l0+blk-1, L);
            epsSub = epsilon(lIdx);

            u = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

            err2 = (u - f).^2;
            msd(kIdx,lIdx) = gather( sqrt( mean(mean(err2,1),2) ) );

            % free intermediate arrays explicitly (good practice)
            clear u err2;
        end
    end
end
