function result = smart_grid_search(f, lambdaRange, epsilonRange, ...
                                    coarseN, refineN, halfDecades, nIter, dt)
lambda0  = logspace(log10(lambdaRange(1)),log10(lambdaRange(2)),coarseN);
epsilon0 = logspace(log10(epsilonRange(1)),log10(epsilonRange(2)),coarseN);
msd0 = calculate_msd(f,lambda0,epsilon0,nIter,dt);
[min0,idx0]=min(msd0(:)); [k0,l0]=ind2sub(size(msd0),idx0);
lstar0=lambda0(k0); estar0=epsilon0(l0);
lamLo=lstar0*10^(-halfDecades); lamHi=lstar0*10^(halfDecades);
epsLo=estar0*10^(-halfDecades); epsHi=estar0*10^(halfDecades);
lambda1  = logspace(log10(lamLo),log10(lamHi),refineN);
epsilon1 = logspace(log10(epsLo),log10(epsHi),refineN);
msd1 = calculate_msd(f,lambda1,epsilon1,nIter,dt);
[min1,idx1]=min(msd1(:)); [k1,l1]=ind2sub(size(msd1),idx1);
lstar1=lambda1(k1); estar1=epsilon1(l1);
result = struct(... 
  'lambdaCoarse',lambda0,'epsilonCoarse',epsilon0,'msdCoarse',msd0,'bestCoarse',[lstar0,estar0],'minCoarse',min0,...
  'lambdaRefine',lambda1,'epsilonRefine',epsilon1,'msdRefine',msd1,'bestRefine',[lstar1,estar1],'minRefine',min1);
end