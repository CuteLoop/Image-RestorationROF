clear; clc; format compact
delete(gcp('nocreate'));

raw_img = './images/DSC00099.ARW';
fprintf('Reading %s …\n',raw_img);
cfa = rawread(raw_img);  Iplanar = raw2planar(cfa);

lambda  = logspace(-3,0,20);
epsilon = logspace(-4,-1,20);
nIter=300; dt=0.25;

colourName=["R","G1","G2","B"];
msdCube = zeros(numel(lambda),numel(epsilon),4,'single');

parfor p = 1:4
    msdCube(:,:,p) = calculate_msd(Iplanar(:,:,p),lambda,epsilon,nIter,dt);
end

save rof_results_singlepool.mat lambda epsilon msdCube
disp('🏁  Done – results saved');
