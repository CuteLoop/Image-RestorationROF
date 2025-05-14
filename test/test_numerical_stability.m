
f = generate_synthetic_image('gradient');
u = smooth_image_rof(f, 1.0, 1e-8);
assert(all(isfinite(u(:))), 'Stability test failed (NaNs/Infs)');
disp('✅ Numerical stability test passed.');
