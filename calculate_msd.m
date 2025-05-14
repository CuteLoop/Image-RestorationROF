function msd = calculate_msd(f, lambda, epsilon, nIter, dt)
%CALCULATE_MSD  Batch‐wise MSD over λ×ε grid, CPU/GPU dispatch
if nargin<4, nIter=10000; dt=0.25; end
useGPU = exist('rof_config','file') && rof_config() && gpuDeviceCount>0;
if useGPU
  msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt);
else
  msd = cpu_plane_sweep(f, lambda, epsilon, nIter, dt);
end
end