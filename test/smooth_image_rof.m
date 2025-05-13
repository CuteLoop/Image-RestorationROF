function u = smooth_image_rof(f, lambda, epsilon)
    if gpuDeviceCount > 0
        f = gpuArray(f);
    end

    [H, W] = size(f);
    lambda = lambda(:);  epsilon = epsilon(:);
    K = length(lambda);  L = length(epsilon);
    uCell = cell(K*L, 1);

    max_iter = 100;  tol = 1e-4;

    parfor idx = 1:(K*L)
        [k, l] = ind2sub([K, L], idx);
        lam = lambda(k);  eps2 = epsilon(l)^2;
        uk = f;

        for iter = 1:max_iter
            up = padarray(uk, [1 1], 'symmetric');
            ux = up(2:end-1,3:end) - up(2:end-1,2:end-1);
            uy = up(3:end,2:end-1) - up(2:end-1,2:end-1);
            mag = sqrt(eps2 + ux.^2 + uy.^2);
            px = ux ./ mag;
            py = uy ./ mag;
            pxp = padarray(px, [0 1], 'pre');
            pyp = padarray(py, [1 0], 'pre');
            div = pxp(:,2:end) - pxp(:,1:end-1) + pyp(2:end,:) - pyp(1:end-1,:);
            unew = f - lam * div;

            rel_change = norm(unew(:)-uk(:)) / norm(uk(:));
            if rel_change < tol, break; end
            uk = unew;
        end

        uCell{idx} = gather(uk);
    end

    % Reassemble into 4D array
    u = zeros(H, W, K, L, 'like', f);
    for idx = 1:(K*L)
        [k, l] = ind2sub([K, L], idx);
        u(:,:,k,l) = uCell{idx};
    end
end