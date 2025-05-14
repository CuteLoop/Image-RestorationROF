function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
% Memory‐adaptive GPU batching for ROF MSD
g = gpuDevice; freeB = g.AvailableMemory; totalB = g.TotalMemory;
f = gpuArray(single(fHost));
[H,W] = size(f);
lambda = cast(lambda(:).','single'); epsilon = cast(epsilon(:).','single');
K = numel(lambda); L = numel(epsilon);
msd = zeros(K,L,'single');
overhead = 7; bytesPlane = H*W*4;
blk = 32;
while blk>1
  bytes4D = H*W*blk*blk*4;
  if bytes4D<0.8*totalB && (overhead*bytes4D+bytesPlane)<0.8*freeB, break; end
  blk = blk/2;
end
blk = max(1,blk);
for k0=1:blk:K
  kIdx = k0:min(k0+blk-1,K);
  lamSub = reshape(lambda(kIdx),1,1,1,[]);
  for l0=1:blk:L
    lIdx = l0:min(l0+blk-1,L);
    epsSub = reshape(epsilon(lIdx),1,1,1,[]);
    uTile = smooth_image_rof(f, lamSub, epsSub, nIter, dt);
    err2 = (uTile - f).^2;
    msd(kIdx,lIdx) = gather(sqrt(mean(mean(err2,1),2)));
  end
end
end