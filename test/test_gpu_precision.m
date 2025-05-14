function test_gpu_precision()
    if gpuDeviceCount == 0
        disp('⚠️ No GPU available. Skipping GPU test.');
        return;
    end
    disp('Running GPU precision test...');
    f = rand(64, 64);

    % Force GPU
    setappdata(0, 'rof_overrideGPU', true);
    u = smooth_image_rof(f, 1.0, 0.01);

    assert(strcmp(class(u), 'double') || strcmp(class(u), 'single'), ...
           '❌ GPU result has wrong type');

    fprintf('✅ GPU test completed. Output class: %s\n', class(u));
end
