% Diagnose validity breakdown for viscoelastic real-k mRLFE.
%
% Purpose:
%   Separate why viscoelastic branches stop being marked valid:
%     - residual gate
%     - reference gate
%     - smoothness gate
%     - finite Cp availability
%   This helps distinguish branch-switching from a residual/validity-threshold
%   limitation at high viscosity or low stiffness.
%
% Model:
%   mRLFERealK, with etaS = 0 as the elastic limit and etaS > 0 as the
%   viscoelastic real-k case.
%
% Output file:
%   mRLFE_visco_validity_breakdown.csv

startup();

EValues = [50e3, 100e3, 300e3, 500e3, 1000e3, 1500e3]; % [Pa], converted to mu through ShearPoisson
etaSValues = [0, 0.01, 0.05, 0.1, 0.3, 0.5, 0.7, 1.0]; % [Pa*s]

paramsBase = rlDefaultParams();
paramsBase.fmin = 500;
paramsBase.fmax = 16000;
paramsBase.numFrequencyPoints = 160;
paramsBase.frequencySpacing = "hybrid";
paramsBase.thickness = 0.5e-3;
paramsBase.nu = 0.4999;

optionsBase = rlDefaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEComplexK = false;

rows = [];
resultsByCase = cell(numel(EValues), numel(etaSValues));

fprintf('\nmRLFE viscoelastic validity breakdown diagnostic\n');
fprintf('------------------------------------------------\n');
fprintf('Frequency range: %.0f to %.0f Hz, N = %d\n', ...
    paramsBase.fmin, paramsBase.fmax, paramsBase.numFrequencyPoints);
fprintf('E-equivalent values: %.3g to %.3g kPa (%d cases)\n', ...
    min(EValues)/1e3, max(EValues)/1e3, numel(EValues));
fprintf('etaS values: %.3g to %.3g Pa*s (%d cases)\n', ...
    min(etaSValues), max(etaSValues), numel(etaSValues));

for iE = 1:numel(EValues)
    params = setYoungModulusForShearPoisson(paramsBase, EValues(iE));
    material = rlComputeMaterial(params);
    fprintf('\nE = %.6g kPa, mu = %.6g kPa, CT = %.6g m/s\n', ...
        material.E/1e3, material.mu/1e3, material.CT);

    for iEta = 1:numel(etaSValues)
        etaS = etaSValues(iEta);
        options = optionsBase;
        options.computeMRLFEViscoRealK = etaS > 0;
        options.mrlfeParams = struct('etaS', etaS, 'etaL', 0, 'useComplexLambda', false);
        fprintf('  etaS = %.6g Pa*s\n', etaS);
        try
            results = rlComputeFundamentalLambModes(params, options);
            resultsByCase{iE,iEta} = results;
            branches = selectRealKBranches(results, etaS);
            rows = [rows; makeBreakdownRow(branches, 'A0Like', params, material, etaS)]; %#ok<AGROW>
            rows = [rows; makeBreakdownRow(branches, 'S0Like', params, material, etaS)]; %#ok<AGROW>
        catch ME
            rows = [rows; makeFailedRow('A0Like', params, material, etaS, ME.message)]; %#ok<AGROW>
            rows = [rows; makeFailedRow('S0Like', params, material, etaS, ME.message)]; %#ok<AGROW>
            fprintf('    ERROR: %s\n', ME.message);
        end
    end
end

mRLFEViscoValidityBreakdown = rowsToTable(rows);
writetable(mRLFEViscoValidityBreakdown, 'mRLFE_visco_validity_breakdown.csv');
assignin('base', 'mRLFEViscoValidityBreakdown', mRLFEViscoValidityBreakdown);
assignin('base', 'mRLFEViscoValidityBreakdownResults', resultsByCase);

fprintf('\nmRLFE viscoelastic validity breakdown\n');
fprintf('------------------------------------\n');
if ~isempty(mRLFEViscoValidityBreakdown)
    disp(mRLFEViscoValidityBreakdown(:, {'Branch','E_kPa','Mu_kPa','EtaS_Pa_s','FiniteCpPoints','ValidCpPoints','ValidResidualPoints','ValidReferencePoints','ValidSmoothPoints','FirstInvalidReason','FirstInvalidFrequency_Hz','MaxResidual','ResidualTolerance'}));
end
fprintf('\nWrote mRLFE_visco_validity_breakdown.csv\n');

function params = setYoungModulusForShearPoisson(params, youngModulus)
params.E = youngModulus;
params.mu = youngModulus / (2 * (1 + params.nu));
end

function branches = selectRealKBranches(results, etaS)
if etaS > 0 && isfield(results.models, 'mRLFEViscoRealK')
    branches = results.models.mRLFEViscoRealK.branches;
elseif isfield(results.models, 'mRLFERealK')
    branches = results.models.mRLFERealK.branches;
elseif isfield(results.models, 'mRLFEElasticRealK')
    branches = results.models.mRLFEElasticRealK.branches;
else
    error('No mRLFE real-k branches were found in results.models.');
end
end

