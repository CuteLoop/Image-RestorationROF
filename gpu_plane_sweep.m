% ---------------------------------------------------------------------
%  gpu_plane_sweep  –  memory‑adaptive ROF sweep on ONE colour plane
% ---------------------------------------------------------------------
function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)

    %-- lock the GPU assigned to this worker and query memory -----------
    g = gpuDevice;
    freeBytes = g.AvailableMemory;            % what CUDA reports
    maxBytesOneVar = 0.8 * g.TotalMemory;     % MATLAB guard (≈ 80 %)

    fprintf('[GPU%d]  Free: %.1f GB   MaxPerVar: %.1f GB\n', ...
            g.Index, freeBytes/2^30, maxBytesOneVar/2^30);

    %-- move the current plane to device (single precision) -------------
    f = gpuArray(single(fHost));
    [H,W] = size(f);

    %-- bytes required for one additional image in smooth_image_rof -----
    %   (u, ux, uy, gmag  → 4 arrays; plus a small overhead factor)
    bytesPerImage = 4 * H * W * 4 * 1.10;    % (~1.1 safety)

    %-- choose #pairs that can fit under both limits --------------------
    avail      = min(freeBytes, maxBytesOneVar) - numel(f)*4;  % leave f in RAM
    maxPairs   = floor( avail / bytesPerImage );
    blk        = max(1, 2^floor(log2(maxPairs)));  % power of two, at least 1

    fprintf('[GPU%d]  Processing %d×%d grid in blocks of %d×%d pairs\n', ...
            g.Index, numel(lambda), numel(epsilon), blk, blk);

    %-- container for final MSD surface (host side) ---------------------
    msd = zeros(numel(lambda), numel(epsilon), 'single');

    %-- iterate over blocks ---------------------------------------------
    for k0 = 1:blk:numel(lambda)
        kIdx = k0 : min(k0+blk-1, numel(lambda));
        lamSub = lambda(kIdx);

        for l0 = 1:blk:numel(epsilon)
            lIdx  = l0 : min(l0+blk-1, numel(epsilon));
            epsSub = epsilon(lIdx);

            % --- ROF solver for this sub‑grid (vectorised inside) -----
            uSub = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

            % --- accumulate MSD for the sub‑grid ----------------------
            err2 = (uSub - f).^2;
            msd(kIdx,lIdx) = gather( sqrt( mean(mean(err2,1), 2) ) );
        end
    end
end

