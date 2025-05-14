Absolutely! Here is a clean archive of all **utility functions** you’ve used or will need, collected for permanent reference and future storage.

---

## ✅ `utils/generate_synthetic_image.m`

```matlab
function img = generate_synthetic_image(type, size)
% GENERATE_SYNTHETIC_IMAGE Generate 2D test images
%   img = generate_synthetic_image(type, size)
%   type: 'gradient', 'checkerboard', or 'sinusoidal'
%   size: [H, W] (default: [128, 128])

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
```

---

## ✅ `utils/add_noise.m`

```matlab
function noisy = add_noise(img, type, std)
% ADD_NOISE Adds noise to an image
%   noisy = add_noise(img, 'gaussian', std)
%   noisy = add_noise(img, 's&p')
%
%   Default std = 0.1

    if nargin < 3
        std = 0.1;
    end

    switch lower(type)
        case 'gaussian'
            noisy = img + std * randn(size(img));
        case {'salt', 'salt & pepper', 's&p'}
            noisy = imnoise(img, 'salt & pepper', 0.1);
        otherwise
            error('Unknown noise type: %s', type);
    end
end
```

---

## ✅ `utils/assert_near.m`

```matlab
function assert_near(a, b, tol, msg)
% ASSERT_NEAR Throws error if |a - b| > tol
%   assert_near(a, b, tol, msg)

    if any(abs(a - b) > tol)
        error(msg);
    end
end
```

---

## ✅ `utils/plot_rof_result.m`

```matlab
function plot_rof_result(f, u)
% PLOT_ROF_RESULT Compare original and ROF-denoised image
%   plot_rof_result(f, u)

    subplot(1, 2, 1);
    imagesc(f); axis image off; colormap gray;
    title('Original / Noisy');

    subplot(1, 2, 2);
    imagesc(u); axis image off; colormap gray;
    title('ROF Denoised');
end
```

---

## ✅ `utils/plot_msd_surface.m`

```matlab
function plot_msd_surface(msd, lambdas, epsilons)
% PLOT_MSD_SURFACE Display MSD(f, lambda, epsilon) surface
%   plot_msd_surface(msd, lambdas, epsilons)

    [Λ, Ε] = meshgrid(lambdas, epsilons);
    mesh(Λ, Ε, msd');
    xlabel('\lambda');
    ylabel('\epsilon');
    zlabel('MSD');
    title('MSD(\lambda, \epsilon)');
    grid on;
end
```

---

Let me know if you'd like:

* A version that exports images (e.g., `saveas`, `exportgraphics`)
* Logging support for test output (`diary`, `fprintf` to file)
* Utilities to compare the output of `gpu` vs `cpu` computations for sanity checking numerical drift

This archive is now ready for your future projects or backups 🚀
