function u = smooth_image_rof(f, lambda, epsilon, nIter, dt)
%SMOOTH_IMAGE_ROF  Regularised ROF TV‑denoise (explicit scheme, Neumann BCs).
%
%   u = smooth_image_rof(f, lambda, epsilon [, nIter, dt])
%
%   INPUT
%     f        : H×W array (double|single) – degraded image plane
%     lambda   : 1×K or K×1 vector ( > 0 )
%     epsilon  : 1×L or L×1 vector ( > 0 )
%     nIter    : # iterations           (default 300)
%     dt       : time step Δt           (default 0.25, CFL‑safe for h=1)
%
%   OUTPUT
%     u        : H×W×K×L array – denoised images for every (λk, εl)
%
%   • Vectorised over both parameters (no for‑loops on K, L).
%   • Homogeneous Neumann BCs enforced via edge‑replication.
%   • Runs on GPU transparently if one is available.

% ---------------- defaults ----------------
if nargin < 4, nIter = 300; end
if nargin < 5, dt    = 0.25; end    % h == 1 pixel

lambda  = lambda(:);                % ensure column
epsilon = epsilon(:);               % ensure column

K = numel(lambda);
L = numel(epsilon);

% -------------- broadcast 4‑D stacks -------------
f      = single(f);                 % work in single to save RAM
f      = repmat(f, 1, 1, K, L);     % H×W×K×L
u      = f;                         % initial guess = data

% parameter grids shaped 1×1×K×L  (implicit expansion friendly)
Lambda = reshape(lambda, 1, 1, K, 1);
EpsTV  = reshape(epsilon,1, 1, 1, L);

% -------------- push to GPU if present -----------
try
    g = gpuDevice;                  %#ok<NASGU>
    f = gpuArray(f); u = f;         % (re‑assign keeps shape)
    Lambda = gpuArray(Lambda);
    EpsTV  = gpuArray(EpsTV);
catch
    % no compatible GPU – run on CPU silently
end

% derivative kernels (forward diff)
kx = [-1 1];                        % ∂/∂x forward
ky = [-1; 1];                       % ∂/∂y forward

for it = 1:nIter
    % forward differences (replicate bc)
    ux = imfilter(u, kx, 'replicate', 'same');
    uy = imfilter(u, ky, 'replicate', 'same');

    gmag = sqrt( EpsTV.^2 + ux.^2 + uy.^2 );

    px = ux ./ gmag;
    py = uy ./ gmag;

    % divergence (backward diff)
    divpx = imfilter(px, -fliplr(kx), 'replicate', 'same');
    divpy = imfilter(py, -flipud(ky), 'replicate', 'same');
    divp  = divpx + divpy;          % h = 1

    % explicit Euler update
    u = u + dt * ( divp - (u - f) ./ Lambda );
end

u = gather(u);                      % return to host if on GPU
end
