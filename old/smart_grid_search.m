function result = smart_grid_search(f, lambdaRange, epsilonRange, ...
                                    coarseN, refineN, halfDecades, ...
                                    nIter, dt)
%SMART_GRID_SEARCH  Two‑stage ROF parameter tuning on one image plane
%
%   result = smart_grid_search(f, lambdaRange, epsilonRange, ...
%                              coarseN, refineN, halfDecades, nIter, dt)
%
% INPUT
%   f            : H×W image (single or gpuArray(single))
%   lambdaRange  : [λ_min λ_max] (e.g. [1e‑4 1])
%   epsilonRange : [ε_min ε_max] (e.g. [1e‑5 1e‑1])
%   coarseN      : #points/axis in coarse grid  (e.g. 10)
%   refineN      : #points/axis in refined grid (e.g. 15)
%   halfDecades  : half‑width of refine window (log‑10 decades)
%   nIter, dt    : ROF solver controls fed to calculate_msd
%
% OUTPUT (struct)
%   lambdaCoarse, epsilonCoarse : coarse grids (vectors)
%   msdCoarse                   : coarse MSD surface  (coarseN×coarseN)
%   bestCoarse,  minCoarse      : [λ*,ε*] & value on coarse grid
%   lambdaRefine, epsilonRefine : refined grids
%   msdRefine                   : refined MSD surface (refineN×refineN)
%   bestRefine,  minRefine      : [λ*,ε*] & value on refined grid
%

% ---------- 1. coarse grid --------------------------------------------
lambda0  = logspace(log10(lambdaRange(1)),  log10(lambdaRange(2)),  coarseN);
epsilon0 = logspace(log10(epsilonRange(1)), log10(epsilonRange(2)), coarseN);

msd0 = calculate_msd(f, lambda0, epsilon0, nIter, dt);

[minVal0, idx0] = min(msd0(:));
[k0,l0]         = ind2sub([coarseN, coarseN], idx0);
lstar0 = lambda0(k0);
estar0 = epsilon0(l0);

% ---------- 2. refinement window --------------------------------------
lamLo = max(lstar0 * 10^(-halfDecades), lambdaRange(1));
lamHi = min(lstar0 * 10^( halfDecades), lambdaRange(2));
epsLo = max(estar0 * 10^(-halfDecades), epsilonRange(1));
epsHi = min(estar0 * 10^( halfDecades), epsilonRange(2));

% widen a tiny window so logspace has >1 point
if lamHi/lamLo < 1.01, lamLo = lstar0/1.5; lamHi = lstar0*1.5; end
if epsHi/epsLo < 1.01, epsLo = estar0/1.5; epsHi = estar0*1.5; end

lambda1  = logspace(log10(lamLo),  log10(lamHi),  refineN);
epsilon1 = logspace(log10(epsLo),  log10(epsHi), refineN);

msd1 = calculate_msd(f, lambda1, epsilon1, nIter, dt);

[minVal1, idx1] = min(msd1(:));
[k1,l1]         = ind2sub([refineN, refineN], idx1);
lstar1 = lambda1(k1);
estar1 = epsilon1(l1);

% ---------- 3. package results ----------------------------------------
result.lambdaCoarse   = lambda0;
result.epsilonCoarse  = epsilon0;
result.msdCoarse      = msd0;
result.bestCoarse     = [lstar0, estar0];
result.minCoarse      = minVal0;

result.lambdaRefine   = lambda1;
result.epsilonRefine  = epsilon1;
result.msdRefine      = msd1;
result.bestRefine     = [lstar1, estar1];
result.minRefine      = minVal1;
end
