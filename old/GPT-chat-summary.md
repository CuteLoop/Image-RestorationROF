# Chat Summary: ROF Image Restoration and GPU Optimization

## Overview

This conversation involved implementing the ROF (Rudin-Osher-Fatemi) image denoising model in MATLAB,
with a focus on performance optimization using the GPU. It covered the discretization of the Euler-Lagrange PDE,
code implementation, batch evaluation over parameter grids, and GPU memory limitations.

---

## Topics Covered

### ðŸ§® Discretization of ROF PDE

The Euler-Lagrange PDE for the ROF model is:
\[
\frac{u - f}{\lambda} - \nabla \cdot \left( \frac{\nabla u}{\sqrt{\epsilon^2 + |\nabla u|^2}} \right) = 0
\]

A finite difference scheme with Neumann boundary conditions was implemented using forward differences and backward divergence.

---

### ðŸ§‘â€ðŸ’» MATLAB Implementations

- `smooth_image_rof.m`: Solves the ROF PDE for a given \(f, \lambda, \epsilon\)
- `calculate_msd.m`: Computes mean square difference between \(u\) and \(f\)
- `smooth_image_rof_batched.m`: GPU-accelerated batched version evaluating many (\lambda, \epsilon) pairs
- `TestRofFunctions.m`: Unit tests for functionality
- `demo_gpu_batched_rof.m`: Benchmarking and plotting utility

---

### ðŸ“ˆ Performance Strategy (LaTeX Write-up Provided)

We explored how to:

- Preload 4D stacks of image copies and parameters into the GPU
- Perform a full ROF sweep over 400 parameter pairs in one pass (given memory)
- Visualize results using surface plots

---

### ðŸ§  GPU Memory Limit Explanation

Despite 8 GB of GPU RAM, batching more than 12 parameter pairs for a 2000Ã—3000 image (16-bit) fails due to:

- 9+ large arrays in memory (e.g., `u`, `ux`, `uy`, `px`, `py`, `div`)
- Padding, overhead, and single-precision defaulting to 4 bytes/pixel
- Internal kernel memory usage by MATLAB
- Result: requires ~18 GB but only 8 GB is available

**Solution:**
- Chunking parameter grid
- Using `single` precision
- Resetting the GPU device (`reset(gpuDevice)`)
- Freeing memory (`clearvars`)

---

## Sharing Recommendation

This Markdown summary captures all the key content from the session. You can share this file or convert it to HTML or PDF.
