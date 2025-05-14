function noisy = add_noise(img, type, std)
    switch lower(type)
        case 'gaussian'
            if nargin < 3, std = 0.1; end
            noisy = img + std * randn(size(img));
        case 's&p'
            noisy = imnoise(img, 'salt & pepper', 0.1);
        otherwise
            error('Unknown noise type: %s', type);
    end
end
