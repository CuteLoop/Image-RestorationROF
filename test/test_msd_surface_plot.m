clc; disp('=== MSD Surface Test ===');
f = generate_synthetic_image('gradient', [128, 128]);
lambdas = linspace(0.1, 1.0, 10);
epsilons = linspace(0.01, 0.1, 10);
msd = calculate_msd(f, lambdas, epsilons);
plot_msd_surface(msd, lambdas, epsilons);