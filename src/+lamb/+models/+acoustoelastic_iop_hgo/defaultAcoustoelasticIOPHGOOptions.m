function options = defaultAcoustoelasticIOPHGOOptions(varargin)
%DEFAULTACOUSTOELASTICIOPHGOOPTIONS Public production options for AE IOP/HGO.
%
% These options belong to the maintained IOP/HGO -> atlasA0 route. Direct
% real-Cp and complex-C diagnostic controls are owned separately by
% lamb.models.acoustoelastic_iop_hgo.configuration.aeDefaultDiagnosticOptions.

options = struct();
options.M54_variant = "corrected";
options.normalizeRows = true;

options.atlasBranchPolicy = "atlasA0";
options.invalidateAtlasFallbackOutput = true;

options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 300;
options.atlasInitializationNumFrequencyPoints = 50;

options.atlasYMin = 0.003;
options.atlasYMax = 2.0;
options.atlasNumYPoints = 1000;
options.atlasTopNMinima = 18;
options.atlasMaxLogYJump = 0.075;
options.atlasMinBranchPoints = 12;
options.atlasSplitOnLargeCpJump = true;
options.atlasMaxRelativeCpJump = 0.05;

options.atlasCoverageWeight = 1.40;
options.atlasRoughnessWeight = 1.20;
options.atlasRankWeight = 0.70;
options.atlasLowYWeight = 0.35;
options.atlasIncreaseWeight = 0.50;
options.atlasDropWeight = 1.25;
options.atlasStartYWeight = 1.10;
options.atlasStartRankWeight = 0.55;
options.atlasStartCpWeight = 0.65;
options.atlasPreferPositiveSlope = true;
options.atlasRequireLowStartY = true;
options.atlasMaxStartY = 0.50;
options.atlasRequireStartRank = true;
options.atlasMaxStartRank = 3;
options.atlasFallbackToUnfilteredSelection = true;

options.atlasAllowInterpolationAcrossGaps = false;
options.atlasMaxInterpolationFrequencyRatio = 1.12;

% Refinement remains downstream of discrete atlas selection.
options.refineLocalMinima = true;
options.selectedBranchRefinementTolLogCp = 1e-6;
options.selectedBranchRefinementMaxFunEvals = 24;
options.selectedBranchRefinementMaxIter = 24;

if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    options.(char(varargin{i})) = varargin{i+1};
end
options.atlasBranchPolicy = lamb.models.acoustoelastic_iop_hgo.configuration.aeNormalizeBranchPolicy(options.atlasBranchPolicy);
end
