function [Cp_mps, rawResult] = aeEvaluateFitModel(params, frequency_Hz, branchName, options)
%AEEVALUATEFITMODEL Evaluate AE IOP/HGO atlasA0 Cp on a fitting grid.
%
% [Cp_mps, rawResult] = lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel(params, frequency_Hz, branchName, options)
%
% This helper uses the maintained official AE/IOP/HGO atlas output:
%   result.phaseVelocity_mps
%   result.validMask
%
% Diagnostic branch outputs are not used for fitting.

if nargin < 3 || isempty(branchName)
    branchName = "atlasA0";
end
if nargin < 4 || isempty(options)
    options = lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions("Fast");
else
    options.atlasBranchPolicy = "atlasA0";
    options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(options);
end

branchName = lamb.models.acoustoelastic_iop_hgo.configuration.aeNormalizeBranchPolicy(branchName);
if branchName ~= "atlasA0"
    error('AE IOP/HGO fitting currently supports only official atlasA0 output.');
end

frequencyInput = frequency_Hz(:).';
lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest(params, 'Context', "fitting", 'Frequency', frequencyInput);
params.frequency = frequencyInput;

solverResult = lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, options);
Cp_mps = solverResult.phaseVelocity_mps(:);
validMask = solverResult.validMask(:) & isfinite(Cp_mps);

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
