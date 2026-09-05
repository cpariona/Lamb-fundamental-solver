% TEMPORARY_DIAGNOSTIC
function summary = diagnoseMrlfeRegressionSnapshotChange()
%DIAGNOSEMRLFEREGRESSIONSNAPSHOTCHANGE Measure intentional mRLFE snapshot drift.

params = rlDefaultParams();
params.mu = 158e3;
params.rho = 1070;
params.nu = 0.4999;
params.thickness = 0.50e-3;
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 18;
params.frequencySpacing = "linspace";

frequency_Hz = linspace(500, 4000, 18).';
indices = [1 9 18];

oldA0 = [2.563075741553039; 5.385531761157373; 7.013850616841720];
oldS0 = [24.282183296783170; 24.028758171168086; 23.468811073659403];

a0 = solveBranch(params, frequency_Hz, "A0Like");
s0 = solveBranch(params, frequency_Hz, "S0Like");

a0Cp = a0.debug.solverResult.branch.Cp(indices);
s0Cp = s0.debug.solverResult.branch.Cp(indices);

summary = table( ...
    [repmat("A0Like",3,1); repmat("S0Like",3,1)], ...
    [indices(:); indices(:)], ...
    [frequency_Hz(indices); frequency_Hz(indices)], ...
    [oldA0; oldS0], ...
    [a0Cp(:); s0Cp(:)], ...
    [a0Cp(:)-oldA0; s0Cp(:)-oldS0], ...
    'VariableNames', {'Branch','Index','Frequency_Hz','OldCp_mps','NewCp_mps','DeltaCp_mps'});
summary.RelativeDelta = abs(summary.DeltaCp_mps) ./ max(abs(summary.OldCp_mps), eps);

disp(summary);
fprintf('\nA0 valid: %d/%d | S0 valid: %d/%d\n', ...
    nnz(a0.validMask), numel(a0.validMask), nnz(s0.validMask), numel(s0.validMask));
fprintf('A0 quality accepted: %d | S0 quality accepted: %d\n', ...
    a0.quality.accepted, s0.quality.accepted);
fprintf('A0 max |Delta Cp|: %.12g m/s\n', max(abs(a0Cp-oldA0)));
fprintf('S0 max |Delta Cp|: %.12g m/s\n', max(abs(s0Cp-oldS0)));
end

function result = solveBranch(params, frequency_Hz, branchName)
options = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0);
request = mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
result = mrlfeSolve(request);
end
