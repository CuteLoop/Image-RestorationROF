# Image Restoration with ROF Model – Master Roadmap

## 📦 Deliverables
1. **Source Code**  
   - `src/smooth_image_rof.m` — vectorised ROF solver (GPU + CPU fallback)  
   - `src/calculate_msd.m` — MSD metric wrapped around the solver  
   - Any helper files (`gradient_ops.m`, `apply_neumann_bc.m`, etc.)  
2. **Automation / Demo Script**  
   - `scripts/run_parameter_sweep.m` — generates MSD data & plots for all planes  
3. **Plots & Data**  
   - `plots/msd_surfaces.png` — stacked semi‑transparent 3‑D surfaces (R, G₁, G₂, B)  
   - `results/msd_values.mat` or `.csv` — raw MSD grid for each plane  
4. **Written Report** (`report/report.pdf`)  
   - Methods, implementation details, parameter study, noise analysis, Bayer discussion  
5. **Documentation**  
   - `README.md` — quick start, objectives, usage  
   - `ROADMAP.md` (this file) — task checklist & progress tracking  
6. **Version‑controlled Repository** (GitHub) with clean commit history & tags

---

## 🗺️ Sequential To‑Do Roadmap

| Phase | Tasks | Outcome |
|-------|-------|---------|
| **0. Orientation & Setup** | • Clone repo & create folder structure<br>• Install Image Processing Toolbox (MATLAB)<br>• Skim ROF paper (Rudin–Osher–Fatemi, 1992) & assignment hand‑out<br>• Run `basic_script.m` on `images/DSC00099.ARW` | Able to load raw image & view R,G,G,B planes |
| **1. Theoretical Grounding** | • Review finite‑difference gradients & divergence in 2‑D<br>• Derive discrete ROF update with Neumann BC<br>• Decide iteration scheme (explicit gradient descent vs. Chambolle) | Hand‑written notes + reference formulas |
| **2. Core Solver Implementation** | • Write `smooth_image_rof.m` skeleton<br>• Implement vectorised `∇u`, `|∇u|`, and `div` helpers<br>• Add scalar `λ,ε` support → verify on \(64×64\) test image<br>• Extend to vectorised λ/ε producing 4‑D output | Working solver (CPU single‑thread) |
| **3. Performance Layer** | • Wrap data in `gpuArray` when `gpuDeviceCount>0`<br>• Else use `parfor` + `maxNumCompThreads(Inf)`<br>• Benchmark vs. baseline; ensure identical results | Fast GPU & multicore execution |
| **4. MSD Metric** | • Implement `calculate_msd.m` (scalar/mesh)<br>• Unit‑test against analytical case (zero noise) | Correct MSD values |
| **5. Parameter Sweep & Visualisation** | • Write `run_parameter_sweep.m`:<br>  – Define λ,ε grid (e.g., 20×20)<br>  – Call `calculate_msd` for each plane<br>  – Save `.mat` & generate stacked `surf` plot (semi‑transparent)<br>• Store outputs in `results/` & `plots/` | Publication‑ready figures |
| **6. Analysis & Interpretation** | • Compare MSD surfaces → rank colour planes by noise<br>• Explain dual green in Bayer (luminance sensitivity)<br>• Draft discussion section | Bullet‑point conclusions |
| **7. Report Writing** | • Assemble LaTeX template
• Insert methods, code snippets, figures, analysis
• Proof‑read & export `report.pdf` | Final report ready |
| **8. Final Polish & Submission** | • Ensure functions have docstrings & comments<br>• Run full parameter sweep one last time (save seeds)<br>• Tag `v1.0` release on GitHub<br>• Submit ZIP / link & report | Project delivered ✔️ |

---

### 🔖 Progress Checklist
- [ ] Orientation & Setup
- [ ] Theory derived & documented
- [ ] `smooth_image_rof.m` (CPU) complete
- [ ] Vectorised λ/ε support
- [ ] GPU / parallel branch implemented
- [ ] `calculate_msd.m` verified
- [ ] Parameter sweep script
- [ ] Plots generated
- [ ] Analysis drafted
- [ ] Report PDF finished
- [ ] Repository tagged & submitted

> **Tip:** Commit after each phase and open GitHub Issues for sub‑tasks; close them as you tick boxes above.

---

© 2025 University of Arizona • Joel Maldonado

