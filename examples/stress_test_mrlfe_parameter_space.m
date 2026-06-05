% Stress-test mRLFE elastic and Han viscoelastic real-k solvers.
% This script scans a compact parameter grid to identify where A0-like and
% S0-like tracking becomes unreliable at higher frequency, lower stiffness,
% or higher shear viscosity.
%
% The purpose is not fitting. It is an automated diagnostic layer for solver
% robustness and branch-switching detection.

startup();

EValues = [25e3, 50e3, 100e3, 250e3, 475e3];          % [Pa]
etaSValues = [0, 0.1, 0.3, 0.5, 0.7, 1.0];           % [Pa*s]
thicknessValues = [0.3e-3, 0.5e-3, 0.7e-3];          % [m]
fmaxValues = [8000, 16000, 30000];                   % [Hz]

baseParams = defaultParams();
baseParams.fmin = 500;
baseParams.numFrequencyPoints = 120;
baseParams.frequencySpacing = "hybrid";
baseParams.nu = 0.4999;
baseParams.rho = 1070;
baseParams.CL = 1500;

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEHanViscoRealK = true;

nCases = numel(EValues) * numel(etaSValues) * numel(thicknessValues) * numel(fmaxValues);
summary = repmat(makeEmptyRow(), nCases, 1);
caseIndex = 0;

fprintf('\nmRLFE parameter-space stress test\n');
fprintf('--------------------------------\n');
fprintf('Total cases: %d\n', nCases);

for iE = 1:numel(EValues)
    for iT = 1:numel(thicknessValues)
        for iF = 1:numel(fmaxValues)
            for iEta = 1:numel(etaSValues)
                caseIndex = caseIndex + 1;

                params = baseParams;
                params.E = EValues(iE);
                params.thickness = thicknessValues(iT);
                params.fmax = fmaxValues(iF);
                params.numFrequencyPoints = "auto";

                options = optionsBase;
                mrlfeParams = defaultMRLFEParams();
                mrlfeParams.fluidDensity = 1000;
                mrlfeParams.fluidSoundSpeed = 1500;
                mrlfeParams.etaS = etaSValues(iEta);
                mrlfeParams.etaL = 0;
                mrlfeParams.useComplexLambda = false;
                options.mrlfeParams = mrlfeParams;

                fprintf('Case %3d/%3d: E=%.3g kPa, etaS=%.3g, thickness=%.3g mm, fmax=%.0f Hz\n', ...
                    caseIndex, nCases, params.E/1e3, mrlfeParams.etaS, params.thickness*1e3, params.fmax);

                try
                    results = computeFundamentalLambModes(params, options);
                    row = makeCaseRow(params, mrlfeParams, results);
                catch ME
                    row = makeFailedRow(params, mrlfeParams, ME.message);
                    fprintf('  ERROR: %s\n', ME.message);
                end
                summary(caseIndex) = row;
            end
        end
    end
end

stressTable = struct2table(summary);
assignin('base', 'mRLFEStressTestTable', stressTable);

fprintf('\nStress-test summary\n');
fprintf('-------------------\n');
fprintf('Cases with any warning flag: %d / %d\n', sum(stressTable.HasWarning), height(stressTable));
fprintf('Worst A0 Han valid fraction: %.3g\n', min(stressTable.HanA0ValidFraction));
fprintf('Worst S0 Han valid fraction: %.3g\n', min(stressTable.HanS0ValidFraction));

warningRows = stressTable(stressTable.HasWarning, :);
if ~isempty(warningRows)
    fprintf('\nWarning cases, first 20 rows:\n');
    disp(warningRows(1:min(20,height(warningRows)), {'E_kPa','EtaS_Pa_s','Thickness_mm','Fmax_Hz','HanA0ValidFraction','HanS0ValidFraction','HanA0MaxJumpRel','HanS0MaxJumpRel','WarningText'}));
end

figure;
scatter(stressTable.E_kPa, stressTable.HanA0ValidFraction, 36, stressTable.Fmax_Hz, 'filled');
grid on;
xlabel('E [kPa]');
ylabel('Han A0-like valid fraction');
title('mRLFE Han A0-like robustness summary');
colorbar;

figure;
scatter(stressTable.E_kPa, stressTable.HanS0ValidFraction, 36, stressTable.Fmax_Hz, 'filled');
grid on;
xlabel('E [kPa]');
ylabel('Han S0-like valid fraction');
title('mRLFE Han S0-like robustness summary');
colorbar;

fprintf('\nExported mRLFEStressTestTable to workspace.\n');

