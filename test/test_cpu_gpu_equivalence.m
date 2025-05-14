function test_cpu_gpu_equivalence()
% TEST_CPU_GPU_EQUIVALENCE - Compare ROF output between CPU and GPU backends

fprintf('\n=== CPU vs GPU Equivalence Test ===\n');

% Setup
f = generate_synthetic_image('gradient', [128, 128]);
lambda = 1.0;
epsilon = 0.01;

% Force CPU
setappdata(0, 'rof_overrideGPU', false);
u_cpu = smooth_image_rof(f, lambda, epsilon);

% Force GPU
setappdata(0, 'rof_overrideGPU', true);
u_gpu = smooth_image_rof(f, lambda, epsilon);

% Compute relative error
rel_err = norm(double(u_cpu(:)) - double(u_gpu(:))) / norm(double(u_cpu(:)));
fprintf('CPU vs GPU relative error: %.2e\n', rel_err);

% Create plot
figure('Name','CPU vs GPU Comparison','Visible','off');
subplot(1,3,1); imagesc(u_cpu); axis image off; title('CPU Output');
subplot(1,3,2); imagesc(u_gpu); axis image off; title('GPU Output');
subplot(1,3,3); imagesc(abs(u_cpu - u_gpu)); axis image off; title('|CPU - GPU|');
colormap gray;

% Save plot to file
plotDir = fullfile('test', 'plots');
if ~exist(plotDir, 'dir')
    mkdir(plotDir);
end
exportgraphics(gcf, fullfile(plotDir, 'cpu_gpu_diff.png'), 'Resolution', 150);
close(gcf);
fprintf('✅ CPU vs GPU comparison plot saved to test/plots/cpu_gpu_diff.png\n');

% Assertion
assert(rel_err < 1e-4, 'Mismatch between CPU and GPU output (rel error = %.2e)', rel_err);
disp('✅ CPU vs GPU equivalence test passed.');

% Clean override
rmappdata(0, 'rof_overrideGPU');
end
