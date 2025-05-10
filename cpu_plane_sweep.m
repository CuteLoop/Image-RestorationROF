function msd = cpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
% One colour plane, processed on CPU in RAM‑aware tiles.

% ---- free RAM in bytes ----------------------------------------------
freeB = NaN;
if exist('memory','file')==2
    try,  freeB = memory; freeB = freeB.MemAvailableAllArrays; end
end
if isnan(freeB) && isunix
    fid=fopen('/proc/meminfo','r');
    if fid>0
        C = textscan(fid,'%s%f%*s'); fclose(fid);
        idx = strcmp(C{1},'MemAvailable'); 
        if any(idx), freeB = C{2}(idx)*1024; end
    end
end
if isnan(freeB) || freeB<=0
    warning('free RAM unknown, assuming 4 GB'); freeB=4*2^30;
end
freeB = 0.8*double(freeB);

% ---- memory model ----------------------------------------------------
f = single(fHost); [H,W]=size(f);
bytesPerImg = 4*H*W*4*1.1;
maxPairs = floor( (freeB-bytesPerImg)/bytesPerImg );
blk = max(1,2^floor(log2(maxPairs)));
fprintf('[CPU] blk %d×%d (RAM %.1f GB)\n',blk,blk,freeB/2^30);

K=numel(lambda); L=numel(epsilon); msd=zeros(K,L,'single');

for k0=1:blk:K
    kIdx = k0:min(k0+blk-1,K); lamSub=lambda(kIdx);
    for l0=1:blk:L
        lIdx=l0:min(l0+blk-1,L); epsSub=epsilon(lIdx);
        u = smooth_image_rof(f,lamSub,epsSub,nIter,dt);
        err2=(u-f).^2;
        msd(kIdx,lIdx)=sqrt(mean(mean(err2,1),2));
    end
end
end
