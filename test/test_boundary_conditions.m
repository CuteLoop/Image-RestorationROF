f = ones(64); % constant image
u = smooth_image_rof(f, 1.0, 0.01);
assert_near(u(1,:), f(1,:), 1e-6, 'Top boundary violated');
assert_near(u(end,:), f(end,:), 1e-6, 'Bottom boundary violated');
disp('✅ Boundary condition test passed.');
