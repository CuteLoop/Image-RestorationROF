function msd = gpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
%GPU_PLANE_SWEEP  –  Explicit ROF TV sweep on GPU with batching
%
%   fHost : H×W noisy plane (uint16 or single)
%   lambda, epsilon : scalars (or vectors if you later broadcast)
%   nIter  : iterations
%   dt     : time step  (e.g. 0.25)

% ---- move to GPU and harmonise types ---------------------------------
f      = gpuArray(single(fHost));      % single gpuArray
lambda = cast(lambda,  'like', f);     % ensure same class
epsilon= cast(epsilon, 'like', f);

[H,W,~] = size(f);
u = f;                                 % initial guess
maxBatch = 16;                         % tune to fit VRAM
T = 1;                                 % time dimension in your version
msd = zeros(H,W,T,'like',f);

for it = 1:nIter
    for batch = 1:ceil(T/maxBatch)
        idx = (batch-1)*maxBatch + (1:maxBatch);
        idx = idx(idx<=T);

        u_batch = u(:,:,idx);

        ux = diff(u_batch,1,2);  ux = cat(2,ux,zeros(H,1,'like',ux));
        uy = diff(u_batch,1,1);  uy = cat(1,uy,zeros(1,W,'like',uy));

        grad_norm = sqrt(ux.^2 + uy.^2 + epsilon.^2);

        px = ux ./ grad_norm;
        py = uy ./ grad_norm;

        divx = [px(:,1,:) , px(:,2:end,:) - px(:,1:end-1,:)];
        divy = [py(1,:,:) ; py(2:end,:,:) - py(1:end-1,:,:)];
        div  = divx + divy;

        u_batch = u_batch + dt * (div - lambda.*(u_batch - f(:,:,idx)));

        u(:,:,idx) = u_batch;
    end
end
msd = u;    % or compute √MSE here
end
