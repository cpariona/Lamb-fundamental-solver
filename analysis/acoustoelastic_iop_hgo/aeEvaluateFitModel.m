function [Cp_mps, rawResult] = aeEvaluateFitModel(params, frequency_Hz, branchName, options)
%AEEVALUATEFITMODEL Evaluate AE IOP/HGO atlasA0 Cp on a fitting grid.
%
% [Cp_mps, rawResult] = aeEvaluateFitModel(params, frequency_Hz, branchName, options)
%
% This helper uses the maintained official AE/IOP/HGO atlas output:
%   result.Cp
%   result.validCp
%
% Diagnostic branch outputs are not used for fitting.

if nargin < 3 || isempty(branchName)
    branchName = "atlasA0";
end
if nargin < 4 || isempty(options)
    options = aeDefaultSweepOptions("Fast");
end

branchName = aeNormalizeBranchPolicy(branchName);
if branchName ~= "atlasA0"
    error('AE IOP/HGO fitting currently supports only official atlasA0 output.');
end

frequencyInput = frequency_Hz(:).';
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
end

params = localPrepareParams(params, frequencyInput);
options = localPrepareOptions(options);

solverResult = solveAcoustoelasticIOPHGOAtlasBranch(params, options);
Cp_mps = solverResult.Cp(:);
validMask = solverResult.validCp(:) & isfinite(Cp_mps);

rawResult = struct();
rawResult.modelFamily = "acoustoelastic_iop_hgo";
rawResult.modelName = "AcoustoelasticIOPHGO";
rawResult.branchName = branchName;
rawResult.frequency_Hz = frequencyInput(:);
rawResult.Cp_mps = Cp_mps;
rawResult.validMask = validMask;
rawResult.solverResult = solverResult;
rawResult.params = params;
rawResult.options = options;
end

function params = localPrepareParams(params, frequency_Hz)
requiredFields = {'IOP', 'R', 'thickness', 'mu', 'k1', 'k2', 'rho', 'rhoF', 'fluidBulkModulus'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing AE IOP/HGO fitting parameter: %s.', requiredFields{i});
    end
end
params.frequency = frequency_Hz(:).';
end

function options = localPrepareOptions(options)
options.atlasBranchPolicy = "atlasA0";
options = localSetIfMissing(options, 'M54_variant', "corrected");
options = localSetIfMissing(options, 'normalizeRows', false);
options = localSetIfMissing(options, 'usePhysicalCpWindow', false);
options = localSetIfMissing(options, 'invalidateAtlasFallbackOutput', true);
end

function options = localSetIfMissing(options, fieldName, value)
if ~isfield(options, fieldName) || isempty(options.(fieldName))
    options.(fieldName) = value;
end
end
