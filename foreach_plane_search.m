function allResults = foreach_plane_search(Iplanar, gridArgs, solverArgs)
%FOREACH_PLANE_SEARCH  Two-stage ROF sweep on every Bayer colour plane
%
%   allResults = foreach_plane_search(Iplanar, gridArgs, solverArgs)
%
% INPUT
%   Iplanar   : H×W×4 array of raw sensor planes  (R, G1, G2, B)
%   gridArgs  : struct with fields
%                 lambdaRange   [λ_min λ_max]
%                 epsilonRange  [ε_min ε_max]
%                 coarseN       points/axis in coarse grid
%                 refineN       points/axis in refine grid
%                 halfDecades   half-width of refine window (decades)
%   solverArgs: struct with fields
%                 nIter         iterations in ROF solver
%                 dt            time-step
%
% OUTPUT
%   allResults: 1×4 struct array (one per plane) containing
%                 plane          – "R","G1","G2","B"
%                 *all* fields returned by smart_grid_search

planes    = ["R","G1","G2","B"];
numPlanes = size(Iplanar, 3);

% -- 1) Run first plane to discover the result struct fields ----------
fprintf('\n=== Processing %s plane ===\n', planes(1));
f0 = single(Iplanar(:,:,1));
res0 = smart_grid_search( ...
    f0, ...
    gridArgs.lambdaRange, gridArgs.epsilonRange, ...
    gridArgs.coarseN,    gridArgs.refineN,    gridArgs.halfDecades, ...
    solverArgs.nIter,    solverArgs.dt );
res0.plane = planes(1);

% -- 2) Pre-allocate allResults as an array of identical structs -------
allResults = repmat(res0, 1, numPlanes);

% -- 3) Fill in the first entry (already computed) --------------------
allResults(1) = res0;

% -- 4) Loop over remaining planes ------------------------------------
for p = 2:numPlanes
    fprintf('\n=== Processing %s plane ===\n', planes(p));
    fPlane = single(Iplanar(:,:,p));

    % Two-stage parameter search
    res = smart_grid_search( ...
        fPlane, ...
        gridArgs.lambdaRange, gridArgs.epsilonRange, ...
        gridArgs.coarseN,    gridArgs.refineN,    gridArgs.halfDecades, ...
        solverArgs.nIter,    solverArgs.dt );
    res.plane = planes(p);

    allResults(p) = res;

    fprintf('  Coarse  min MSD = %.4f   at λ = %.3g, ε = %.3g\n', ...
            res.minCoarse, res.bestCoarse);
    fprintf('  Refined min MSD = %.4f   at λ = %.3g, ε = %.3g\n', ...
            res.minRefine, res.bestRefine);
end
end
