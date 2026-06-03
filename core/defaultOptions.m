function options = defaultOptions(robustness)
% Return default solver options for the requested robustness preset.
%
% robustness can be "Fast", "Balanced", or "Robust".

if nargin < 1 || strlength(string(robustness)) == 0
    robustness = "Balanced";
end

robustness = string(robustness);

options = struct();
options.computeA0 = true;
options.computeS0 = false;
options.robustness = robustness;
options.residualTolerance = 1e-5;
options.minCpAbsolute = 1e-4;
options.minCpRelativeToCT = 1e-3;
options.maxCpFactorCT = 20;
options.minCpGlobalMax = 1.0;
options.initialGuessWeight = 0.25;
options.predictionWeight = 0.50;

switch robustness
    case "Fast"
        options.gridPointsInitial = 1200;
        options.gridPointsTracking = 300;
        options.jumpTol = 0.45;
        options.searchFactors = [0.70, 1.35; 0.45, 1.80; 0.20, 3.00];

    case "Balanced"
        options.gridPointsInitial = 3000;
        options.gridPointsTracking = 600;
        options.jumpTol = 0.35;
        options.searchFactors = [0.75, 1.25; 0.50, 1.60; 0.30, 2.20; 0.10, 4.00];

    case "Robust"
        options.gridPointsInitial = 6000;
        options.gridPointsTracking = 1200;
        options.jumpTol = 0.55;
        options.searchFactors = [0.80, 1.20; 0.60, 1.45; 0.40, 1.90; 0.20, 3.00; 0.05, 6.00];

    otherwise
        error('Unknown robustness preset. Use Fast, Balanced, or Robust.');
end
end