function row = makeCaseRow(params, mrlfeParams, results)
row = makeEmptyRow();
row.E_kPa = params.E / 1e3;
row.EtaS_Pa_s = mrlfeParams.etaS;
row.Thickness_mm = params.thickness * 1e3;
row.Fmax_Hz = params.fmax;
row.ErrorMessage = "";

if isfield(results.models, 'mRLFEElasticRealK')
    row = appendBranchMetrics(row, results.models.mRLFEElasticRealK, 'ElasticA0', 'A0Like');
    row = appendBranchMetrics(row, results.models.mRLFEElasticRealK, 'ElasticS0', 'S0Like');
end
if isfield(results.models, 'mRLFEHanViscoRealK')
    row = appendBranchMetrics(row, results.models.mRLFEHanViscoRealK, 'HanA0', 'A0Like');
    row = appendBranchMetrics(row, results.models.mRLFEHanViscoRealK, 'HanS0', 'S0Like');
end

warnings = strings(0,1);
if row.HanA0ValidFraction < 0.98
    warnings(end+1) = "HanA0 valid fraction < 0.98"; %#ok<AGROW>
end
if row.HanS0ValidFraction < 0.98
    warnings(end+1) = "HanS0 valid fraction < 0.98"; %#ok<AGROW>
end
if row.HanA0MaxJumpRel > 0.20
    warnings(end+1) = "HanA0 jump > 20%"; %#ok<AGROW>
end
if row.HanS0MaxJumpRel > 0.20
    warnings(end+1) = "HanS0 jump > 20%"; %#ok<AGROW>
end
if row.HanA0MaxResidual > 1e-3
    warnings(end+1) = "HanA0 residual > 1e-3"; %#ok<AGROW>
end
if row.HanS0MaxResidual > 1e-3
    warnings(end+1) = "HanS0 residual > 1e-3"; %#ok<AGROW>
end
row.HasWarning = ~isempty(warnings);
row.WarningText = strjoin(warnings, '; ');
end

function row = makeFailedRow(params, mrlfeParams, message)
row = makeEmptyRow();
row.E_kPa = params.E / 1e3;
row.EtaS_Pa_s = mrlfeParams.etaS;
row.Thickness_mm = params.thickness * 1e3;
row.Fmax_Hz = params.fmax;
row.HasWarning = true;
row.WarningText = "solver error";
row.ErrorMessage = string(message);
end

function row = appendBranchMetrics(row, model, prefix, branchName)
if ~isfield(model.branches, branchName)
    row.(prefix + "ValidFraction") = 0;
    row.(prefix + "MaxResidual") = nan;
    row.(prefix + "MinCp") = nan;
    row.(prefix + "MaxCp") = nan;
    row.(prefix + "MaxJumpRel") = inf;
    return;
end
branch = model.branches.(branchName);
valid = getValidCp(branch);
row.(prefix + "ValidFraction") = sum(valid) / numel(valid);
if any(isfinite(branch.residual))
    row.(prefix + "MaxResidual") = max(branch.residual(isfinite(branch.residual)));
else
    row.(prefix + "MaxResidual") = nan;
end
if any(valid)
    cp = branch.Cp(valid);
    row.(prefix + "MinCp") = min(cp);
    row.(prefix + "MaxCp") = max(cp);
    row.(prefix + "MaxJumpRel") = maxRelativeJump(cp);
else
    row.(prefix + "MinCp") = nan;
    row.(prefix + "MaxCp") = nan;
    row.(prefix + "MaxJumpRel") = inf;
end
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid & isfinite(branch.Cp);
end

function value = maxRelativeJump(x)
if numel(x) < 2
    value = 0;
    return;
end
value = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end

function row = makeEmptyRow()
row = struct();
row.E_kPa = nan;
row.EtaS_Pa_s = nan;
row.Thickness_mm = nan;
row.Fmax_Hz = nan;
row.ElasticA0ValidFraction = nan;
row.ElasticA0MaxResidual = nan;
row.ElasticA0MinCp = nan;
row.ElasticA0MaxCp = nan;
row.ElasticA0MaxJumpRel = nan;
row.ElasticS0ValidFraction = nan;
row.ElasticS0MaxResidual = nan;
row.ElasticS0MinCp = nan;
row.ElasticS0MaxCp = nan;
row.ElasticS0MaxJumpRel = nan;
row.HanA0ValidFraction = nan;
row.HanA0MaxResidual = nan;
row.HanA0MinCp = nan;
row.HanA0MaxCp = nan;
row.HanA0MaxJumpRel = nan;
row.HanS0ValidFraction = nan;
row.HanS0MaxResidual = nan;
row.HanS0MinCp = nan;
row.HanS0MaxCp = nan;
row.HanS0MaxJumpRel = nan;
row.HasWarning = false;
row.WarningText = "";
row.ErrorMessage = "";
end
