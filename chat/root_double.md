Absolutely — here's the **fully updated ROF image restoration archive** with precision fixes for `double` (CPU) and `single` (GPU), suitable for long-term record keeping and GitHub archiving. This reflects all recent updates we've discussed.

---

## ✅ `smooth_image_rof.m`

```matlab
function u = smooth_image_rof(f, lambda, epsilon, nIter, dt)
%SMOOTH_IMAGE_ROF  Vectorized ROF solver over λ×ε grid, CPU/GPU adaptive

if nargin < 4, nIter = 300; dt = 0.25; end
useGPU = exist('rof_config','file') && rof_config() && gpuDeviceCount > 0;

if useGPU
    f = gpuArray(single(f));
else
    f = double(f);
end

[H, W] = size(f);
lambda = lambda(:).'; epsilon = epsilon(:).';
K = numel(lambda); L = numel(epsilon);
u = zeros(H, W, K, L, 'like', f);
tol = 1e-4;

for k = 1:K
  for l = 1:L
    lam = lambda(k); eps = epsilon(l);
    uk = f;
    for it = 1:nIter
      ux = [diff(uk,1,2), zeros(H,1,'like',uk)];
      uy = [diff(uk,1,1); zeros(1,W,'like',uk)];
      mag = sqrt(eps.^2 + ux.^2 + uy.^2);
      px = ux ./ mag; py = uy ./ mag;
      div = [px(:,1), diff(px,1,2)] + [py(1,:); diff(py,1,1)];
      un = f - lam * div;
      if norm(un - uk, 'fro') / norm(uk, 'fro') < tol, break; end
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

if nargin < 4, nIter = 300; dt = 0.25; end
useGPU = exist('rof_config','file') && rof_config() && gpuDeviceCount > 0;

if useGPU
    msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt);
else
    msd = cpu_plane_sweep(f, lambda, epsilon, nIter, dt);
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

f = double(fHost);  % ✅ ensure double on CPU
[H,W] = size(f);
lambda = lambda(:); epsilon = epsilon(:);
K = numel(lambda); L = numel(epsilon);
msd = zeros(K, L, 'like', f);

overhead = 7; bytesPlane = H * W * 8;

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

g = gpuDevice(); freeB = g.AvailableMemory; totalB = g.TotalMemory;
f = gpuArray(single(fHost));
[H,W] = size(f);
lambda = lambda(:).'; epsilon = epsilon(:).';
K = numel(lambda); L = numel(epsilon);
msd = zeros(K, L, 'like', f);

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
  lamSub = reshape(single(lambda(kIdx)),1,1,1,[]);
  for l0 = 1:blk:L
    lIdx = l0:min(l0+blk-1,L);
    epsSub = reshape(single(epsilon(lIdx)),1,1,1,[]);
    uTile = smooth_image_rof(f, lamSub, epsSub, nIter, dt);
    err2 = (uTile - f).^2;
    msd(kIdx,lIdx) = gather(sqrt(mean(mean(err2,1),2)));
  end
end
end
```

---

## ✅ `foreach_plane_search.m`

```matlab
function allResults = foreach_plane_search(Iplanar, gridArgs, solverArgs)
planes = ["R", "G1", "G2", "B"];
numPlanes = size(Iplanar, 3);

res0 = smart_grid_search(Iplanar(:,:,1), ...
    gridArgs.lambdaRange, gridArgs.epsilonRange, ...
    gridArgs.coarseN, gridArgs.refineN, gridArgs.halfDecades, ...
    solverArgs.nIter, solverArgs.dt);
res0.plane = planes(1);
allResults = repmat(res0, 1, numPlanes);

for p = 2:numPlanes
  res = smart_grid_search(Iplanar(:,:,p), ...
    gridArgs.lambdaRange, gridArgs.epsilonRange, ...
    gridArgs.coarseN, gridArgs.refineN, gridArgs.halfDecades, ...
    solverArgs.nIter, solverArgs.dt);
  res.plane = planes(p);
  allResults(p) = res;
end
end
```

---

## ✅ `test/test_precision_safety.m`

```matlab
function test_precision_safety()
    disp('Running precision safety test...');
    f = rand(64);  % Default: double
    setappdata(0, 'rof_overrideGPU', false);

    u = smooth_image_rof(f, 1.0, 0.01);
    assert(strcmp(class(u), 'double'), '❌ Output is not double on CPU');

    msd = calculate_msd(f, 1.0, 0.01);
    assert(strcmp(class(msd), 'double'), '❌ MSD not double on CPU');

    disp('✅ CPU path uses double precision as expected.');
end
```

---

## ✅ `test/test_memory_requirements.m`

```matlab
function test_memory_requirements()
    disp('=== Running memory requirement test for ROF ===');

    H = 2000; W = 3000; K = 20; L = 20;
    bytesPerElement = 8;  % double
    totalBytes = H * W * K * L * bytesPerElement;
    totalGB = totalBytes / 2^30;

    fprintf('Image size:        %d x %d\n', H, W);
    fprintf('Grid size:         %d x %d\n', K, L);
    fprintf('Precision:         double (%d bytes)\n', bytesPerElement);
    fprintf('Total memory need: %.2f GB\n', totalGB);

    try
        m = memory;
        availableGB = m.MemAvailableAllArrays / 2^30;
        fprintf('Available RAM:     %.2f GB\n', availableGB);

        if totalGB > availableGB
            warning('❌ Insufficient RAM for full batch. Reduce block size.');
        else
            disp('✅ Enough RAM for this configuration.');
        end
    catch
        disp('ℹ️ Skipped system memory check (non-Windows system).');
    end
end
```

---

Let me know if you'd like this assembled into a downloadable `.zip`, committed to GitHub, or embedded in your project documentation.
