f = generate_synthetic_image('gradient', [128, 128]);

setappdata(0, 'rof_overrideGPU', false);  % force CPU
u_cpu = smooth_image_rof(single(f), 1, 0.01);

setappdata(0, 'rof_overrideGPU', true);   % force GPU
u_gpu = smooth_image_rof(single(f), 1, 0.01);

% Compute relative difference
diff = norm(double(u_cpu(:)) - double(u_gpu(:))) / norm(double(u_cpu(:)));
fprintf('CPU vs GPU relative error: %.2e\n', diff);

assert(diff < 1e-4, 'Mismatch between CPU and GPU output');
disp('✅ CPU vs GPU consistency test passed.');
