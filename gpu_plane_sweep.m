function msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt)
%GPU_PLANE_SWEEP   Rudin–Osher–Fatemi TV denoising via plane‐sweep on GPU
%   f       – noisy image stack (H×W×T) on GPU
%   lambda  – regularization weight
%   epsilon – small constant to avoid division by zero
%   nIter   – number of outer iterations
%   dt      – time‐step size

% Preallocate
[H,W,T] = size(f);
u = f;                             % initialize
msd = zeros(H,W,T,'like',f);

% Decide batch size: process a subset of frames at a time to fit GPU memory
maxBatch = 16;                     % e.g. up to 16 time‑slices per batch
nBatches = ceil(T/maxBatch);

for it = 1:nIter
    % Sweep over each batch of time‐slices
    for b = 1:nBatches
        idx = (b-1)*maxBatch + (1:maxBatch);
        idx = idx(idx<=T);         % clip last batch

        % Extract batch, keep it on GPU
        u_batch = u(:,:,idx);

        % Compute finite differences along x and y in one go
        ux = diff(u_batch,1,2);                     % size H×(W‑1)×Nb
        uy = diff(u_batch,1,1);                     % size (H‑1)×W×Nb
        % Pad to original size
        ux = cat(2, ux, zeros(H,1,numel(idx),'like',ux));
        uy = cat(1, uy, zeros(1,W,numel(idx),'like',uy));

        % Gradient magnitude
        grad_norm = sqrt(ux.^2 + uy.^2 + epsilon^2);

        % Divergence (vectorized): compute backward differences
        div_x = [ux(:,1,:) , ux(:,2:end,:) - ux(:,1:end-1,:)];
        div_y = [uy(1,:,:) ; uy(2:end,:,:) - uy(1:end-1,:)];
        div = div_x + div_y;   

        % TV update: one explicit gradient‐descent step
        u_batch = u_batch + dt * (div - lambda*(u_batch - f(:,:,idx)));

        % Write back
        u(:,:,idx) = u_batch;
    end
end

msd = u;
end
