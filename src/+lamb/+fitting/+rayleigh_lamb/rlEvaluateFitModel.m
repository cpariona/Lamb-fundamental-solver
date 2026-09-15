function [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
%RLEVALUATEFITMODEL Sample the canonical public Rayleigh-Lamb operation.
% Fitting neither establishes branch identity nor repairs missing predictions.
if nargin<3 || isempty(branchName),branchName="A0";end
if nargin<4 || isempty(options),options=lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");end
branchName=string(branchName);frequencyInput=frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput<=0)
    error('frequency_Hz must contain positive finite values.');
end
if ~any(branchName==["A0","S0"]),error('Unsupported Rayleigh-Lamb fitting branch: %s.',branchName);end
frequency=unique(frequencyInput,'sorted');
% The public operation requires two distinct ascending requests. An auxiliary
% output for a singleton does not participate in model-owned continuation.
if numel(frequency)==1,frequency=[frequency;frequency*1.05];end
params.frequencySpacing="explicit";params.frequencyVector_Hz=frequency;
params.fmin=frequency(1);params.fmax=frequency(end);
options.computeA0=branchName=="A0";options.computeS0=branchName=="S0";
result=lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(params,options);
mode=result.modes.(branchName);[~,index]=ismember(frequencyInput,frequency);
Cp_mps=mode.phaseVelocity_mps(index);
rawResult=struct('modelFamily',"rayleigh_lamb",'branchName',branchName, ...
    'frequency_Hz',frequencyInput,'Cp_mps',Cp_mps,'omega',2*pi*frequencyInput, ...
    'k',mode.wavenumber_radpm(index),'kThickness',mode.wavenumberThickness(index), ...
    'residual',mode.diagnostics.residual(index),'validMask',mode.validMask(index), ...
    'material',result.material,'geometry',result.geometry,'options',options, ...
    'trackingMode',"canonical_public_solver",'selectedBranch',branchName, ...
    'modelResult',result,'diagnostics',mode.diagnostics);
rawResult.reliability=struct('PolicyName',"canonicalPublicRL", ...
    'SelectionFallbackUsed',false,'ValidFraction',mean(rawResult.validMask), ...
    'ValidPoints',nnz(rawResult.validMask),'MissingPoints',nnz(~rawResult.validMask));
end
