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
options.computeMRLFE = false;
options.robustness = robustness;
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
options.mrlfeResidualTolerance = 1e-4;
options.mrlfeSearchFactors = [0.80, 1.25; 0.60, 1.60; 0.35, 2.50];

% Complex-k continuation and validation controls.
options.mrlfeComplexMaxIter = 120;
options.mrlfeComplexMaxFunEvals = 260;
options.mrlfeComplexTolX = 1e-7;
options.mrlfeComplexTolFun = 1e-9;
options.mrlfeComplexResidualScale = 1e-8;
options.mrlfeComplexResidualWeight = 1.0;
options.mrlfeComplexPredictionWeight = 2.0;
options.mrlfeComplexReferenceWeight = 12.0;
options.mrlfeComplexReferenceCpWeight = 8.0;
options.mrlfeComplexImagContinuityWeight = 4.0;
options.mrlfeComplexLossPenaltyWeight = 100.0;
options.mrlfeComplexMaxRelativeKDrift = 0.25;
options.mrlfeComplexMaxRelativeCpDrift = 0.30;
options.mrlfeComplexMaxLossFactor = 1e-2;
options.mrlfeComplexImagScaleFraction = 1e-7;
options.mrlfeComplexCpResidualTolerance = 1e-4;
options.mrlfeComplexAttenuationResidualTolerance = 1e-5;
options.mrlfeComplexMaxAttenuationJumpRelative = 5.0;
options.mrlfeComplexMaxAttenuationJumpLossFactor = 5e-3;

switch robustness
    case "Fast"
        options.gridPointsInitial = 1200;
        options.gridPointsTracking = 300;
        options.jumpTol = 0.35;
        options.searchFactors = [0.80, 1.25; 0.65, 1.45; 0.45, 1.80; 0.25, 2.50];
        options.mrlfeGridPoints = 220;
        options.mrlfeComplexMaxIter = 70;
        options.mrlfeComplexMaxFunEvals = 150;

    case "Balanced"
        options.gridPointsInitial = 3000;
        options.gridPointsTracking = 700;
        options.jumpTol = 0.25;
        options.searchFactors = [0.85, 1.18; 0.70, 1.35; 0.50, 1.65; 0.30, 2.20];
        options.mrlfeGridPoints = 450;

    case "Robust"
        options.gridPointsInitial = 6000;
        options.gridPointsTracking = 1400;
        options.jumpTol = 0.30;
        options.searchFactors = [0.90, 1.12; 0.75, 1.25; 0.60, 1.45; 0.40, 1.80; 0.25, 2.40];
        options.mrlfeGridPoints = 800;
        options.mrlfeComplexMaxIter = 180;
        options.mrlfeComplexMaxFunEvals = 420;

    otherwise
        error('Unknown robustness preset. Use Fast, Balanced, or Robust.');
end
end
