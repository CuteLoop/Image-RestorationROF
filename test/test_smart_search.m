clc; fprintf('\n=== Running smart-search unit test ===\n');
H=64;W=64;[X,Y]=meshgrid(linspace(0,1,W),linspace(0,1,H)); base=0.6*X+0.4*Y;
Iplanar=cat(3,base+0.02*randn(H,W),base+0.01*randn(H,W),base+0.01*randn(H,W),base+0.03*randn(H,W));
grid=struct('lambdaRange',[1e-4,1],'epsilonRange',[1e-5,1e-2],'coarseN',6,'refineN',8,'halfDecades',0.3);
solver=struct('nIter',50,'dt',0.2); run_one=@(im) smart_grid_search(im,grid.lambdaRange,grid.epsilonRange,grid.coarseN,grid.refineN,grid.halfDecades,solver.nIter,solver.dt);
fprintf('\n[1] CPU seq... '); setappdata(0,'rof_overrideGPU',false); delete(gcp('nocreate'));
t1=tic; run_one(Iplanar(:,:,1)); t_seq=toc(t1); fprintf('%6.3f s\n',t_seq);
fprintf('[2] CPU par... '); setappdata(0,'rof_overrideGPU',false); delete(gcp('nocreate'));
pool=parpool('Processes',feature('numCores')); t2=tic; parfor p=1:4, run_one(Iplanar(:,:,p)); end; t_par=toc(t2); delete(pool); fprintf('%6.3f s\n',t_par);
fprintf('[3] GPU solve... '); setappdata(0,'rof_overrideGPU',true); delete(gcp('nocreate')); gpuDevice; run_one(Iplanar(1:2,1:2,1));
t3=tic; run_one(Iplanar(:,:,1)); t_gpu=toc(t3); rmappdata(0,'rof_overrideGPU'); fprintf('%6.3f s\n',t_gpu);
% …
fprintf('[4] Sanity... ');
U4D = smooth_image_rof(single(Iplanar(:,:,1)), 1e-6, 1e-3, solver.nIter, solver.dt);
u    = squeeze(U4D(:,:,1,1));                  % pull out the 2D result
err  = max(abs(u(:) - Iplanar(:,:,1)));        
fprintf('maxErr=%6.3e\n', err);
% …
fprintf('\nSummary:\n CPU seq=%6.3f s\n CPU par=%6.3f s (×%.1f)\n GPU solve=%6.3f s (×%.1f)\n',t_seq,t_par,t_seq/t_par,t_gpu,t_seq/t_gpu);