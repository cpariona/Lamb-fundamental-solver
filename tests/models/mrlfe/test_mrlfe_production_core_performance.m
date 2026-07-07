clear; clc;
startup

fprintf('\nRunning mRLFE production core performance check...\n');
fprintf('-------------------------------------------------\n');

cases = [ ...
    struct('branch', "A0Like", 'etaS', 0), ...
    struct('branch', "A0Like", 'etaS', 0.05), ...
    struct('branch', "S0Like", 'etaS', 0), ...
    struct('branch', "S0Like", 'etaS', 0.05)];

for i = 1:numel(cases)
    request = localRequest(cases(i).branch, cases(i).etaS);
    mrlfeSolve(request);
    oracleSolve(request);
    newTimes = zeros(3,1);
    oldTimes = zeros(3,1);
    for k = 1:3
        t = tic;
        mrlfeSolve(request);
        newTimes(k) = toc(t);
        t = tic;
        oracleSolve(request);
        oldTimes(k) = toc(t);
    end
    newMedian = median(newTimes);
    oldMedian = median(oldTimes);
    ratio = newMedian / max(oldMedian, eps);
    fprintf('%s etaS %.3g | oracle %.4f s | new %.4f s | ratio %.3f\n', ...
        cases(i).branch, cases(i).etaS, oldMedian, newMedian, ratio);
    assert(ratio < 1.20, 'New production core performance regression exceeded 20%%.');
end

fprintf('mRLFE production core performance check passed.\n');

function oracleSolve(request)
configuration = mrlfeResolveConfiguration(request);
mrlfeEvaluateAtlasFitModel(configuration.solverParams, ...
    request.frequency_Hz, request.branch, configuration.internalOptions);
end

function request = localRequest(branch, etaS)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
if branch == "A0Like"
    request.termination = struct('policy', "physicalTail");
else
    request.termination = struct('policy', "none");
end
request.fallback = struct('policy', "none");
end
