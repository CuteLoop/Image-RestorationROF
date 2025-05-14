function test_precision_safety()
    disp('Running precision safety test...');
    f = rand(64, 64);  % Defaults to double

    % Force CPU
    setappdata(0, 'rof_overrideGPU', false);

    u = smooth_image_rof(f, 1.0, 0.01);
    assert(strcmp(class(u), 'double'), '❌ Output is not double on CPU');

    msd = calculate_msd(f, 1.0, 0.01);
    assert(strcmp(class(msd), 'double'), '❌ MSD not double on CPU');

    fprintf('✅ CPU path preserves double precision.\n');
end
