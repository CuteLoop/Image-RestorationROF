function u = smooth_image_rof(f, lambda, epsilon, nIter, dt)
%SMOOTH_IMAGE_ROF  Regularised ROF TV denoising with Neumann BCs
%   u = smooth_image_rof(f, lambda, epsilon [, nIter, dt])
%
%   f        : H×W degraded image (single | double | gpuArray)
%   lambda   : vector length K   ( > 0 )
%   epsilon  : vector length L   ( > 0 )
%   nIter    : iterations per pair      (default 300)
%   dt       : time step Δt             (default 0.25)
%   -----------------------------------------------
%   Returns  u  of size  H×W×K×L   on host memory.

    if nargin < 4, nIter = 300; end
    if nargin < 5, dt    = 0.25; end

    if isa(f,'gpuArray')
        useGPU = true;
    else
        useGPU = false;
        f = single(f);                         % work in single on CPU
    end

    lambda  = lambda(:);
    epsilon = epsilon(:);
    K = numel(lambda);  L = numel(epsilon);

    % ------- parfor writes into a linear cell array -------------------
    uCell = cell(K*L,1);

    parfor idx = 1:K*L                  %#ok<PFUNK>
        [k,l] = ind2sub([K,L], idx);
        lam   = lambda(k);
        eps2  = epsilon(l)^2;

        uk = f;                          % initial guess = data
        for it = 1:nIter
            % Symmetric pad for Neumann BCs (adds 1‑pixel border)
            up = padarray(uk,[1 1],'symmetric');

            % Forward gradients
            ux = up(2:end-1,3:end) - up(2:end-1,2:end-1);
            uy = up(3:end,2:end-1) - up(2:end-1,2:end-1);

            gmag = sqrt(eps2 + ux.^2 + uy.^2);

            px = ux ./ gmag;
            py = uy ./ gmag;

            % Divergence with replicate edge (backward diff)
            divx = [px(:,1), px(:,2:end)-px(:,1:end-1)];
            divy = [py(1,:); py(2:end,:)-py(1:end-1,:)];
            div  = divx + divy;

            unew = f - lam * dt * div;

            if norm(unew(:)-uk(:)) / norm(uk(:)) < 1e-4
                uk = unew;  break;
            end
            uk = unew;
        end
        uCell{idx} = gather(uk);         % ensure host copy
    end

    % ------- stitch cells into 4‑D array ------------------------------
    [H,W] = size(f);
    u = zeros(H,W,K,L,'single');
    for idx = 1:K*L
        [k,l] = ind2sub([K,L], idx);
        u(:,:,k,l) = uCell{idx};
    end
end
