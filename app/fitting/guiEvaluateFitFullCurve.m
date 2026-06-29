function fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%GUIEVALUATEFITFULLCURVE Evaluate fitted model on a plotting grid.
%
% fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%
% This helper is intended for visual QC. For most models the plotted in-band
% curve is evaluated directly with the fitted solver parameters. If direct
% dense evaluation is not available, the helper falls back to interpolation
% through the fitted model values at the experimental frequencies.

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

[CpSmooth_mps, validSmooth, rawInBand, curveNote] = localEvaluateInBandCurve( ...
    fitResult, modelFamily, branchName, frequencySmooth_Hz, ...
    frequencyAnchor_Hz, CpAnchor_mps, validAnchor);

raw = struct();
raw.inBand = rawInBand;
extended = emptyExtension();
if shouldEvaluateExtension(fitResult, modelFamily)
    extended = localEvaluateExtension(fitResult, modelFamily, branchName, fmin, fmax, nPoints);
    raw.extension = extended;
else
    extended.errorMessage = "extension skipped for fast GUI fitting path";
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
fullCurve.note = curveNote;
end

function [CpSmooth_mps, validSmooth, rawInBand, curveNote] = localEvaluateInBandCurve( ...
        fitResult, modelFamily, branchName, frequencySmooth_Hz, ...
        frequencyAnchor_Hz, CpAnchor_mps, validAnchor)
rawInBand = struct();
curveNote = "in-band curve interpolates fitted model values at experimental frequencies";

try
    params = fitResult.allParams;
    options = fitResult.problem.solverOptions;

    switch modelFamily
        case "rayleigh_lamb"
            [CpSmooth_mps, rawInBand] = rlEvaluateFitModel(params, frequencySmooth_Hz, branchName, options);
            validSmooth = isfinite(CpSmooth_mps(:));
            if isstruct(rawInBand) && isfield(rawInBand, 'validMask')
                validSmooth = validSmooth & rawInBand.validMask(:);
            end
            curveNote = "in-band dense solver curve evaluated with fitted parameters";
            return;

        case "mrlfe"
            [CpSmooth_mps, rawInBand] = mrlfeEvaluateFitModel(params, frequencySmooth_Hz, branchName, options);
            validSmooth = isfinite(CpSmooth_mps(:));
            if isstruct(rawInBand) && isfield(rawInBand, 'validMask')
                validSmooth = validSmooth & rawInBand.validMask(:);
            end
            curveNote = "in-band dense solver curve evaluated with fitted parameters";
            return;

        case "acoustoelastic_iop_hgo"
            [CpSmooth_mps, rawInBand] = aeEvaluateFitModel(params, frequencySmooth_Hz, "atlasA0", options);
            validSmooth = isfinite(CpSmooth_mps(:));
            if isstruct(rawInBand) && isfield(rawInBand, 'validMask')
                validSmooth = validSmooth & rawInBand.validMask(:);
            end
            curveNote = "in-band dense solver curve evaluated with fitted parameters";
            return;
    end
catch ME
    rawInBand = struct('errorMessage', string(ME.message));
end

[CpSmooth_mps, validSmooth] = localInterpolateAnchorCurve(frequencySmooth_Hz, ...
    frequencyAnchor_Hz, CpAnchor_mps, validAnchor);
end

function [CpSmooth_mps, validSmooth] = localInterpolateAnchorCurve(frequencySmooth_Hz, ...
        frequencyAnchor_Hz, CpAnchor_mps, validAnchor)
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
end

function value = getOption(options, name, defaultValue)
value = defaultValue;
if isstruct(options) && isfield(options, name) && ~isempty(options.(name))
    value = options.(name);
end
end

function tf = shouldEvaluateExtension(fitResult, modelFamily)
if modelFamily == "mrlfe"
    tf = false;
    if isfield(fitResult, 'problem') && isfield(fitResult.problem, 'fitOptions') && ...
            isfield(fitResult.problem.fitOptions, 'evaluateFullCurveExtension') && ...
            ~isempty(fitResult.problem.fitOptions.evaluateFullCurveExtension)
        tf = logical(fitResult.problem.fitOptions.evaluateFullCurveExtension);
    end
else
    tf = true;
end
end

function extended = localEvaluateExtension(fitResult, modelFamily, branchName, fmin, fmax, nPoints)
extended = emptyExtension();
try
    params = fitResult.allParams;
    if modelFamily == "mrlfe"
        fminExt = fmin;
        fmaxExt = fmax + getOption(fitResult.problem.fitOptions, 'mrlfeFullCurveExtensionMargin_Hz', 2000);
    else
        fminExt = max(1, 0.5 * fmin);
        fmaxExt = 1.5 * fmax;
    end
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
