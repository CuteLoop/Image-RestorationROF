function allResults = foreach_plane_search(Iplanar, coarseArgs, refineArgs, solverArgs)
%FOREACH_PLANE_SEARCH  Apply smart_grid_search to each colour plane
%
% Usage:
%   args = struct( ...
%      'lambdaRange', [1e-4,1], ...
%      'epsilonRange',[1e-5,1e-1], ...
%      'coarseN', 10, ...
%      'refineN', 15, ...
%      'halfDecades', 0.5 );
%   solver = struct('nIter',300,'dt',0.25);
%   results = foreach_plane_search(Iplanar, args, solver);
%
% Input:
%   Iplanar    – H×W×4 array of raw sensor planes
%   coarseArgs – struct with fields lambdaRange, epsilonRange, coarseN, refineN, halfDecades
%   solverArgs – struct with fields nIter, dt
%
% Output:
%   allResults – 1×4 struct array with fields from smart_grid_search

planes = ["R","G1","G2","B"];
numPlanes = size(Iplanar,3);
allResults = repmat(struct(),1,numPlanes);

for p = 1:numPlanes
    fprintf('\n=== Processing %s plane ===\n', planes(p));
    fPlane = single(Iplanar(:,:,p));  % cast to single

    % Call the two-stage search
    result = smart_grid_search( ...
        fPlane, ...
        coarseArgs.lambdaRange, ...
        coarseArgs.epsilonRange, ...
        coarseArgs.coarseN, ...
        coarseArgs.refineN, ...
        coarseArgs.halfDecades, ...
        solverArgs.nIter, ...
        solverArgs.dt);

    % Store & print summary
    allResults(p).plane       = planes(p);
    allResults(p).bestCoarse  = result.bestCoarse;
    allResults(p).bestRefine  = result.bestRefine;
    allResults(p).minCoarse   = min(result.msdCoarse(:));
    allResults(p).minRefine   = min(result.msdRefine(:));

    fprintf(' Coarse  minMSD=%.4f at λ=%.3g, ε=%.3g\n', ...
            allResults(p).minCoarse, result.bestCoarse);
    fprintf(' Refined minMSD=%.4f at λ=%.3g, ε=%.3g\n', ...
            allResults(p).minRefine, result.bestRefine);
end
end
