# Image Restoration with ROF Model

This repository contains an implementation of the ROF (Rudin–Osher–Fatemi) image restoration model in MATLAB. The project focuses on restoring a degraded grayscale image extracted from a RAW Bayer image using PDE-based denoising techniques.

## 📌 Objectives
- Interpret and process raw image sensor data
- Implement a non-linear PDE solver for the ROF functional
- Analyze noise statistics across color channels
- Visualize and compare the effect of regularization parameters

## 📂 Repository Structure
```
image-restoration-rof/
├── images/                   # RAW input image(s)
├── scripts/                  # Analysis & visualization scripts
├── src/                      # MATLAB source code
│   ├── smooth_image_rof.m    # ROF denoising solver
│   └── calculate_msd.m       # Noise measurement tool
├── plots/                    # Generated visualizations
├── results/                  # Output statistics, analysis results
├── report/                   # Final project report (PDF)
├── README.md
└── ROADMAP.md
```

## 🚀 Getting Started
1. Clone the repository:
```bash
git clone https://github.com/your-username/image-restoration-rof.git
```
2. Open MATLAB and navigate to the project folder.
3. Place your `.ARW` image file in the `images/` directory.
4. Use `basic_script.m` as a guide to extract and visualize color planes.

## 🧠 Key Functions
### `smooth_image_rof.m`
Solves the ROF PDE for a given grayscale image `f`, with parameters `lambda`, `epsilon`. Returns the smoothed image `u`.

### `calculate_msd.m`
Computes the Mean Squared Difference (MSD) between the original and smoothed image, allowing for parameter sweeps.

## 🖼️ Visualization Goals
- 3D surface plots of MSD for each color plane (R, G, G, B)
- Comparison across planes for noise characterization
- GPU/multithreaded support for acceleration

## 📒 Report
- Explanation of the ROF model and discretization
- Implementation details
- Plot analysis and discussion
- Conclusion on noise levels per channel and implications

## 📚 References
- Rudin, Osher, Fatemi. "Nonlinear Total Variation based noise removal algorithms" (1992)
- MATLAB documentation for `gpuArray`, `parfor`, `imagesc`, `demosaic`
- Marek Rychlik's `basic_script.m`

---
© 2025 Marek Rychlik| Joel Maldonado | Assignment for Applied Mathematics course at University of Arizona

