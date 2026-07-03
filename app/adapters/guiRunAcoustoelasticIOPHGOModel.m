function result = guiRunAcoustoelasticIOPHGOModel(guiRequest)
%GUIRUNACOUSTOELASTICIOPHGOMODEL Run Acoustoelastic IOP/HGO for GUI usage.
%
% result = guiRunAcoustoelasticIOPHGOModel(guiRequest) calls the existing
% long author-neutral Acoustoelastic IOP/HGO API and returns a normalized
% result struct for future GUI plotting/export layers.
%
% Required guiRequest field:
%   params - struct with SI-unit fields required by solveAcoustoelasticIOPHGOBranch
%
% Optional guiRequest field:
%   options - struct overlay for defaultAcoustoelasticIOPHGOOptions()
%
% This adapter intentionally does not introduce ae* aliases. Short ae* names
% may be added later in a dedicated tested/documented PR.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

if ~isfield(guiRequest, 'params') || ~isstruct(guiRequest.params)
    error('guiRunAcoustoelasticIOPHGOModel:MissingParams', ...
        'guiRequest.params is required for Acoustoelastic IOP/HGO GUI runs.');
end

params = guiRequest.params;
options = guiMergeStructs(defaultAcoustoelasticIOPHGOOptions(), guiGetStructField(guiRequest, 'options', struct()));
[profile, profileMetadata] = guiNormalizeExecutionProfile(options, ...
    'DefaultProfile', guiGetStructField(options, 'robustness', "Balanced"), ...
    'DefaultSource', "model default");
options.executionProfile = profile;
options.robustness = profile;
options = applyGuiFastAEPreset(options);

elapsedTimer = tic;
rawResult = solveAcoustoelasticIOPHGOBranch(params, options);
elapsedSeconds = toc(elapsedTimer);

result = struct();
result.modelName = "AcoustoelasticIOPHGO";
result.branchName = guiGetStructField(options, 'branch', "A0");
result.frequency = getFieldOrDefault(rawResult, 'frequency', []);
result.phaseVelocity = getFieldOrDefault(rawResult, 'Cp', []);
result.wavenumber = computeWavenumber(result.frequency, result.phaseVelocity);
result.kThickness = computeKThickness(result.wavenumber, params);
result.branches = normalizeAcoustoelasticBranch(result, rawResult, params, options);
result.metadata = struct();
result.metadata.params = params;
result.metadata.options = options;
result.metadata.rawResult = rawResult;
result.metadata.adapter = mfilename;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.aeGuiAtlasPreset = guiGetStructField(options, 'aeGuiAtlasPreset', "none");
profileMetadata.internalSolverPreset = "";
profileMetadata.internalAtlasPreset = "ae_atlas_" + string(guiGetStructField(options, 'atlasNumYPoints', NaN)) + ...
    "x" + string(guiGetStructField(options, 'atlasTopNMinima', NaN));
profileMetadata.aeGuiInteractivePreset = guiGetStructField(options, 'aeGuiAtlasPreset', "none");
profileMetadata.profileOverrideApplied = false;
profileMetadata.profileOverrideReason = "";
profileMetadata.routePolicy = string(guiGetStructField(options, 'atlasBranchPolicy', "atlasA0"));
profileMetadata.optimizerProfile = "";
profileMetadata.atlasNumYPoints = guiGetStructField(options, 'atlasNumYPoints', NaN);
profileMetadata.atlasTopNMinima = guiGetStructField(options, 'atlasTopNMinima', NaN);
profileMetadata.supportedExecutionProfiles = ["Fast", "Balanced", "Robust"];
profileMetadata.profileSupportMode = "fully_supported";
profileMetadata.surfaceDefaultExecutionProfile = "Balanced";
result.metadata.executionProfile = profileMetadata;
result.diagnostics = getFieldOrDefault(rawResult, 'diagnostics', struct());
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.diagnostics.aeGuiAtlasPreset = guiGetStructField(options, 'aeGuiAtlasPreset', "none");
result.diagnostics.executionProfile = profileMetadata;
if isfield(rawResult, 'reliability')
    result.diagnostics.reliability = rawResult.reliability;
end
end

function options = applyGuiFastAEPreset(options)
usePreset = logical(guiGetStructField(options, 'aeUseGuiFastAtlasPreset', true));
if ~usePreset
    options.aeGuiAtlasPreset = "off";
    return;
end
options.aeGuiAtlasPreset = "fast";
options.numCpScanPoints = guiGetStructField(options, 'numCpScanPoints', 420);
options.maxLocalCandidates = guiGetStructField(options, 'maxLocalCandidates', 8);
options.refineLocalMinima = guiGetStructField(options, 'refineLocalMinima', false);
options.atlasInitializationNumFrequencyPoints = guiGetStructField(options, 'atlasInitializationNumFrequencyPoints', 25);
options.trackingMethod = guiGetStructField(options, 'trackingMethod', "predictiveContinuation");
options.localContinuationFallback = guiGetStructField(options, 'localContinuationFallback', "globalScan");
options.predictiveWindow = guiGetStructField(options, 'predictiveWindow', 0.22);
options.predictionWeight = guiGetStructField(options, 'predictionWeight', 8.0);
options.curvatureWeight = guiGetStructField(options, 'curvatureWeight', 4.0);
end

function branch = normalizeAcoustoelasticBranch(result, rawResult, params, options)
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
branch.metadata.rawBranch = rawResult;
branch.metadata.units = struct('frequency', 'Hz', 'phaseVelocity', 'm/s', 'wavenumber', '1/m', 'kThickness', 'dimensionless');
branch.diagnostics = struct();
branch.diagnostics.objective = getFieldOrDefault(rawResult, 'objective', []);
branch.diagnostics.valid = getFieldOrDefault(rawResult, 'validCp', isfinite(branch.phaseVelocity));
branch.diagnostics.pointStatus = getFieldOrDefault(rawResult, 'pointStatus', strings(size(branch.phaseVelocity)));
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
