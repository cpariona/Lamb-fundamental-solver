% Compare mRLFE tracker with brute-force residual/condition peaks.
% This script is diagnostic only. It does not change the solver.

startup();

branchName = "A0Like";
modelName = "mRLFEElasticRealK";
frequencyList = [1000 3000 5000 7000 9000 12000 16000];
CpMin = 0.25;
CpMax = 80;
CpScanPoints = 5000;
numPeaksToShow = 5;

params = defaultParams();
params.E = 100e3;
params.nu = 0.4999;
params.CL = 1500;
params.r