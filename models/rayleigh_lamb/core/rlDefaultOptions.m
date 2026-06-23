function options = rlDefaultOptions(robustness)
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
options.mrlfeResidualMethod = "minSingularValueRatio";
options.mrlfeSearchFactors = [0.80, 1.25; 0.60, 1.60; 0.35, 2.50];

% mRLFE branch selection. Defaults preserve the historical behavior of
% computing both fundamental-like branches unless a caller restricts them.
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = true;

% Optional mRLFE internal tracking grid. Disabled by default to preserve the
% external behavior of current workflows. When enabled, mRLFE branches are
% tracked on a denser internal grid and resampled back to the requested grid.
options.mrlfeUseInternalTrackingGrid = false;
options.mrlfeInternalTrackingPointFactor = 2;
options.mrlfeInternalTrackingMinPoints = 30;
options.mrlfeInternalTrackingMaxPoints = 400;

% Real-k mRLFE continuation and validation controls.
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFERealK = false; % compatibility alias for elastic real-k
options.computeMRLFEHanViscoRealK = false; % legacy compatibility alias
options.mrlfeRealKReferenceWeight = 0.75;
options.mrlfeRealKPredictionWeight = 0.0;
options.mrlfeRealKResidualFloor = 1e-14;
options.mrlfeRealKScoreMode = "residual"; % "residual" or "modal"
options.mrlfeRealKRequireLocalMinimum = false;
options.mrlfeRealKMaxRelativeKDrift = inf;
options.mrlfeRealKHardReferenceWindow = false;
options.mrlfeRealKValidationMaxRelativeKDrift = inf;
options.mrlfeRealKValidationMaxRelativeCpDrift = inf;
options.mrlfeRealKMaxCpJumpRelative = 0.22;
options.mrlfeRealKMaxCpPredictionError = 0.18;
options.mrlfeRealKMinPointsForPrediction = 3;
options.mrlfeRealKUseModalCpWindow = false;
options.mrlfeRealKModalCpLowerFactor = 0.35;
options.mrlfeRealKModalCpUpperFactor = 2.50;
options.mrlfeRealKStopAtFirstMissingModalMinimum = false;
options.mrlfeRealKPreviousCpWeight = 0.0;
options.mrlfeRealKPreviousKWeight = 0.0;
options.mrlfeRealKPreviousCpMaxRelativeJump = inf;

% Viscoelastic real-k modal-local tracker controls. These are enabled
% internally only for the viscoelastic real-k branch by rlComputeFundamentalLambModes.
options.mrlfeViscoUseModalLocalTracker = true;
options.mrlfeViscoA0ModalCpWindow = [0.35, 2.50];
options.mrlfeViscoS0ModalCpWindow = [0.70, 1.40];
options.mrlfeViscoPreviousCpWeight = 80.0;
options.mrlfeViscoPreviousKWeight = 0.0;
options.mrlfeViscoPreviousCpMaxRelativeJump = 0.18;

% Legacy option aliases kept temporarily for older scripts.
options.mrlfeHanUseModalLocalTracker = options.mrlfeViscoUseModalLocalTracker;
options.mrlfeHanA0ModalCpWindow = options.mrlfeViscoA0ModalCpWindow;
options.mrlfeHanS0ModalCpWindow = options.mrlfeViscoS0ModalCpWindow;
options.mrlfeHanPreviousCpWeight = options.mrlfeViscoPreviousCpWeight;
options.mrlfeHanPreviousKWeight = options.mrlfeViscoPreviousKWeight;
options.mrlfeHanPreviousCpMaxRelativeJump = options.mrlfeViscoPreviousCpMaxRelativeJump;

% Multicandidate dynamic-programming tracker for elastic A0-like mRLFE.
% This is intended to suppress branch switching in soft A0-like cases.
options.mrlfeA0UseDPTracker = false;
options.mrlfeA0DPCandidates = 8;
options.mrlfeA0DPCpScanPoints = 2200;
options.mrlfeA0DPEdgeGuardPoints = 8;
options.mrlfeA0DPCpMinFactor = 0.25;
options.mrlfeA0DPCpMaxFactor = 2.20;
options.mrlfeA0DPCpMinFloor = 0.25;
options.mrlfeA0DPCpMaxCeiling = 80;
options.mrlfeA0DPResidualWeight = 0.35;
options.mrlfeA0DPJumpWeight = 18.0;
options.mrlfeA0DPCurvatureWeight = 12.0;
options.mrlfeA0DPSeedWeight = 0.20;
options.mrlfeA0DPMaxJumpSoft = 0.30;
options.mrlfeA0DPMissingPenalty = 20.0;
options.mrlfeA0DPAllowMissing = true;

% DP-specific validation gates. They are intentionally disabled by default
% because the DP path cost already enforces modal continuity softly. Turning
% these on is useful only for diagnostics, not for routine A0-like fitting.
options.mrlfeA0DPValidationMaxRelativeKDrift = inf;
options.mrlfeA0DPValidationMaxRelativeCpDrift = inf;
options.mrlfeA0DPValidationMaxCpJumpRelative = inf;
options.mrlfeA0DPValidationMaxCpPredictionError = inf;
options.mrlfeA0DPValidationMinPointsForPrediction = 3;

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
