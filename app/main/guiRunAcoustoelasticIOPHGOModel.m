function result = guiRunAcoustoelasticIOPHGOModel(guiRequest)
%GUIRUNACOUSTOELASTICIOPHGOMODEL Run Acoustoelastic IOP/HGO for GUI usage.
%
% result = guiRunAcoustoelasticIOPHGOModel(guiRequest) calls the canonical
% Acoustoelastic IOP/HGO API and returns a normalized
% result struct for future GUI plotting/export layers.
%
% Required guiRequest field:
%   params - struct with SI-unit fields required by solveAcoustoelasticIOPHGOBranch
%
% Optional guiRequest field:
%   options - struct overlay for defaultAcoustoelasticIOPHGOOptions()
%
if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

if ~isfield(guiRequest, 'params') || ~isstruct(guiRequest.params)
    error('guiRunAcoustoelasticIOPHGOModel:MissingParams', ...
        'guiRequest.params is required for Acoustoelastic IOP/HGO GUI runs.');
end

params = guiRequest.params;
options = guiMergeStructs(defaultAcoustoelasticIOPHGOOptions(), guiGetStructField(guiRequest, 'options', struct()));
[options, profileMetadata] = aeResolveExecutionProfile(options, ...
    'DefaultProfile', guiGetStructField(options, 'robustness', "Balanced"), ...
    'DefaultSource', "model default", ...
    'Surface', "MainGUI", ...
    'Overrides', options, ...
    'ApplyNumericalPreset', false);

elapsedTimer = tic;
modelResult = solveAcoustoelasticIOPHGOBranch(params, options);
elapsedSeconds = toc(elapsedTimer);

result = struct();
result.modelName = "AcoustoelasticIOPHGO";
result.branchName = guiGetStructField(options, 'branch', "A0");
result.frequency = modelResult.frequency_Hz;
result.phaseVelocity = modelResult.phaseVelocity_mps;
result.wavenumber = modelResult.wavenumber_radpm;
result.kThickness = computeKThickness(result.wavenumber, params);
result.branches = normalizeAcoustoelasticBranch(result, modelResult, params, options);
result.metadata = struct();
result.metadata.params = params;
result.metadata.options = options;
result.metadata.modelResult = modelResult;
result.metadata.adapter = mfilename;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.executionProfile = profileMetadata;
result.diagnostics = modelResult.diagnostics;
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.diagnostics.executionProfile = profileMetadata;
result.diagnostics.quality = modelResult.quality;
end

function branch = normalizeAcoustoelasticBranch(result, modelResult, params, options)
branch = struct();
branch.modelName = result.modelName;
branch.branchName = result.branchName;
branch.frequency = result.frequency(:);
branch.phaseVelocity = result.phaseVelocity(:);
branch.wavenumber = result.wavenumber(:);
branch.kThickness = result.kThickness(:);
branch.metadata = struct();
branch.metadata.params = params;
branch.metadata.options = options;
branch.metadata.modelResult = modelResult;
branch.metadata.units = struct('frequency', 'Hz', 'phaseVelocity', 'm/s', 'wavenumber', '1/m', 'kThickness', 'dimensionless');
branch.diagnostics = struct();
branch.diagnostics.objective = getFieldOrDefault(modelResult, 'objective', []);
branch.diagnostics.valid = modelResult.validMask;
branch.diagnostics.pointStatus = getFieldOrDefault(modelResult, 'pointStatus', strings(size(branch.phaseVelocity)));
end

function k = computeWavenumber(frequency, phaseVelocity)
frequency = frequency(:);
phaseVelocity = phaseVelocity(:);
k = nan(size(phaseVelocity));
valid = isfinite(frequency) & isfinite(phaseVelocity) & phaseVelocity ~= 0;
k(valid) = 2*pi*frequency(valid) ./ phaseVelocity(valid);
end

function kThickness = computeKThickness(k, params)
if isfield(params, 'thickness') && ~isempty(params.thickness)
    kThickness = k(:) .* params.thickness;
else
    kThickness = nan(size(k(:)));
end
end

function value = getFieldOrDefault(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
