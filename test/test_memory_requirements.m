function test_memory_requirements()
    disp('=== Running memory requirement test for ROF ===');

    H = 2000; W = 3000; K = 20; L = 20;
    bytesPerElement = 8;  % double
    totalBytes = H * W * K * L * bytesPerElement;
    totalGB = totalBytes / 2^30;

    fprintf('Image size:        %d x %d\n', H, W);
    fprintf('Grid size:         %d x %d\n', K, L);
    fprintf('Precision:         double (%d bytes)\n', bytesPerElement);
    fprintf('Total memory need: %.2f GB\n', totalGB);

    try
        m = memory;
        availableGB = m.MemAvailableAllArrays / 2^30;
        fprintf('Available RAM:     %.2f GB\n', availableGB);

        if totalGB > availableGB
            warning('❌ Insufficient RAM for full batch. Reduce block size.');
        else
            disp('✅ Enough RAM for this configuration.');
        end
    catch
        disp('ℹ️ Skipped system memory check (non-Windows system).');
    end
end
