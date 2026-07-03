function sweepOutput = guiRunAcoustoelasticIOPHGOSweep(request)
%GUIRUNACOUSTOELASTICIOPHGOSWEEP Run an Acoustoelastic IOP/HGO sweep from a GUI request.
%
% This adapter is the GUI-facing layer around aeRunSweep. It is intentionally
% separate from SweepTool_GUI so the GUI does not depend on solver policy,
% tracker details, or raw Acoustoelastic IOP/HGO result layout.

params = buildAcoustoelasticBaseParams(request);
options = buildAcoustoelasticOptions(request);
[valuesSolver, displayScale, units] = convertRequestDisplayValues(request);

sweepConfig = struct();
sweepConfig.Name = char(getRequestField(request, 'outputTaskName', "ae_iop_hgo_sweep"));
sweepConfig.Label = char(getRequestField(request, 'sweepLabel', request.sweepField));
sweepConfig.Unit = char(units);
sweepConfig.ValueScale = displayScale;
sweepConfig.ValueFormatter = '%.1f';

rawResults = aeRunSweep(params, string(request.sweepField), valuesSolver, options, sweepConfig);
summary = aeSummarizeSweep(rawResults);
normalized = guiNormalizeAcoustoelasticIOPHGOSweep(rawResults, summary, request);
if isfield(options, 'executionProfileMetadata')
    normalized.metadata.executionProfile = options.executionProfileMetadata;
end

sweepOutput = struct();
sweepOutput.request = request;
sweepOutput.modelFamily = "acoustoelastic_iop_hgo";
sweepOutput.modelName = "AcoustoelasticIOPHGO";
sweepOutput.branchName = string(getRequestField(request, 'branchName', "atlasA0"));
sweepOutput.sweepSpec = struct();
sweepOutput.sweepSpec.parameter = string(request.sweepField);
sweepOutput.sweepSpec.values = valuesSolver;
sweepOutput.sweepSpec.label = string(getRequestField(request, 'sweepLabel', request.sweepField));
sweepOutput.sweepSpec.units = units;
sweepOutput.sweepSpec.displayScale = displayScale;
sweepOutput.rawResults = rawResults;
sweepOutput.summary = summary;
sweepOutput.summaryTable = summary.conditionTable;
sweepOutput.normalized = normalized;
if isfield(options, 'executionProfileMetadata')
    sweepOutput.executionProfile = options.executionProfileMetadata;
end
end

function params = buildAcoustoelasticBaseParams(request)
if isfield(request, 'baseParams') && ~isempty(request.baseParams)
    params = request.baseParams;
else
    params = struct();
end

params = fillParamDefault(params, 'R', 7.8e-3);
params = fillParamDefault(params, 'thickness', 550e-6);
params = fillParamDefault(params, 'IOP', 15 * 133.322);
params = fillParamDefault(params, 'mu', 50e3);
params = fillParamDefault(params, 'k1', 25e3);
params = fillParamDefault(params, 'k2', 100);
params = fillParamDefault(params, 'rho', 1060);
params = fillParamDefault(params, 'rhoF', 1000);
params = fillParamDefault(params, 'fluidBulkModulus', 2.2e9);

if ~isfield(params, 'frequency') || isempty(params.frequency)
    params.frequency = logspace(log10(300), log10(15e3), 35);
end
end

function options = buildAcoustoelasticOptions(request)
controls = getRequestField(request, 'controls', struct());
[options, profileMetadata] = aeResolveExecutionProfile(controls, ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "SweepTool default");

if isfield(request, 'baseOptions') && isstruct(request.baseOptions) && isfield(request.baseOptions, 'atlasBranchPolicy')
    options = guiMergeStructs(options, request.baseOptions);
end

options.M54_variant = getControlValue(controls, 'M54_variant', "corrected");
options.normalizeRows = getControlValue(controls, 'normalizeRows', false);
options.usePhysicalCpWindow = getControlValue(controls, 'usePhysicalCpWindow', false);
options.atlasBranchPolicy = getControlValue(controls, 'atlasBranchPolicy', "atlasA0");
options.atlasNumYPoints = getControlValue(controls, 'atlasNumYPoints', options.atlasNumYPoints);
options.atlasTopNMinima = getControlValue(controls, 'atlasTopNMinima', options.atlasTopNMinima);
profileMetadata.atlasNumYPoints = options.atlasNumYPoints;
profileMetadata.atlasTopNMinima = options.atlasTopNMinima;
profileMetadata.internalAtlasPreset = "ae_atlas_" + string(options.atlasNumYPoints) + "x" + string(options.atlasTopNMinima);
profileMetadata.routePolicy = string(options.atlasBranchPolicy);
profileMetadata.profileOverrideApplied = profileMetadata.requestedExecutionProfile ~= profileMetadata.effectiveExecutionProfile;
profileMetadata.profileOverrideReason = "";
requestedOptions = aeDefaultSweepOptions(profileMetadata.requestedExecutionProfile);
if options.atlasNumYPoints ~= requestedOptions.atlasNumYPoints || ...
        options.atlasTopNMinima ~= requestedOptions.atlasTopNMinima
    profileMetadata.profileOverrideApplied = true;
    profileMetadata.profileOverrideReason = "SweepTool AE controls override atlas density while preserving visible defaults.";
    if options.atlasNumYPoints == 300 && options.atlasTopNMinima == 12
        profileMetadata.effectiveExecutionProfile = "Fast";
    elseif options.atlasNumYPoints == 600 && options.atlasTopNMinima == 16
        profileMetadata.effectiveExecutionProfile = "Balanced";
    elseif options.atlasNumYPoints == 900 && options.atlasTopNMinima == 20
        profileMetadata.effectiveExecutionProfile = "Robust";
    end
end
options.executionProfileMetadata = profileMetadata;
end

function params = fillParamDefault(params, fieldName, defaultValue)
if ~isfield(params, fieldName) || isempty(params.(fieldName))
    params.(fieldName) = defaultValue;
end
end

function [valuesSolver, displayScale, units] = convertRequestDisplayValues(request)
displayScale = guiGetStructField(request, 'displayScale', 1);
units = string(guiGetStructField(request, 'displayUnit', ""));
valuesSolver = request.sweepValuesDisplay .* displayScale;
end

function value = getControlValue(controls, fieldName, defaultValue)
value = guiGetStructField(controls, fieldName, defaultValue);
end

function value = getRequestField(request, fieldName, defaultValue)
value = guiGetStructField(request, fieldName, defaultValue);
end
