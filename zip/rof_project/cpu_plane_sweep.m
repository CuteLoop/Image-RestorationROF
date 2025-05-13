function msd = cpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
% Memory‐adaptive CPU batching for ROF MSD
try m=memory; freeB=m.MemAvailableAllArrays; catch freeB=4*2^30; end
freeB=0.8*double(freeB);
f=single(fHost); [H,W]=size(f);
lambda=lambda(:); epsilon=epsilon(:);
K=numel(lambda); L=numel(epsilon);
msd=zeros(K,L,'single');
overhead=7; bytesPlane=H*W*4;
blk=32;
while blk>1
  tileB = overhead*bytesPlane*blk*blk + bytesPlane;
  if tileB<freeB, break; end
  blk=blk/2;
end
blk=max(1,blk);
for k0=1:blk:K
  kIdx=k0:min(k0+blk-1,K); lamSub=lambda(kIdx);
  for l0=1:blk:L
    lIdx=l0:min(l0+blk-1,L); epsSub=epsilon(lIdx);
    uTile = smooth_image_rof(f, lamSub, epsSub, nIter, dt);
    err2=(uTile-f).^2;
    msd(kIdx,lIdx)=sqrt(mean(mean(err2,1),2));
  end
end
end