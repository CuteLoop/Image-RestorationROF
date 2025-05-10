
% ---------------------------------------------------------------------
%  cpu_plane_sweep  –  memory‑adaptive ROF sweep on ONE colour plane
%                      (robust free‑RAM detection)
% ---------------------------------------------------------------------
function msd = cpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)

    % -------------------------------------------------------------- 1 --
    %  Free‑RAM query with three fallbacks
    % --------------------------------------------------------------
    freeBytes = NaN;

    % 1A.  First choice: memory() (Windows & many Linux w/ Java)
    if exist('memory','file') == 2
        try
            m = memory;                         % struct
            freeBytes = m.MemAvailableAllArrays;
        catch
        end
    end

    % 1B.  Second choice: /proc/meminfo (Linux)
    if isnan(freeBytes) && isunix
        fid = fopen('/proc/meminfo','r');
        if fid>0
            C = textscan(fid,'%s%f%*s');    % token, numeric‑value, (skip)
            fclose(fid);
            idx = strcmp(C{1},'MemAvailable');
            if any(idx)
                freeBytes = C{2}(idx) * 1024;   % kB → bytes
            end
        end
    end

    % 1C.  Last resort: assume 4 GB free
    if isnan(freeBytes) || freeBytes<=0
        warning('Could not query free host RAM – assuming 4 GB.');
        freeBytes = 4 * 2^30;
    end

    freeBytes = 0.8 * double(freeBytes);     % keep 20 % safety margin

    % -------------------------------------------------------------- 2 --
    %  Memory model: how many (λ,ε) pairs fit simultaneously?
    % --------------------------------------------------------------
    f = single(fHost);               % work in single precision
    [H,W] = size(f);

    bytesPerImage = 4 * H * W * 4 * 1.10;   % u,ux,uy,gmag +10 %

    maxPairs = floor( (freeBytes - bytesPerImage) / bytesPerImage );
    blk      = max(1, 2^floor(log2(maxPairs)));      % ≥1, power‑of‑two

    fprintf('[CPU]  Free ≈ %.1f GB → block %d×%d pairs\n',...
            freeBytes/2^30, blk, blk);

    % -------------------------------------------------------------- 3 --
    %  Block‑wise loop over grid
    % --------------------------------------------------------------
    K = numel(lambda);   L = numel(epsilon);
    msd = zeros(K, L, 'single');

    for k0 = 1:blk:K
        kIdx = k0 : min(k0+blk-1, K);
        lamSub = lambda(kIdx);

        for l0 = 1:blk:L
            lIdx  = l0 : min(l0+blk-1, L);
            epsSub = epsilon(lIdx);

            uSub = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

            err2 = (uSub - f).^2;
            msd(kIdx,lIdx) = sqrt( mean(mean(err2,1), 2) );
        end
    end
end
