function [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
%RLEVALUATEFITMODEL Evaluate Rayleigh-Lamb Cp on a fitting frequency grid.
%
% [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
%
% This helper evaluates the maintained Rayleigh-Lamb A0/S0 residuals directly
% on the supplied experimental frequency grid. It is intended for fitting and
% does not rely on rlBuildFrequencyVector, so one-point fitting is supported.
%
% For fitting, prediction fallback is disabled. Therefore finite tracked
% points correspond to residual minima, not predictor-only placeholders. The
% residual value is retained for diagnostics but is not used as a hard validity
% gate because an absolute residual tolerance can be overly restrictive across
% different frequency/material scales.

if nargin < 3 || isempty(branchName)
    branchName = "A0";
end
if nargin < 4 || isempty(options)
    options = rlDefaultOptions("Fast");
end

branchName = string(branchName);
frequencyInput = frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
end

rlValidateParams(params);
rlValidateOptions(options);

[frequencySorted, sortIdx] = sort(frequencyInput);
[~, unsortIdx] = sort(sortIdx);

material = rlComputeMaterial(params);
geometry = rlComputeGeometry(params);
omegaSorted = 2 * pi * frequencySorted;

geometryForSpec = geometry;
geometryForSpec.frequency0 = frequencySorted(1);
branchSpec = rlMakeBranchSpec(branchName, material, geometryForSpec);
solverOptions = localBuildSolverOptions(options, material, branchSpec);

switch branchName
    case "A0"
        residualFcn = @(Cp, f) rlAResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    case "S0"
        residualFcn = @(Cp, f) rlSResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    otherwise
        error('Unsupported Rayleigh-Lamb fitting branch: %s.', branchName);
end

[CpSorted, residualSorted] = rlSolveFundamentalBranch(frequencySorted, residualFcn, solverOptions);
kSorted = omegaSorted ./ CpSorted;

Cp_mps = CpSorted(unsortIdx);
residual = residualSorted(unsortIdx);
k = kSorted(unsortIdx);
omega = omegaSorted(unsortIdx);
validMask = isfinite(Cp_mps) & isfinite(residual) & isfinite(k);
Cp_mps(~validMask) = NaN;
k(~validMask) = NaN;

rawResult = struct();
rawResult.modelFamily = "rayleigh_lamb";
rawResult.branchName = branchName;
rawResult.frequency_Hz = frequencyInput;
rawResult.Cp_mps = Cp_mps;
rawResult.omega = omega;
rawResult.k = k;
rawResult.kThickness = k * geometry.thickness;
rawResult.residual = residual;
rawResult.validMask = validMask;
rawResult.material = material;
rawResult.geometry = rmfield(geometry, 'halfThickness');
rawResult.options = options;
rawResult.solverOptions = solverOptions;
end

function solverOptions = localBuildSolverOptions(options, material, branchSpec)
solverOptions = struct();
solverOptions.CT = material.CT;
solverOptions.gridPointsInitial = options.gridPointsInitial;
solverOptions.gridPointsTracking = options.gridPointsTracking;
solverOptions.jumpTol = options.jumpTol;
solverOptions.residualTolerance = options.residualTolerance;
solverOptions.branchName = branchSpec.name;
solverOptions.initialCpGuess = branchSpec.initialCpGuess;
solverOptions.initialSearchRange = branchSpec.initialSearchRange;
solverOptions.preferLowestCp = branchSpec.preferLowestCp;
solverOptions.disallowPredictionFallback = true;

optionalFields = {'searchFactors', 'minCpAbsolute', 'minCpRelativeToCT', ...
    'maxCpFactorCT', 'minCpGlobalMax', 'initialGuessWeight', 'predictionWeight', ...
    'maxPredictionRelativeError', 'maxSinglePointSpikeRelative', 'preferPreviousRootWeight'};
for i = 1:numel(optionalFields)
    fieldName = optionalFields{i};
    if isfield(options, fieldName)
        solverOptions.(fieldName) = options.(fieldName);
    end
end
end
