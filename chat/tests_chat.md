\[media pointer="file-service://file-ESWUZ2prTXc6qAw97V9EWP"]
are there any more utils functions that I should be aware of? Absolutely. Here's a **structured layout** of test files and what each will contain. This keeps your code clean, modular, and easy to run in batch or debug individually.

---

# ✅ **Test Suite Structure for ROF Image Restoration**

## 📁 Folder structure:

```
rof_image_restoration/
├── smooth_image_rof.m
├── calculate_msd.m
├── test/
│   ├── run_all_tests.m
│   ├── test_zero_noise.m
│   ├── test_high_noise_recovery.m
│   ├── test_monotonic_lambda.m
│   ├── test_output_shape.m
│   ├── test_boundary_conditions.m
│   ├── test_numerical_stability.m
│   ├── test_gpu_fallback.m
│   ├── test_batch_speedup.m
│   ├── test_visual_check.m
│   ├── test_msd_surface_plot.m
├── utils/
│   ├── generate_synthetic_image.m
│   ├── add_noise.m
│   ├── assert_near.m
│   ├── plot_rof_result.m
```

---

## 📄 **Details of Each File**

### ✅ `test/test_zero_noise.m`

```matlab
f = generate_synthetic_image('gradient');
u = smooth_image_rof(f, 1.0, 0.01);
msd = calculate_msd(f, 1.0, 0.01);
assert_near(msd, 0, 1e-6, 'Zero noise test failed');
disp('✅ Zero noise test passed.');
```

---

### ✅ `test/test_high_noise_recovery.m`

```matlab
u_true = generate_synthetic_image('sinusoidal');
f = add_noise(u_true, 'gaussian', 0.1);
u = smooth_image_rof(f, 2.0, 0.01);
msd = calculate_msd(f, 2.0, 0.01);
assert(msd > 0.01, 'High noise recovery test failed');
disp('✅ High noise recovery test passed.');
```

---

### ✅ `test/test_monotonic_lambda.m`

```matlab
f = generate_synthetic_image('checkerboard');
eps = 0.01;
lambdas = [0.1, 1, 10];
msd_vals = arrayfun(@(l) calculate_msd(f, l, eps), lambdas);
assert(issorted(msd_vals), 'MSD should increase with lambda');
disp('✅ Monotonic lambda test passed.');
```

---

### ✅ `test/test_output_shape.m`

```matlab
f = generate_synthetic_image('gradient');
lambdas = [0.5, 1.0];
epsilons = [0.01, 0.1];
u = smooth_image_rof(f, lambdas, epsilons);
expected_shape = [size(f), length(lambdas), length(epsilons)];
assert(isequal(size(u), expected_shape), 'Output shape test failed');
disp('✅ Output shape test passed.');
```

---

### ⚖️ `test/test_boundary_conditions.m`

```matlab
f = ones(64); % constant image
u = smooth_image_rof(f, 1.0, 0.01);
assert_near(u(1,:), f(1,:), 1e-6, 'Top boundary violated');
assert_near(u(end,:), f(end,:), 1e-6, 'Bottom boundary violated');
disp('✅ Boundary condition test passed.');
```

---

### ⚖️ `test/test_numerical_stability.m`

```matlab
f = generate_synthetic_image('gradient');
u = smooth_image_rof(f, 1.0, 1e-8);
assert(all(isfinite(u(:))), 'Stability test failed (NaNs/Infs)');
disp('✅ Numerical stability test passed.');
```

---

### ⚙️ `test/test_gpu_fallback.m`

```matlab
try
    gpuDevice();
    disp('✅ GPU available: GPU fallback test skipped.');
catch
    f = generate_synthetic_image('gradient');
    u = smooth_image_rof(f, 1.0, 0.01); % should fallback to CPU
    assert(~isempty(u), 'Fallback failed');
    disp('✅ GPU fallback to CPU test passed.');
end
```

---

### ⚙️ `test/test_batch_speedup.m`

```matlab
f = generate_synthetic_image('gradient', [128,128]);
lambdas = linspace(0.1, 1.0, 10);
epsilons = linspace(0.01, 0.1, 10);

tic;
u_batch = smooth_image_rof(f, lambdas, epsilons);
t_batch = toc;

tic;
for i = 1:length(lambdas)
    for j = 1:length(epsilons)
        u = smooth_image_rof(f, lambdas(i), epsilons(j));
    end
end
t_loop = toc;

fprintf('Batch: %.2fs | Loop: %.2fs\n', t_batch, t_loop);
assert(t_batch < t_loop, 'Batch mode not faster');
disp('✅ Batch speedup test passed.');
```

---

### 👁️ `test/test_visual_check.m`

```matlab
f = generate_synthetic_image('checkerboard');
f = add_noise(f, 'gaussian', 0.1);
u = smooth_image_rof(f, 2.0, 0.01);
plot_rof_result(f, u);
title('Visual Test: Denoising');
disp('✅ Visual test (manual check).');
```

---

### 👁️ `test/test_msd_surface_plot.m`

```matlab
f = generate_synthetic_image('gradient', [128, 128]);
lambdas = linspace(0.1, 1.0, 10);
epsilons = linspace(0.01, 0.1, 10);
msd = calculate_msd(f, lambdas, epsilons);
mesh(lambdas, epsilons, msd');
xlabel('\lambda'), ylabel('\epsilon'), zlabel('MSD');
title('MSD(\lambda, \epsilon)');
disp('✅ MSD surface test (manual check).');
```

