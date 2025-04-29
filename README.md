# Image Restoration with ROF Model

> **PDE‑driven denoising · GPU‑accelerated MATLAB · Scientific visualization**

This repository showcases a full workflow for **restoring RAW sensor data** with the Rudin–Osher–Fatemi (ROF) total‑variation model.  It was developed as part of an applied‑mathematics programming assignment and doubles as a portfolio piece demonstrating high‑impact numerical skills.

---

## 🎯 Project Highlights
| Feature | Description |
|---------|-------------|
| **ROF Solver** | Finite‑difference discretisation of the anisotropic TV regulariser with Neumann BCs |
| **Vectorised Parameter Sweep** | Single call returns a 4‑D array of solutions for a full \( (\lambda,\epsilon) \) grid |
| **GPU & Multicore Support** | Automatic switch between `gpuArray` kernels and `parfor` CPU fallback |
| **Noise Analytics** | Mean‑squared difference (MSD) surface plots across R, G₁, G₂, B planes |
| **Reproducible Pipeline** | One‑click script generates results, figures, and LaTeX‑ready tables |

---

## 🛠️ Marketable Skills Demonstrated
- **Numerical PDEs & Variational Methods** – discretising Euler–Lagrange equations, stability checks
- **High‑Performance Computing** – CUDA‑enabled MATLAB + multicore parallelisation
- **Vectorised Linear Algebra** – 4‑D tensor operations, memory‑aware broadcasting
- **Scientific Visualization** – semi‑transparent 3‑D surface plots, comparative analytics
- **Git Workflow & Documentation** – modular repo, roadmap, CI‑ready scripts

> ✨ *Ideal for roles in computational imaging, numerical analysis, or data‑intensive scientific R&D.*

---

## 🚀 Quick Start
```bash
# clone & enter
git clone https://github.com/<you>/image-restoration-rof.git
cd image-restoration-rof

# launch MATLAB (or MATLAB Engine for Python) and run demo
run scripts/run_parameter_sweep.m
```
The demo automatically:
1. Reads `images/DSC00099.ARW` and extracts Bayer planes.
2. Runs the GPU‑accelerated ROF solver over a 20×20 \((\lambda,\epsilon)\) grid.
3. Saves MSD values in `results/` and a publication‑ready stacked surface plot in `plots/`.

---

## 📂 Repository Layout
```
images/        RAW input data (.ARW)
src/           MATLAB core functions
  ├── smooth_image_rof.m   # TV‑ROF solver
  ├── calculate_msd.m      # noise metric
  └── +helpers/            # gradient_ops, apply_neumann_bc, ...
scripts/       End‑to‑end demos & parameter sweeps
plots/         Generated figures
results/       Cached .mat /.csv outputs
report/        LaTeX write‑up (compiled to PDF)
ProgAssignment.pdf  Assignment brief (this repository)
ROADMAP.md     Task checklist & progress tracker
README.md      (you are here)
```
images/        RAW input data (.ARW)
src/           MATLAB core functions
  ├── smooth_image_rof.m   # TV‑ROF solver
  ├── calculate_msd.m      # noise metric
  └── +helpers/            # gradient_ops, apply_neumann_bc, ...
scripts/       End‑to‑end demos & parameter sweeps
plots/         Generated figures
results/       Cached .mat /.csv outputs
report/        LaTeX write‑up (compiled to PDF)
ROADMAP.md     Task checklist & progress tracker
README.md      (you are here)
```

---

## 🔑 Key Functions
```matlab
u = smooth_image_rof(f, lambda, epsilon)
msd = calculate_msd(f, lambda, epsilon)
```
Both are **fully vectorised**; pass vectors for `lambda` and `epsilon` to obtain a 4‑D solution family or MSD matrix ready for `meshgrid` plotting.

---

## ⚡ Performance Notes
* Batching strategy copies the 2‑D image into a 4‑D tensor on the GPU to evaluate the entire parameter grid **in one pass**.
* Falls back to `parfor` on systems without NVIDIA GPUs, guaranteeing utilisation of all CPU threads.

---

## 📜 Licence & Attribution
Assignment scaffold © 2025 **Marek Rychlik** · University of Arizona.  Solution code and documentation © 2025 **Joel A. M. Tänori**.  Released under the MIT licence.

---

## 🤝 Connect
*LinkedIn:* [joel‑tänori](https://linkedin.com/in/joel-tanori)  |  *Email:* joel@example.com

*If this project resonates with your team’s needs in computational imaging or applied mathematics, let’s talk!*

---

## 🗺️ Development Roadmap
A detailed, phase‑by‑phase checklist lives in **[Roadmap.md](Roadmap.md)**—open it to track progress or adapt the workflow to your own projects.

