function allResults = foreach_plane_search(Iplanar, gridArgs, solverArgs)
planes    = ["R","G1","G2","B"]; numPlanes=size(Iplanar,3);
res0 = smart_grid_search(Iplanar(:,:,1),gridArgs.lambdaRange,gridArgs.epsilonRange,...
    gridArgs.coarseN,gridArgs.refineN,gridArgs.halfDecades,solverArgs.nIter,solverArgs.dt);
res0.plane = planes(1); allResults=repmat(res0,1,numPlanes);
for p=2:numPlanes
  res = smart_grid_search(Iplanar(:,:,1),gridArgs.lambdaRange,gridArgs.epsilonRange,...
    gridArgs.coarseN,gridArgs.refineN,gridArgs.halfDecades,solverArgs.nIter,solverArgs.dt);
  res.plane=planes(p); allResults(p)=res;
end
end