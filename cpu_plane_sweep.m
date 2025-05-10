% ---------------------------------------------------------------------
%  cpu_plane_sweep.m  –  Memory‑adaptive ROF sweep on ONE colour plane
%                       (runs on CPU workers)
% ---------------------------------------------------------------------
function msd = cpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)

%% ---------- 1.  determine free RAM ----------------------------------
freeB = NaN;
if exist('memory','file')==2
    try,  S=memory; freeB=S.MemAvailableAllArrays; end
end
if isnan(freeB) && isunix
    fid=fopen('/proc/meminfo','r');
    if fid>0
        C=textscan(fid,'%s%f%*s'); fclose(fid);
        id=strcmp(C{1},'MemAvailable');
        if any(id), freeB=C{2}(id)*1024; end      % kB→B
    end
end
if isnan(freeB) || freeB<=0
    freeB = 4*2^30;
    warning('Free RAM unknown – defaulting to 4 GB.');
end
freeB = 0.8*double(freeB);                        % 20 % head‑room

%% ---------- 2.  cast image & parameters -----------------------------
f   = single(fHost);             % work in single on CPU too
cls = class(f);
lambda  = cast(lambda,  cls);
epsilon = cast(epsilon, cls);

[H,W] = size(f);
bytesPlane = 4*H*W;              % one single‑precision image

overhead = 7;                    % same 7 temps as GPU version
bytesPerImg = bytesPlane * overhead;

K = numel(lambda);  L = numel(epsilon);
blk = 32;
while blk>1
    bytesTile = bytesPlane * blk*blk * overhead + bytesPlane;
    if bytesTile < freeB
        break
    end
    blk = blk/2;
end
if blk<1, blk=1; end

fprintf('[CPU] free %.1f GB  blk %d×%d  working‑set %.2f GB\n',...
        freeB/2^30, blk, blk, ...
        (bytesPlane*blk*blk*overhead + bytesPlane)/2^30);

%% ---------- 3.  loop over tiles -------------------------------------
msd = zeros(K,L,'single');
for k0 = 1:blk:K
    kIdx   = k0 : min(k0+blk-1, K);
    lamSub = reshape(lambda(kIdx),1,1,1,[]);   % broadcast 1×1×1×Bλ
    for l0 = 1:blk:L
        lIdx   = l0 : min(l0+blk-1, L);
        epsSub = reshape(epsilon(lIdx),1,1,1,[]);

        fprintf('[CPU] tile λ[%d:%d] ε[%d:%d]  f:%s  λ:%s  ε:%s\n',...
                kIdx(1),kIdx(end), lIdx(1),lIdx(end), ...
                mat2str(size(f)), mat2str(size(lamSub)), ...
                mat2str(size(epsSub)));

        uTile = smooth_image_rof(f, lamSub, epsSub, nIter, dt);

        assert(isequal(size(uTile), [H,W,numel(kIdx),numel(lIdx)]), ...
               'uTile shape mismatch');

        err2 = (uTile - f).^2;
        msd(kIdx,lIdx) = sqrt( mean(mean(err2,1),2) );

        clear uTile err2                       % release RAM
    end
end
end
