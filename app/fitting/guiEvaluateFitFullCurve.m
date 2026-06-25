function fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%GUIEVALUATEFITFULLCURVE Evaluate fitted model on a wider plotting grid.
%
% fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%
% This helper is intended for visual QC. It evaluates the fitted model beyond
% the exact experimental frequencies when the underlying solver supports it.

if nargin < 2 || isempty(nPoints)
    nPoints = 80;
end

frequencyData = fitResult.frequency_Hz(:);
frequencyData = frequencyData(isfinite(frequencyData) & frequencyData > 0);
if isempty(frequencyData)
    fullCurve = emptyCurve();
    return;
end

modelFamily = string(fitResult.modelFamily);
branchName = string(fitResult.branchName);
params = fitResult.allParams;

fmin = max(1, 0.5 * min(frequencyData));
fmax = max(frequencyData) * 1.5;
if fmax <= fmin
    fmax = fmin * 1.05;
end

switch modelFamily
    case "rayleigh_lamb"
        frequencyFull_Hz = linspace(fmin, fmax, max(nPoints, 20)).';
        options = fitResult.problem.solverOptions;
        [CpFull_mps, raw] = rlEvaluateFitModel(params, frequencyFull_Hz, branchName, options);
        validMask = raw.validMask(:) & isfinite(CpFull_mps(:));
    case "mrlfe"
        frequencyFull_Hz = linspace(fmin, fmax, max(nPoints, 20)).';
        options = fitResult.problem.solverOptions;
        [CpFull_mps, raw] = mrlfeEvaluateFitModel(params, frequencyFull_Hz, branchName, options);
        validMask = raw.validMask(:) & isfinite(CpFull_mps(:));
    case "acoustoelastic_iop_hgo"
        % AE atlas tracking is more expensive and may be less stable outside the
        % validated band, so use a conservative grid spanning the same expanded
        % range with fewer points.
        frequencyFull_Hz = logspace(log10(fmin), log10(fmax), max(35, min(nPoints, 45))).';
        options = fitResult.problem.solverOptions;
        [CpFull_mps, raw] = aeEvaluateFitModel(params, frequencyFull_Hz, "atlasA0", options);
        validMask = raw.validMask(:) & isfinite(CpFull_mps(:));
    otherwise
        fullCurve = emptyCurve();
        return;
end

fullCurve = struct();
fullCurve.modelFamily = modelFamily;
fullCurve.branchName = branchName;
fullCurve.frequency_Hz = frequencyFull_Hz(:);
fullCurve.Cp_mps = CpFull_mps(:);
fullCurve.validMask = validMask(:);
fullCurve.rawResult = raw;
end

function curve = emptyCurve()
curve = struct();
curve.modelFamily = "";
curve.branchName = "";
curve.frequency_Hz = [];
curve.Cp_mps = [];
curve.validMask = [];
curve.rawResult = [];
end
