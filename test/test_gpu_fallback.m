try
    gpuDevice();
    disp('✅ GPU available: GPU fallback test skipped.');
catch
    f = generate_synthetic_image('gradient');
    u = smooth_image_rof(f, 1.0, 0.01); % should fallback to CPU
    assert(~isempty(u), 'Fallback failed');
    disp('✅ GPU fallback to CPU test passed.');
end
% Test for GPU fallback in smooth_image_rof function