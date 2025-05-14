function msd = calculate_msd(f, lambda, epsilon)
    f_gpu = false;
    if gpuDeviceCount > 0
        f = gpuArray(f);
        f_gpu = true;
    end
    [H, W] = size(f);
    lambda = lambda(:);
    epsilon = epsilon(:);
    K = length(lambda);
    L = length(epsilon);
    msd = zeros(K, L, 'like', f);
    chunkSize = 6;
    for i = 1:chunkSize:K
        iEnd = min(i+chunkSize-1, K);
        thisLambda = lambda(i:iEnd);
        Ublock = smooth_image_rof(f, thisLambda, epsilon);
        Fblock = repmat(f, [1,1,iEnd-i+1,L]);
        diff2 = (Ublock - Fblock).^2;
        sums = squeeze(sum(sum(diff2,1),2));
        msd(i:iEnd, :) = sqrt(sums / (H*W));
    end

    if f_gpu, msd = gather(msd); end
end

