function msd = calculate_msd(f, lambda, epsilon, nIter, dt)
%CALCULATE_MSD  Mean‑square difference for a grid of (λ, ε).
%
%   msd = calculate_msd(f, lambda, epsilon [, nIter, dt])
%
%   • Returns a K×L array where K = numel(lambda), L = numel(epsilon).
%   • Uses smooth_image_rof internally.

u = smooth_image_rof(f, lambda, epsilon, nIter, dt);

% MSD over spatial dimensions (1,2).  Result: 1×1×K×L → reshape to K×L
err2 = (u - repmat(single(f),1,1,numel(lambda),numel(epsilon))).^2;
msd  = sqrt( squeeze( mean( mean(err2, 1), 2) ) );   % K×L

end
