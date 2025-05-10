% ---------------------------------------------------------------------
%  gpu_plane_sweep.m  –  Memory‑adaptive ROF sweep for one colour plane
%                       (runs entirely on ONE GPU)
% ---------------------------------------------------------------------
function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
% fHost    : H×W image on host (uint16 | single | double)
% lambda   : vector of λ values  (double)
% epsilon  : vector of ε values  (double)
% nIter,dt : solver controls
%
% Returns  msd(K×L)  on host.

%% 1.  Lock GPU & query memory
g        = gpuDevice;               % reserve card for this worker
elemCap  = 2^31 - 1;                % per‑array element limit
oneVarB  = 0.8 * g.TotalMemory;     % per‑array byte cap (80 %)
freeB    = g.AvailableMemory;       % current free bytes

%% 2.  Move plane to GPU & unify types
f   = gpuArray(single(fHost));      % use single precision on device
cls = classUnderlying(f);           % 'single'

lambda  = cast(lambda(:).',  cls);  % row vectors, single
epsilon = cast(epsilon(:).', cls);

[H,W]   = size(f);
bytesPlane = 4 * H * W;             % bytes of f

K = numel(lambda);   L = numel(epsilon);
msd = zeros(K, L, 'single');        % final surface (host)

% 7 working arrays per tile: u,ux,uy,gmag,px,py,div
overhead = 7;

%% 3.  Choose adaptive tile size blk×blk
blk = 32;                           % start aggressive
while blk > 1
    elems  = double(H)*W*blk*blk;   % elements of one 4‑D image
    bytes4D= elems * 4;             % bytes of that image
    bytesTotal = overhead*bytes4D + bytesPlane;
    if elems<=elemCap && bytes4D<oneVarB && bytesTotal<0.8*freeB
        break                       % safe block found
    end
    blk = blk / 2;
end
if blk < 1, blk = 1; end

fprintf('[GPU%u] free %.1f GB  blk %d×%d  working‑set %.2f GB\n', ...
        g.Index, freeB/2^30, blk, blk, ...
        (overhead*double(H)*W*blk*blk*4 + bytesPlane)/2^30);

%% 4.  Sweep over λ×ε tiles
for k0 = 1:blk:K
    kIdx   = k0 : min(k0+blk-1, K);
    lamSub = reshape(lambda(kIdx), 1,1,1,[]);   % 1×1×1×Bλ

    for l0 = 1:blk:L
        lIdx   = l0 : min(l0+blk-1, L);
        epsSub = reshape(epsilon(lIdx), 1,1,1,[]); % 1×1×1×Bε

        % ---- DEBUG header (sizes & types) ----
        fprintf('[GPU%u] tile λ[%d:%d] ε[%d:%d]  f:%s  λ:%s  ε:%s\n', ...
                g.Index, kIdx(1),kIdx(end), lIdx(1),lIdx(end), ...
                mat2str(size(f)), mat2str(size(lamSub)), mat2str(size(epsSub)));

        % ---- Vectorised ROF solver ----
        uTile = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

        % ---- Shape check ----
        expect = [H, W, numel(kIdx), numel(lIdx)];
        assert(isequal(size(uTile), expect), ...
              'uTile shape mismatch: got %s expected %s', ...
              mat2str(size(uTile)), mat2str(expect));

        % ---- MSD accumulation ----
        err2 = (uTile - f).^2;
        msd(kIdx,lIdx) = gather( sqrt( mean(mean(err2,1),2) ) );

        clear uTile err2                      % free tile buffers
    end
end
end
