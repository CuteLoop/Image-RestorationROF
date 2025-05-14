function msd = calculate_msd(f, lambda, epsilon, nIter, dt)
%CALCULATE_MSD  Convenience wrapper: chooses CPU or GPU automatically.

if nargin<4, nIter=300; end
if nargin<5, dt=0.25;  end

if gpuDeviceCount>0
    msd = gpu_plane_sweep(f, lambda, epsilon, nIter, dt);
else
    msd = cpu_plane_sweep(f, lambda, epsilon, nIter, dt);
end
end
