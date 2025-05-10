%% test_smart_search.m  –  sanity checks for smart_grid_search helpers
clc; fprintf('\n=== Running smart-search unit test ===\n');

% ------------------------------------------------------------------ 1
%  Synthetic single plane: 64×64 gradient + noise
H = 64; W = 64;
[X,Y] = meshgrid(linspace(0,1,W),linspace(0,1,H));
plane = single( 0.6*X + 0.4*Y + 0.05*randn(H,W,'single') );

coarseArgs = struct('lambdaRange',[1e-4,1], ...
                    'epsilonRange',[1e-5,1e-2], ...
                    'coarseN',6,'refineN',8,'halfDecades',0.3);
solverArgs = struct('nIter',50,'dt',0.2);  % lighter settings for test

fprintf('• Testing smart_grid_search on single plane …\n');
res = smart_grid_search(plane, ...
        coarseArgs.lambdaRange, coarseArgs.epsilonRange, ...
        coarseArgs.coarseN, coarseArgs.refineN, ...
        coarseArgs.halfDecades, ...
        solverArgs.nIter, solverArgs.dt);

% basic assertions
assert(isfield(res,'msdCoarse') && isfield(res,'msdRefine'));
assert(all(size(res.msdCoarse) == [coarseArgs.coarseN, coarseArgs.coarseN]));
assert(all(size(res.msdRefine)  == [coarseArgs.refineN, coarseArgs.refineN]));
assert(numel(res.bestRefine)==2);

% ------------------------------------------------------------------ 2
%  Synthetic 4-plane stack (R,G1,G2,B) = plane + noise variations
Iplanar = cat(3, ...
    plane + 0.02*randn(H,W,'single'), ...
    plane + 0.01*randn(H,W,'single'), ...
    plane + 0.01*randn(H,W,'single'), ...
    plane + 0.03*randn(H,W,'single'));

fprintf('• Testing foreach_plane_search on 4-plane stack …\n');
allRes = foreach_plane_search(Iplanar, coarseArgs, solverArgs);

assert(numel(allRes)==4);
for p = 1:4
    assert(isfield(allRes(p),'bestRefine'));
end

fprintf('\n✅  All tests passed!\n');
