%% run_smart_search.m  –  two‐stage parameter search on all 4 planes

% 1) Read & split your RAW into 4 color planes
raw_img   = './images/DSC00099.ARW';
cfa       = rawread(raw_img);
Iplanar   = raw2planar(cfa);    % H×W×4 array

% 2) Define your coarse‐grid and solver settings
coarseArgs = struct( ...
    'lambdaRange',  [1e-4, 1], ...
    'epsilonRange', [1e-5, 1e-1], ...
    'coarseN',      10, ...
    'refineN',      15, ...
    'halfDecades',  0.5 );
solverArgs = struct( ...
    'nIter', 300, ...
    'dt',    0.25 );

% 3) Run the smart search across all 4 Bayer planes
allResults = foreach_plane_search( Iplanar, coarseArgs, solverArgs );

% 4) Save or inspect the results
save('smart_search_results.mat','allResults','-v7.3');
disp(allResults);
% disp('🏁  Done – results saved');