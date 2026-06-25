function fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%GUIEVALUATEFITFULLCURVE Evaluate fitted model on a plotting grid.
%
% fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%
% This helper is intended for visual QC. The plotted in-band curve is anchored
% to the model values used by the fit. This avoids mixing two continuation
% paths when a branch tracker is path-dependent on the first frequency.

if nargin < 2 || isempty(nPoints)
    nPoints = 80;
end

frequencyData = fitResult.frequency_Hz(:);
validData = isfinite(frequencyData) & frequencyData > 0;
frequencyData = frequencyData(validData);
if isempty(frequencyData)
    fullCurve = emptyCurve();
    return;
end

modelFamily = string(fitResult.modelFamily);
branchName = string(fitResult.branchName);

fmin = min(frequencyData);
fmax = max(frequencyData);
if fmax <= fmin
    fmax = fmin * 1.05;
end

frequencySmooth_Hz = linspace(fmin, fmax, max(nPoints, 20)).';
frequencyAnchor_Hz = fitResult.frequency_Hz(:);
CpAnchor_mps = fitResult.Cp_fit_mps(:);
validAnchor = fitResult.validMask(:) & isfinite(frequencyAnchor_Hz) & isfinite(CpAnchor_mps) & frequencyAnchor_Hz > 0;

if nnz(validAnchor) >= 2
    [frequencyAnchorSorted, sortIdx] = sort(frequencyAnchor_Hz(validAnchor));
    CpAnchorSorted = CpAnchor_mps(validAnchor);
    CpAnchorSorted = CpAnchorSorted(sortIdx);
    CpSmooth_mps = interp1(frequencyAnchorSorted, CpAnchorSorted, frequencySmooth_Hz, 'pchip', nan);
    validSmooth = isfinite(CpSmooth_mps);
else
    CpSmooth_mps = nan(size(frequencySmooth_Hz));
    validSmooth = false(size(frequencySmooth_Hz));
end

raw = struct();
extended = emptyExtension();
if modelFamily == "rayleigh_lamb" || modelFamily == "mrlfe" || modelFamily == "acoustoelastic_iop_hgo"
    extended = localEvaluateExtension(fitResult, modelFamily, branchName, fmin, fmax, nPoints);
    raw.extension = extended;
end

fullCurve = struct();
fullCurve.modelFamily = modelFamily;
fullCurve.branchName = branchName;
fullCurve.frequency_Hz = frequencySmooth_Hz(:);
fullCurve.Cp_mps = CpSmooth_mps(:);
fullCurve.validMask = validSmooth(:);
fullCurve.rawResult = raw;
fullCurve.extension = extended;
fullCurve.anchorFrequency_Hz = frequencyAnchor_Hz(:);
fullCurve.anchorCp_mps = CpAnchor_mps(:);
fullCurve.anchorValidMask = validAnchor(:);
fullCurve.note = "in-band curve interpolates fitted model values at experimental frequencies";
end

function extended = localEvaluateExtension(fitResult, modelFamily, branchName, fmin, fmax, nPoints)
extended = emptyExtension();
try
    params = fitResult.allParams;
    fminExt = max(1, 0.5 * fmin);
    fmaxExt = 1.5 * fmax;
    if fmaxExt <= fminExt
        return;
    end
    switch modelFamily
        case "rayleigh_lamb"
            frequencyExt_Hz = linspace(fminExt, fmaxExt, max(nPoints, 20)).';
            options = fitResult.problem.solverOptions;
            [CpExt_mps, rawExt] = rlEvaluateFitModel(params, frequencyExt_Hz, branchName, options);
        case "mrlfe"
            frequencyExt_Hz = linspace(fminExt, fmaxExt, max(nPoints, 20)).';
            options = fitResult.problem.solverOptions;
            [CpExt_mps, rawExt] = mrlfeEvaluateFitModel(params, frequencyExt_Hz, branchName, options);
        case "acoustoelastic_iop_hgo"
            frequencyExt_Hz = logspace(log10(fminExt), log10(fmaxExt), max(35, min(nPoints, 45))).';
            options = fitResult.problem.solverOptions;
            [CpExt_mps, rawExt] = aeEvaluateFitModel(params, frequencyExt_Hz, "atlasA0", options);
        otherwise
            return;
    end
    validExt = isfinite(CpExt_mps(:));
    if isstruct(rawExt) && isfield(rawExt, 'validMask')
        validExt = validExt & rawExt.validMask(:);
    end
    extended.frequency_Hz = frequencyExt_Hz(:);
    extended.Cp_mps = CpExt_mps(:);
    extended.validMask = validExt(:);
    extended.rawResult = rawExt;
catch ME
    extended.errorMessage = string(ME.message);
end
end

function curve = emptyCurve()
curve = struct();
curve.modelFamily = "";
curve.branchName = "";
curve.frequency_Hz = [];
curve.Cp_mps = [];
curve.validMask = [];
curve.rawResult = [];
curve.extension = emptyExtension();
end

function extension = emptyExtension()
extension = struct();
extension.frequency_Hz = [];
extension.Cp_mps = [];
extension.validMask = [];
extension.rawResult = [];
extension.errorMessage = "";
end
