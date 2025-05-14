function u = smooth_image_rof(f, lambda, epsilon, nIter, dt)
%SMOOTH_IMAGE_ROF  Vectorized ROF solver over λ×ε grid, CPU/GPU adaptive
if nargin<4, nIter=100; dt=0.25; end
useGPU = exist('rof_config','file') && rof_config() && gpuDeviceCount>0;

if useGPU
    f = gpuArray(single(f));
else
    f = double(f);  % ✅ Use full precision on CPU
end

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