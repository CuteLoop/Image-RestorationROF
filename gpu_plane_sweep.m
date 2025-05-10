function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
% One colour plane, full λ×ε grid, auto‑shrinks block to fit GPU RAM.

g       = gpuDevice;
elemCap = 2^31 - 1;                       % MATLAB hard element limit
capB    = 0.8 * g.TotalMemory;            % 80 % per‑array cap
freeB   = g.AvailableMemory;

f = gpuArray(single(fHost));
[H,W] = size(f);

bytesPerImg = 4*H*W*4*1.1;                % u,ux,uy,gmag (+10%)
K = numel(lambda);  L = numel(epsilon);
msd = zeros(K,L,'single');

% choose blk so that H*W*blk² elements & bytes safe
blk = 32;
while blk > 1
    elems = double(H)*W*blk*blk;
    bytes = elems*4;
    if elems<=elemCap && bytes<capB && bytes*2<freeB
        break
    end
    blk = blk/2;
end
if blk<1, blk=1; end
fprintf('[GPU%u] blk %d×%d (%.2f GB array)\n',g.Index,blk,blk, ...
        double(H)*W*blk*blk*4/2^30 );

for k0 = 1:blk:K
    kIdx = k0 : min(k0+blk-1, K);
    lamSub = lambda(kIdx);
    for l0 = 1:blk:L
        lIdx  = l0 : min(l0+blk-1, L);
        epsSub = epsilon(lIdx);

        u = smooth_image_rof(f, lamSub, epsSub, nIter, dt);
        err2 = (u - f).^2;
        msd(kIdx,lIdx) = gather( sqrt( mean(mean(err2,1),2) ) );
    end
end
end
