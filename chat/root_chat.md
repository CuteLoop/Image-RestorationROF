Absolutely! Here's a full archive of all the main code from your **root directory**, as used in your ROF image restoration project.

---

## ✅ `smooth_image_rof.m`

```matlab
function u = smooth_image_rof(f, lambda, epsilon, nIter, dt)
%SMOOTH_IMAGE_ROF  Vectorized ROF solver over λ×ε grid, CPU/GPU adaptive

if nargin<4, nIter=300; dt=0.25; end
useGPU = exist('rof_config','file') && rof_config() && gpuDeviceCount>0;
if useGPU, f = gpuArray(single(f)); else, f = single(f); end

[H,W] = size(f);
lambda = lambda(:).'; epsilon = epsilon(:).';
K = numel(lambda);   L = numel(epsilon);

u = zeros(H,W,K,L,'like',f);
tol = 1e-4;

for k = 1:K
  for l = 1:L
    lam = lambda(k); eps = epsilon(l);
    uk = f;
    for it=1:nIter
      ux = [diff(uk,1,2), zeros(H,1,'like',uk)];
      uy = [diff(uk,1,1); zeros(1,W,'like',uk)];
      mag = sqrt(eps.^2 + ux.^2 + uy.^2);
      px = ux ./ mag;  py = uy ./ mag;
      div = [px(:,1), diff(px,1,2)] + [py(1,:); diff(py,1,1)];
      un = f - lam * div;
      if norm(un-uk,'fro')/norm(uk,'fro')<tol, break; end
      uk = un;
    end
    u(:,:,k,l) = uk;
  end
end

if useGPU, u = gather(u); end
end
```

---

## ✅ `calculate_msd.m`

```matlab
function msd = calculate_msd(f, lambda, epsilon, nIter, dt)
%CALCULATE_MSD  Batch‐wise MSD over λ×ε grid, CPU/GPU dispatch

if nargin<4, nIter=300; dt=0.25; end
useGPU = exist('rof_config','file') && rof_config() && gpuDeviceCount>0;

if useGPU
  msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt);
else
  msd = cpu_plane_sweep(f, lambda, epsilon, nIter, dt);
end
end
```

---

## ✅ `rof_config.m`

```matlab
function tf = rof_config()
%ROF_CONFIG  Master switch for GPU usage (overridable in tests)
if isappdata(0,'rof_overrideGPU')
    tf = getappdata(0,'rof_overrideGPU');
else
    tf = true;
end
end
```

---

## ✅ `cpu_plane_sweep.m`

```matlab
function msd = cpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
% Memory‐adaptive CPU batching for ROF MSD

try m = memory; freeB = m.MemAvailableAllArrays; catch; freeB = 4*2^30; end
freeB = 0.8 * double(freeB);
f = single(fHost); [H,W] = size(f);
lambda = lambda(:); epsilon = epsilon(:);
K = numel(lambda); L = numel(epsilon);
msd = zeros(K, L, 'single');
overhead = 7; bytesPlane = H * W * 4;

blk = 32;
while blk > 1
  tileB = overhead * bytesPlane * blk * blk + bytesPlane;
  if tileB < freeB, break; end
  blk = blk / 2;
end
blk = max(1, blk);

for k0 = 1:blk:K
  kIdx = k0:min(k0+blk-1,K); lamSub = lambda(kIdx);
  for l0 = 1:blk:L
    lIdx = l0:min(l0+blk-1,L); epsSub = epsilon(lIdx);
    uTile = smooth_image_rof(f, lamSub, epsSub, nIter, dt);
    err2 = (uTile - f).^2;
    msd(kIdx,lIdx) = sqrt(mean(mean(err2,1),2));
  end
end
end
```

---

## ✅ `gpu_plane_sweep.m`

```matlab
function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
% Memory‐adaptive GPU batching for ROF MSD

g = gpuDevice; freeB = g.AvailableMemory; totalB = g.TotalMemory;
f = gpuArray(single(fHost));
[H,W] = size(f);
lambda = cast(lambda(:).','single'); epsilon = cast(epsilon(:).','single');
K = numel(lambda); L = numel(epsilon);
msd = zeros(K,L,'single');

overhead = 7; bytesPlane = H * W * 4;
blk = 32;
while blk > 1
  bytes4D = H * W * blk * blk * 4;
  if bytes4D < 0.8 * totalB && (overhead * bytes4D + bytesPlane) < 0.8 * freeB
    break;
  end
  blk = blk / 2;
end
blk = max(1, blk);

for k0 = 1:blk:K
  kIdx = k0:min(k0+blk-1,K);
  lamSub = reshape(lambda(kIdx),1,1,1,[]);
  for l0 = 1:blk:L
    lIdx = l0:min(l0+blk-1,L);
    epsSub = reshape(epsilon(lIdx),1,1,1,[]);
    uTile = smooth_image_rof(f, lamSub, epsSub, nIter, dt);
    err2 = (uTile - f).^2;
    msd(kIdx,lIdx) = gather(sqrt(mean(mean(err2,1),2)));
  end
end
end
```

