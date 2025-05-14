Absolutely! Here's your updated **utility function archive**, now including:

* `plot_rof_grid.m` – for visualizing ROF denoising across parameter grids
* `fake_colorize.m` – for presentation-ready color tinting of grayscale planes

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

## ✅ `utils/fake_colorize.m`

```matlab
function rgb = fake_colorize(gray, plane)
% FAKE_COLORIZE Apply color tint to grayscale image
%   gray  — 2D image in [0,1]
%   plane — 'R', 'G1', 'G2', 'B'

    if isa(gray, 'uint8') || isa(gray, 'uint16')
        gray = im2single(gray);
    end

    switch upper(plane)
        case 'R'
            rgb = cat(3, gray, zeros(size(gray)), zeros(size(gray)));
        case {'G', 'G1', 'G2'}
            rgb = cat(3, zeros(size(gray)), gray, zeros(size(gray)));
        case 'B'
            rgb = cat(3, zeros(size(gray)), zeros(size(gray)), gray);
        otherwise
            rgb = repmat(gray, 1, 1, 3);  % fallback to grayscale
    end
end
```

---

## ✅ `utils/plot_rof_grid.m`

```matlab
function plot_rof_grid(f, outFile, planeLabel, colorize)
% PLOT_ROF_GRID Visualize 4x4 grid of ROF denoised results
%   f         — grayscale input image
%   outFile   — optional PNG path
%   planeLabel— 'R', 'G1', etc.
%   colorize  — true for fake RGB tint

    if nargin < 2, outFile = ''; end
    if nargin < 3, planeLabel = ''; end
    if nargin < 4, colorize = false; end

    lambdas  = logspace(0, -3, 4);
    epsilons = logspace(-1, -4, 4);

    if isa(f, 'uint8') || isa(f, 'uint16')
        f = im2single(f);
    end

    u = smooth_image_rof(f, lambdas, epsilons);

    figure;
    tiledlayout(4, 4, 'Padding','compact','TileSpacing','compact');

    for i = 1:4
        for j = 1:4
            nexttile;
            img = u(:,:,i,j);
            if colorize
                imshow(fake_colorize(img, planeLabel));
            else
                imagesc(img); colormap gray;
            end
            axis image off;
            title(sprintf('\\lambda=%.3g\\newline\\epsilon=%.3g', ...
                lambdas(i), epsilons(j)));
        end
    end

    if colorize
        sgtitle(['Fake Colorized – Plane: ', planeLabel]);
    elseif planeLabel ~= ""
        sgtitle(['ROF Output – Plane: ', planeLabel]);
    else
        sgtitle('ROF Output Grid');
    end

    if ~isempty(outFile)
        folder = fileparts(outFile);
        if ~isempty(folder) && ~isfolder(folder)
            mkdir(folder);
        end
        exportgraphics(gcf, outFile, 'Resolution', 150);
        fprintf('✅ Saved grid to %s\n', outFile);
    end
end
```

---

Let me know if you'd like:

* `utils/compare_rof_outputs.m` to visualize `u - f`
* `utils/save_all_rofs.m` for batch saving from a 4D array
* Auto-annotated LaTeX snippet generator for each figure

You're now locked and loaded with a full ROF visualization suite 🔧🧠🖼️