---

## ✅ `test/run_all_tests.m`

```matlab
disp('=== Running all ROF image restoration tests ===');
test_zero_noise
test_high_noise_recovery
test_monotonic_lambda
test_output_shape
test_boundary_conditions
test_numerical_stability
test_gpu_fallback
test_batch_speedup
test_visual_check
test_msd_surface_plot
disp('=== ✅ All tests complete ===');
```

---

## ✅ `utils/assert_near.m`

```matlab
function assert_near(a, b, tol, msg)
    if any(abs(a - b) > tol)
        error(msg);
    end
end
```
Great — let’s now **complete your test documentation** by adding the **remaining tests with full code** under your `test/` directory. Here's the continuation:

---

### ✅ `test/test_high_noise_recovery.m`

```matlab
u_true = generate_synthetic_image('sinusoidal');
f = add_noise(u_true, 'gaussian', 0.1);
u = smooth_image_rof(f, 2.0, 0.01);
msd = calculate_msd(f, 2.0, 0.01);
assert(msd > 0.01, 'High noise recovery test failed');
disp('✅ High noise recovery test passed.');
```

---

### ✅ `test/test_msd_monotonic_lambda.m`

```matlab
f = generate_synthetic_image('gradient', [128, 128]);
eps = 0.01;
lambdas = [0.1, 1.0, 10.0];
msds = arrayfun(@(l) calculate_msd(f, l, eps), lambdas);
fprintf('MSDs: %g → [%g %g %g]\n', eps, msds);
assert(issorted(msds), 'MSD should increase with lambda');
disp('✅ MSD monotonicity w.r.t. lambda passed.');
```

---

### ✅ `test/test_msd_monotonic_epsilon.m`

```matlab
f = generate_synthetic_image('gradient', [128, 128]);
lambda = 1.0;
epsilons = [0.001, 0.01, 0.1];
msds = arrayfun(@(e) calculate_msd(f, lambda, e), epsilons);
fprintf('MSDs: %g → [%g %g %g]\n', lambda, msds);
assert(all(isfinite(msds)), 'MSD contains NaN or Inf');
disp('ℹ️ MSD trend w.r.t. epsilon observed (manual check)');
```

---

### ✅ `test/test_monotonic_lambda.m` (alias or older name for the same test above)

> Optional to remove if redundant with `test_msd_monotonic_lambda.m`

---

### ✅ `test/test_output_shape.m`

```matlab
f = generate_synthetic_image('gradient');
lambdas = [0.5, 1.0];
epsilons = [0.01, 0.1];
u = smooth_image_rof(f, lambdas, epsilons);
expected_shape = [size(f), length(lambdas), length(epsilons)];
assert(isequal(size(u), expected_shape), 'Output shape mismatch');
disp('✅ Output shape test passed.');
```

---

### ✅ `test/test_boundary_conditions.m`

```matlab
f = ones(64); % constant image
u = smooth_image_rof(f, 1.0, 0.01);
assert_near(u(1,:), f(1,:), 1e-6, 'Top boundary violated');
assert_near(u(end,:), f(end,:), 1e-6, 'Bottom boundary violated');
disp('✅ Boundary condition test passed.');
```

---

### ✅ `test/test_numerical_stability.m`

```matlab
f = generate_synthetic_image('gradient');
u = smooth_image_rof(f, 1.0, 1e-8);
assert(all(isfinite(u(:))), 'Stability test failed (NaNs/Infs)');
disp('✅ Numerical stability test passed.');
```

---

### ✅ `test/test_gpu_fallback.m`

```matlab
try
    gpuDevice(); % if GPU available
    disp('✅ GPU available: fallback test skipped.');
catch
    f = generate_synthetic_image('gradient');
    u = smooth_image_rof(f, 1.0, 0.01); % should fallback to CPU
    assert(~isempty(u), 'Fallback to CPU failed');
    disp('✅ GPU fallback to CPU test passed.');
end
```

---

### ✅ `test/test_batch_speedup.m`

```matlab
f = generate_synthetic_image('gradient', [128, 128]);
lambdas = linspace(0.1, 1.0, 10);
epsilons = linspace(0.01, 0.1, 10);

tic;
u_batch = smooth_image_rof(f, lambdas, epsilons);
t_batch = toc;

tic;
for i = 1:length(lambdas)
    for j = 1:length(epsilons)
        u = smooth_image_rof(f, lambdas(i), epsilons(j));
    end
end
t_loop = toc;

fprintf('Batch: %.2fs | Loop: %.2fs\n', t_batch, t_loop);
assert(t_batch < t_loop, 'Batch mode not faster than loop');
disp('✅ Batch speedup test passed.');
```

---

### ✅ `test/test_visual_check.m`

```matlab
f = generate_synthetic_image('checkerboard');
f = add_noise(f, 'gaussian', 0.1);
u = smooth_image_rof(f, 2.0, 0.01);
plot_rof_result(f, u);
title('Visual Test: Denoising');
disp('✅ Visual test (manual check).');
```

---

### ✅ `test/test_msd_surface_plot.m`

```matlab
f = generate_synthetic_image('gradient', [128, 128]);
lambdas = linspace(0.1, 1.0, 10);
epsilons = linspace(0.01, 0.1, 10);
msd = calculate_msd(f, lambdas, epsilons);
plot_msd_surface(msd, lambdas, epsilons);
disp('✅ MSD surface test (manual check).');
```
