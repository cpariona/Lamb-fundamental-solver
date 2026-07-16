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
    options = aeResolveConfiguration(struct(), ...
        'NumericalPreset', "Fast", 'Surface', "FitTool");
else
    options.atlasBranchPolicy = "atlasA0";
    options = aeResolveConfiguration(options, 'Surface', "FitTool");
end

branchName = aeNormalizeBranchPolicy(branchName);
if branchName ~= "atlasA0"
    error('AE IOP/HGO fitting currently supports only official atlasA0 output.');
end

frequencyInput = frequency_Hz(:).';
aeValidateRequest(params, 'Context', "fitting", 'Frequency', frequencyInput);
params.frequency = frequencyInput;

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
