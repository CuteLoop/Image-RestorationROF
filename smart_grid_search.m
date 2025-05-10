function result = smart_grid_search(f, lambdaRange, epsilonRange, coarseN, refineN, halfDecades, nIter, dt)
%SMART_GRID_SEARCH  Two-stage ROF parameter tuning on one image plane
%
% Usage:
%   result = smart_grid_search(f, lambdaRange, epsilonRange, ...
%                              coarseN, refineN, halfDecades, nIter, dt)
%
% Inputs:
%   f             – H×W single or gpuArray image
%   lambdaRange   – [λ_min, λ_max], e.g. [1e-4, 1]
%   epsilonRange  – [ε_min, ε_max], e.g. [1e-5, 1e-1]
%   coarseN       – #points per axis in coarse scan (e.g. 10)
%   refineN       – #points per axis in refinement scan (e.g. 15)
%   halfDecades   – half-width of refine window in decades (e.g. 0.5)
%   nIter, dt     – solver settings passed to calculate_msd
%
% Output struct fields:
%   result.lambdaCoarse, result.epsilonCoarse : coarse grids
%   result.msdCoarse                          : coarse MSD surface
%   result.lambdaRefine, result.epsilonRefine : refined grids
%   result.msdRefine                          : refined MSD surface
%   result.bestCoarse = [λ*,ε*] in coarse scan
%   result.bestRefine = [λ*,ε*] in refine scan

% 1) Build coarse log-spaced grids
lambda0  = logspace(log10(lambdaRange(1)),  log10(lambdaRange(2)),  coarseN);
epsilon0 = logspace(log10(epsilonRange(1)), log10(epsilonRange(2)), coarseN);

% 2) Evaluate coarse MSD
msd0 = calculate_msd(f, lambda0, epsilon0, nIter, dt);

% 3) Find coarse optimum
[minVal0, linIdx0]   = min(msd0(:));
[k0, l0]             = ind2sub([coarseN,coarseN], linIdx0);
lstar0 = lambda0(k0);
estar0 = epsilon0(l0);

% 4) Build refined grids around (lstar0,estar0)
lamLo = lstar0 * 10^(-halfDecades);
lamHi = lstar0 * 10^( halfDecades);
epsLo = estar0 * 10^(-halfDecades);
epsHi = estar0 * 10^( halfDecades);

lambda1  = logspace(log10(lamLo),  log10(lamHi),  refineN);
epsilon1 = logspace(log10(epsLo), log10(epsHi), refineN);

% 5) Evaluate refined MSD
msd1 = calculate_msd(f, lambda1, epsilon1, nIter, dt);

% 6) Find refined optimum
[minVal1, linIdx1]   = min(msd1(:));
[k1, l1]             = ind2sub([refineN,refineN], linIdx1);
lstar1 = lambda1(k1);
estar1 = epsilon1(l1);

% 7) Package results
result.lambdaCoarse   = lambda0;
result.epsilonCoarse  = epsilon0;
result.msdCoarse      = msd0;
result.bestCoarse     = [lstar0, estar0];

result.lambdaRefine   = lambda1;
result.epsilonRefine  = epsilon1;
result.msdRefine      = msd1;
result.bestRefine     = [lstar1, estar1];
end
