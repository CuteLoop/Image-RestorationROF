
f = generate_synthetic_image('gradient', [128,128]);
lambdas = linspace(0.1, 1.0, 10);
epsilons = linspace(0.01, 0.1, 10);

tic;
u_batch = smooth_image_rof(f, lambdas, epsilons);
t_batch = toc;

tic;
for i = 1:length(lambdas)
    for j = 1:length(epsilons)
        u = smooth_image_rof(f, lambdas(i), epsilons(j));
    end
end
t_loop = toc;

fprintf('Batch: %.2fs | Loop: %.2fs\n', t_batch, t_loop);
assert(t_batch < t_loop, 'Batch mode not faster');
disp('✅ Batch speedup test passed.');
