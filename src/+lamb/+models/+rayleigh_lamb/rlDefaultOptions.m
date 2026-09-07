function options = rlDefaultOptions(numericalPreset)
%RLDEFAULTOPTIONS Return default solver options for the requested numerical preset.
%
% numericalPreset can be "Fast", "Balanced", or "Robust".

if nargin < 1 || strlength(string(numericalPreset)) == 0
    numericalPreset = "Balanced";
end

numericalPreset = string(numericalPreset);

options = struct();
options.computeA0 = true;
options.computeS0 = false;
options.numericalPreset = numericalPreset;
options.residualTolerance = 1e-5;
options.minCpAbsolute = 1e-4;
options.minCpRelativeToCT = 1e-3;
options.maxCpFactorCT = 20;
options.minCpGlobalMax = 1.0;
options.initialGuessWeight = 0.25;
options.predictionWeight = 2.0;
options.maxPredictionRelativeError = 0.18;
options.maxSinglePointSpikeRelative = 0.25;
options.preferPreviousRootWeight = 0.50;
switch numericalPreset
    case "Fast"
        options.gridPointsInitial = 1200;
        options.gridPointsTracking = 300;
        options.jumpTol = 0.35;
        options.searchFactors = [0.80, 1.25; 0.65, 1.45; 0.45, 1.80; 0.25, 2.50];

    case "Balanced"
        options.gridPointsInitial = 3000;
        options.gridPointsTracking = 700;
        options.jumpTol = 0.25;
        options.searchFactors = [0.85, 1.18; 0.70, 1.35; 0.50, 1.65; 0.30, 2.20];

    case "Robust"
        options.gridPointsInitial = 6000;
        options.gridPointsTracking = 1400;
        options.jumpTol = 0.30;
        options.searchFactors = [0.90, 1.12; 0.75, 1.25; 0.60, 1.45; 0.40, 1.80; 0.25, 2.40];

    otherwise
        error('Unknown numerical preset. Use Fast, Balanced, or Robust.');
end
end
