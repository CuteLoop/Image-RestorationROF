function img = generate_synthetic_image(type, size)
    if nargin < 2
        size = [128, 128];
    end
    [X, Y] = meshgrid(linspace(0, 1, size(2)), linspace(0, 1, size(1)));

    switch lower(type)
        case 'gradient'
            img = X + Y;
        case 'checkerboard'
            img = mod(floor(10*X) + floor(10*Y), 2);
        case 'sinusoidal'
            img = sin(2*pi*5*X) + cos(2*pi*5*Y);
        otherwise
            error('Unknown synthetic image type: %s', type);
    end
end
