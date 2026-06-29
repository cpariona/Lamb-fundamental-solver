function fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%GUIEVALUATEFITFULLCURVE Evaluate fitted model on a plotting grid.
%
% fullCurve = guiEvaluateFitFullCurve(fitResult, nPoints)
%
% This helper is intended for visual QC. The primary in-band curve is
% fit-consistent: it interpolates the model values that were actually used by
% the objective function. This avoids silently mixing a second continuation
% path into the main fit visualization when a branch tracker is grid/path
% dependent.
%
% A dense solver re-evaluation is also stored as a diagnostic in
% fullCurve.denseSolver.

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

[CpSmooth_mps, validSmooth] = localInterpolateAnchorCurve( ...
    frequencySmooth_Hz, frequencyAnchor_Hz, CpAnchor_mps, validAnchor);

denseSolver = localEvaluateDenseSolverDiagnostic( ...
    fitResult, modelFamily, branchName, frequencySmooth_Hz, ...
    frequencyAnchor_Hz, CpAnchor_mps, validAnchor);

raw = struct();
raw.denseSolver = denseSolver;

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
fullCurve.denseSolver = denseSolver;
fullCurve.anchorFrequency_Hz = frequencyAnchor_Hz(:);
fullCurve.anchorCp_mps = CpAnchor_mps(:);
fullCurve.anchorValidMask = validAnchor(:);
fullCurve.note = "fit-consistent in-band curve interpolates solver values used by fit";
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

function denseSolver = localEvaluateDenseSolverDiagnostic(fitResult, modelFamily, branchName, ...
        frequencySmooth_Hz, frequencyAnchor_Hz, CpAnchor_mps, validAnchor)
denseSolver = emptyDenseSolverDiagnostic();
try
    params = fitResult.allParams;
    options = fitResult.problem.solverOptions;

    switch modelFamily
        case "rayleigh_lamb"
            [CpDense_mps, rawDense] = rlEvaluateFitModel(params, frequencySmooth_Hz, branchName, options);
        case "mrlfe"
            [CpDense_mps, rawDense] = mrlfeEvaluateFitModel(params, frequencySmooth_Hz, branchName, options);
        case "acoustoelastic_iop_hgo"
            [CpDense_mps, rawDense] = aeEvaluateFitModel(params, frequencySmooth_Hz, "atlasA0", options);
        otherwise
            denseSolver.errorMessage = "dense solver diagnostic skipped for unsupported model family";
            return;
    end

    validDense = isfinite(CpDense_mps(:));
    if isstruct(rawDense) && isfield(rawDense, 'validMask')
        validDense = validDense & rawDense.validMask(:);
    end

    CpDenseAtData_mps = interp1(frequencySmooth_Hz(:), CpDense_mps(:), frequencyAnchor_Hz(:), 'linear', nan);
    denseMinusFit_mps = CpDenseAtData_mps(:) - CpAnchor_mps(:);
    denseMinusFit_mps(~validAnchor(:)) = nan;

    denseSolver.frequency_Hz = frequencySmooth_Hz(:);
    denseSolver.Cp_mps = CpDense_mps(:);
    denseSolver.validMask = validDense(:);
    denseSolver.rawResult = rawDense;
    denseSolver.CpAtData_mps = CpDenseAtData_mps(:);
    denseSolver.denseMinusFitAtData_mps = denseMinusFit_mps(:);
    denseSolver.maxAbsDenseMinusFit_mps = max(abs(denseMinusFit_mps), [], 'omitnan');
    denseSolver.warningThreshold_mps = getDenseMismatchThreshold(fitResult);
    denseSolver.hasGridMismatch = isfinite(denseSolver.maxAbsDenseMinusFit_mps) && ...
        denseSolver.maxAbsDenseMinusFit_mps > denseSolver.warningThreshold_mps;
    denseSolver.note = "dense solver re-evaluation diagnostic; primary curve remains fit-consistent";

    if denseSolver.hasGridMismatch
        denseSolver.warningMessage = sprintf( ...
            'dense solver grid/path mismatch %.4g m/s exceeds %.4g m/s', ...
            denseSolver.maxAbsDenseMinusFit_mps, denseSolver.warningThreshold_mps);
    end
catch ME
    denseSolver.errorMessage = string(ME.message);
end
end

function threshold = getDenseMismatchThreshold(fitResult)
threshold = 0.05;
if isfield(fitResult, 'problem') && isfield(fitResult.problem, 'fitOptions')
    threshold = getOption(fitResult.problem.fitOptions, 'denseSolverMismatchThreshold_mps', threshold);
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

function value = getOption(options, name, defaultValue)
value = defaultValue;
if isstruct(options) && isfield(options, name) && ~isempty(options.(name))
    value = options.(name);
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
curve.denseSolver = emptyDenseSolverDiagnostic();
end

function extension = emptyExtension()
extension = struct();
extension.frequency_Hz = [];
extension.Cp_mps = [];
extension.validMask = [];
extension.rawResult = [];
extension.errorMessage = "";
end

function denseSolver = emptyDenseSolverDiagnostic()
denseSolver = struct();
denseSolver.frequency_Hz = [];
denseSolver.Cp_mps = [];
denseSolver.validMask = [];
denseSolver.rawResult = [];
denseSolver.CpAtData_mps = [];
denseSolver.denseMinusFitAtData_mps = [];
denseSolver.maxAbsDenseMinusFit_mps = nan;
denseSolver.warningThreshold_mps = nan;
denseSolver.hasGridMismatch = false;
denseSolver.warningMessage = "";
denseSolver.errorMessage = "";
denseSolver.note = "";
end