function row = makeBreakdownRow(branches, branchName, params, material, etaS)
row = makeEmptyRow(branchName, params, material, etaS);
if ~isfield(branches, branchName)
    row.FirstInvalidReason = "branch not available";
    row.ErrorMessage = "branch not available";
    fprintf('    %s: not available\n', branchName);
    return;
end

branch = branches.(branchName);
Cp = branch.Cp(:);
frequency = branch.frequency(:);
residual = branch.residual(:);
finiteCp = isfinite(Cp);

validCp = getFieldMask(branch, 'validCp', 'valid', finiteCp);
validResidual = getFieldMask(branch, 'validResidual', '', validCp);
validReference = getFieldMask(branch, 'validReference', '', validCp);
validSmooth = getFieldMask(branch, 'validSmooth', '', validCp);

row.TotalPoints = numel(Cp);
row.FiniteCpPoints = sum(finiteCp);
row.ValidCpPoints = sum(validCp);
row.ValidResidualPoints = sum(validResidual);
row.ValidReferencePoints = sum(validReference);
row.ValidSmoothPoints = sum(validSmooth);
row.InvalidCpPoints = row.TotalPoints - row.ValidCpPoints;
row.InvalidResidualPoints = sum(finiteCp & ~validResidual);
row.InvalidReferencePoints = sum(finiteCp & ~validReference);
row.InvalidSmoothPoints = sum(finiteCp & ~validSmooth);

if any(finiteCp)
    row.FiniteFmax_Hz = max(frequency(finiteCp));
    row.FiniteFmin_Hz = min(frequency(finiteCp));
end
if any(validCp)
    row.ValidFmax_Hz = max(frequency(validCp));
    row.ValidFmin_Hz = min(frequency(validCp));
    row.MinCp = min(Cp(validCp));
    row.MaxCp = max(Cp(validCp));
end
if any(isfinite(residual))
    row.MaxResidual = max(residual(isfinite(residual)));
    residualMask = finiteCp & isfinite(residual);
    if any(residualMask)
        row.MaxResidualFiniteCp = max(residual(residualMask));
    end
end

row.ResidualTolerance = inferResidualTolerance(branch);
[row.FirstInvalidReason, row.FirstInvalidFrequency_Hz] = firstInvalidReason(frequency, finiteCp, validCp, validResidual, validReference, validSmooth);

fprintf('    %s: validCp %d/%d, residual %d, reference %d, smooth %d, first invalid: %s at %.6g Hz\n', ...
    branchName, row.ValidCpPoints, row.TotalPoints, row.ValidResidualPoints, row.ValidReferencePoints, row.ValidSmoothPoints, row.FirstInvalidReason, row.FirstInvalidFrequency_Hz);
end

function row = makeFailedRow(branchName, params, material, etaS, message)
row = makeEmptyRow(branchName, params, material, etaS);
row.FirstInvalidReason = "solver error";
row.ErrorMessage = string(message);
end

function row = makeEmptyRow(branchName, params, material, etaS)
row = struct();
row.Branch = string(branchName);
row.E_kPa = material.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.EtaS_Pa_s = etaS;
row.TotalPoints = 0;
row.FiniteCpPoints = 0;
row.ValidCpPoints = 0;
row.ValidResidualPoints = 0;
row.ValidReferencePoints = 0;
row.ValidSmoothPoints = 0;
row.InvalidCpPoints = 0;
row.InvalidResidualPoints = 0;
row.InvalidReferencePoints = 0;
row.InvalidSmoothPoints = 0;
row.FiniteFmin_Hz = nan;
row.FiniteFmax_Hz = nan;
row.ValidFmin_Hz = nan;
row.ValidFmax_Hz = nan;
row.FirstInvalidFrequency_Hz = nan;
row.FirstInvalidReason = "";
row.MinCp = nan;
row.MaxCp = nan;
row.MaxResidual = nan;
row.MaxResidualFiniteCp = nan;
row.ResidualTolerance = nan;
row.ErrorMessage = "";
end

function mask = getFieldMask(branch, preferredField, fallbackField, defaultMask)
if isfield(branch, preferredField)
    mask = branch.(preferredField)(:);
elseif ~isempty(fallbackField) && isfield(branch, fallbackField)
    mask = branch.(fallbackField)(:);
else
    mask = defaultMask(:);
end
mask = logical(mask) & isfinite(branch.Cp(:));
end

function tol = inferResidualTolerance(branch)
tol = nan;
if isfield(branch, 'dpOptions') && isfield(branch.dpOptions, 'residualTolerance')
    tol = branch.dpOptions.residualTolerance;
end
end

function [reason, fInvalid] = firstInvalidReason(frequency, finiteCp, validCp, validResidual, validReference, validSmooth)
idx = find(~validCp(:), 1, 'first');
if isempty(idx)
    reason = "none";
    fInvalid = nan;
    return;
end
fInvalid = frequency(idx);
if ~finiteCp(idx)
    reason = "non-finite Cp";
elseif ~validResidual(idx)
    reason = "residual gate";
elseif ~validReference(idx)
    reason = "reference gate";
elseif ~validSmooth(idx)
    reason = "smoothness gate";
else
    reason = "combined/unknown gate";
end
end

function T = rowsToTable(rows)
if isempty(rows)
    T = table();
else
    T = struct2table(rows);
end
end
