function allResults = foreach_plane_search(Iplanar, gridArgs, solverArgs)
%FOREACH_PLANE_SEARCH  Two‑stage ROF search for every Bayer plane
%
%   allResults = foreach_plane_search(Iplanar, gridArgs, solverArgs)
%
% INPUT
%   Iplanar   : H×W×4 array (R,G1,G2,B planes)
%   gridArgs  : struct with fields
%                 lambdaRange   [λ_min, λ_max]
%                 epsilonRange  [ε_min, ε_max]
%                 coarseN       points per axis in coarse grid
%                 refineN       points per axis in refine grid
%                 halfDecades   half‑width of refine window (decades)
%   solverArgs: struct with fields
%                 nIter         #ROF iterations
%                 dt            time‑step
%
% OUTPUT
%   allResults: 1×4 struct array with fields
%                 plane, bestCoarse, bestRefine, minCoarse, minRefine,
%                 lambdaCoarse, epsilonCoarse, msdCoarse, ...
%                 lambdaRefine, epsilonRefine, msdRefine

planes   = ["R","G1","G2","B"];
numPlanes = size(Iplanar,3);
allResults = repmat(struct(), 1, numPlanes);

for p = 1:numPlanes
    fprintf('\n=== Processing %s plane ===\n', planes(p));
    fPlane = single(Iplanar(:,:,p));

    % --- two‑stage search for this plane -----------------------------
    result = smart_grid_search( ...
        fPlane, ...
        gridArgs.lambdaRange, ...
        gridArgs.epsilonRange, ...
        gridArgs.coarseN, ...
        gridArgs.refineN, ...
        gridArgs.halfDecades, ...
        solverArgs.nIter, ...
        solverArgs.dt );

    % --- store & print summary --------------------------------------
    allResults(p)          = result;     % copy full struct
    allResults(p).plane    = planes(p);  % add plane label

    fprintf('  Coarse  minMSD = %.4f  at λ = %.3g, ε = %.3g\n', ...
            min(result.msdCoarse(:)), result.bestCoarse);
    fprintf('  Refined minMSD = %.4f  at λ = %.3g, ε = %.3g\n', ...
            min(result.msdRefine(:)), result.bestRefine);
end
end
