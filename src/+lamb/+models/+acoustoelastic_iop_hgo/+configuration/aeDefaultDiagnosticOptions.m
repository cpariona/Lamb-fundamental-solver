function options = aeDefaultDiagnosticOptions(overrides)
%AEDEFAULTDIAGNOSTICOPTIONS Internal options for retained direct AE diagnostics.

options = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();

options.branch = "A0";
options.trackingDirection = "forward";
options.trackingMethod = "globalScan";
options.localContinuationWindow = 0.20;
options.localContinuationMinWidth = 0.05;
options.localContinuationFallback = "globalScan";
options.predictiveWindow = 0.18;
options.predictiveMinWidth = 0.05;
options.predictionWeight = 8.0;
options.curvatureWeight = 4.0;
options.macWeight = 12.0;
options.minAcceptableMAC = 0.00;
options.allowPredictiveFallbackNearest = true;

options.complexCInitialImagRatio = -1e-3;
options.complexCImagLimitRatio = 0.50;
options.complexCMinScale = 0.05;
options.complexCMaxIter = 250;
options.complexCMaxFunEvals = 900;
options.complexCTolX = 1e-9;
options.complexCTolFun = 1e-9;
options.complexCDisplay = "off";

options.branchSelectionMode = "band";
options.minDimensionlessFrequency = 0;
options.A0Band = [0.02, 0.75];
options.A0HighBand = [0.75, 1.20];
options.S0Band = [1.20, 3.40];
options.A0HighTarget = 0.955;
options.branchStartPreference = "auto";

options.cMin = 0.15;
options.cMax = [];
options.numCpScanPoints = 1400;
options.maxLocalCandidates = 12;
options.usePhysicalCpWindow = true;
options.A0CpWindowScale = [0.03, 1.15];
options.A0HighCpWindowScale = [0.60, 1.25];
options.S0CpWindowScale = [0.20, 1.25];
options.refineHalfWindowPoints = 2;

options.previousCpWeight = 5.0;
options.firstPointPreferenceWeight = 2.0;
options.useBranchContinuityWindow = true;
options.A0ContinuityWindow = 0.45;
options.A0HighContinuityWindow = 0.25;
options.S0ContinuityWindow = 0.18;
options.maxRelativeCpJump = inf;
options.maxObjectiveForValid = inf;

if nargin < 1 || isempty(overrides)
    return;
end
if ~isstruct(overrides) || ~isscalar(overrides)
    error('lamb.models.acoustoelastic_iop_hgo.configuration.aeDefaultDiagnosticOptions:InvalidOverrides', ...
        'Diagnostic AE option overrides must be a scalar struct.');
end
names = fieldnames(overrides);
for i = 1:numel(names)
    if ~isempty(overrides.(names{i}))
        options.(names{i}) = overrides.(names{i});
    end
end
options.atlasBranchPolicy = lamb.models.acoustoelastic_iop_hgo.configuration.aeNormalizeBranchPolicy(options.atlasBranchPolicy);
end