---

## ✅ `smart_grid_search.m`

```matlab
function result = smart_grid_search(f, lambdaRange, epsilonRange, ...
                                    coarseN, refineN, halfDecades, nIter, dt)
lambda0  = logspace(log10(lambdaRange(1)), log10(lambdaRange(2)), coarseN);
epsilon0 = logspace(log10(epsilonRange(1)), log10(epsilonRange(2)), coarseN);
msd0 = calculate_msd(f, lambda0, epsilon0, nIter, dt);
[min0,idx0] = min(msd0(:)); [k0,l0] = ind2sub(size(msd0), idx0);
lstar0 = lambda0(k0); estar0 = epsilon0(l0);

lamLo = lstar0 * 10^(-halfDecades); lamHi = lstar0 * 10^(halfDecades);
epsLo = estar0 * 10^(-halfDecades); epsHi = estar0 * 10^(halfDecades);
lambda1 = logspace(log10(lamLo), log10(lamHi), refineN);
epsilon1 = logspace(log10(epsLo), log10(epsHi), refineN);

msd1 = calculate_msd(f, lambda1, epsilon1, nIter, dt);
[min1,idx1] = min(msd1(:)); [k1,l1] = ind2sub(size(msd1), idx1);
lstar1 = lambda1(k1); estar1 = epsilon1(l1);

result = struct( ...
  'lambdaCoarse', lambda0, ...
  'epsilonCoarse', epsilon0, ...
  'msdCoarse', msd0, ...
  'bestCoarse', [lstar0, estar0], ...
  'minCoarse', min0, ...
  'lambdaRefine', lambda1, ...
  'epsilonRefine', epsilon1, ...
  'msdRefine', msd1, ...
  'bestRefine', [lstar1, estar1], ...
  'minRefine', min1);
end
```

---

## ✅ `foreach_plane_search.m`

```matlab
function allResults = foreach_plane_search(Iplanar, gridArgs, solverArgs)
planes = ["R", "G1", "G2", "B"];
numPlanes = size(Iplanar, 3);

res0 = smart_grid_search(single(Iplanar(:,:,1)), ...
    gridArgs.lambdaRange, gridArgs.epsilonRange, ...
    gridArgs.coarseN, gridArgs.refineN, gridArgs.halfDecades, ...
    solverArgs.nIter, solverArgs.dt);
res0.plane = planes(1);
allResults = repmat(res0, 1, numPlanes);

for p = 2:numPlanes
  res = smart_grid_search(single(Iplanar(:,:,p)), ...
    gridArgs.lambdaRange, gridArgs.epsilonRange, ...
    gridArgs.coarseN, gridArgs.refineN, gridArgs.halfDecades, ...
    solverArgs.nIter, solverArgs.dt);
  res.plane = planes(p);
  allResults(p) = res;
end
end
```

---

## ✅ `run_rof_hpc.m`

```matlab
clear; clc; format compact
delete(gcp('nocreate'));

raw_img = './images/DSC00099.ARW';
fprintf('Reading %s …\n', raw_img);

cfa = rawread(raw_img);
Iplanar = raw2planar(cfa);

lambda = logspace(-3, 0, 20);
epsilon = logspace(-4, -1, 20);
nIter = 300; dt = 0.25;

numGPU = gpuDeviceCount;
localC = parcluster('local');
cpuW = max(localC.NumWorkers - numGPU, 1);

pool = parpool('Processes', cpuW + numGPU, 'SpmdEnabled', true);
msdCube = zeros(numel(lambda), numel(epsilon), 4, 'single');

parfor p = 1:4
    msdCube(:,:,p) = calculate_msd(Iplanar(:,:,p), lambda, epsilon, nIter, dt);
end

save('rof_results_singlepool.mat', 'lambda', 'epsilon', 'msdCube');
disp('🏁 Done – results saved');
delete(pool);
```

---

Let me know if you’d like the entire codebase zipped, or this version formatted into a Markdown file for GitHub archiving 📁✅
