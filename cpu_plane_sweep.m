function msd = cpu_plane_sweep(fHost, lambda, epsilon, nIter, dt)
%CPU_PLANE_SWEEP  CPU-based ROF MSD evaluation with chunked batching

if nargin < 4, nIter = 100; dt = 0.25; end
f = double(fHost);
[H, W] = size(f);
lambda = lambda(:); epsilon = epsilon(:);
K = length(lambda); L = length(epsilon);
msd = zeros(K, L, 'like', f);

chunkSize = 6;
for i = 1:chunkSize:K
    iEnd = min(i + chunkSize - 1, K);
    lambdaChunk = lambda(i:iEnd);
    Ublock = smooth_image_rof(f, lambdaChunk, epsilon, nIter, dt);
    Fblock = repmat(f, [1, 1, iEnd - i + 1, L]);
    diff2 = (Ublock - Fblock).^2;
    sums = squeeze(sum(sum(diff2, 1), 2));
    msd(i:iEnd, :) = sqrt(sums / (H * W));
end
end
