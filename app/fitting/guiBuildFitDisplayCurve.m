function displayCurve = guiBuildFitDisplayCurve(fitResult, nPoints)
%GUIBUILDFITDISPLAYCURVE Build a plotting curve from objective values only.
%
% This helper never calls a forward solver. It interpolates the fitted model
% values already evaluated at the experimental frequencies.

if nargin < 2 || isempty(nPoints)
    nPoints = 80;
end
frequencyAnchor_Hz = fitResult.frequency_Hz(:);
CpAnchor_mps = fitResult.Cp_fit_mps(:);
validAnchor = fitResult.validMask(:) & isfinite(frequencyAnchor_Hz) & ...
    isfinite(CpAnchor_mps) & frequencyAnchor_Hz > 0;

if nnz(validAnchor) < 2
    frequencySmooth_Hz = frequencyAnchor_Hz;
    CpSmooth_mps = CpAnchor_mps;
    validSmooth = validAnchor;
else
    fmin = min(frequencyAnchor_Hz(validAnchor));
    fmax = max(frequencyAnchor_Hz(validAnchor));
    frequencySmooth_Hz = linspace(fmin, fmax, max(20, round(nPoints))).';
    [frequencySorted, idx] = sort(frequencyAnchor_Hz(validAnchor));
    CpSorted = CpAnchor_mps(validAnchor);
    CpSorted = CpSorted(idx);
    CpSmooth_mps = interp1(frequencySorted, CpSorted, frequencySmooth_Hz, 'pchip', nan);
    validSmooth = isfinite(CpSmooth_mps);
end

displayCurve = struct();
displayCurve.modelFamily = string(fitResult.modelFamily);
displayCurve.branchName = string(fitResult.branchName);
displayCurve.frequency_Hz = frequencySmooth_Hz(:);
displayCurve.Cp_mps = CpSmooth_mps(:);
displayCurve.validMask = validSmooth(:);
displayCurve.anchorFrequency_Hz = frequencyAnchor_Hz(:);
displayCurve.anchorCp_mps = CpAnchor_mps(:);
displayCurve.anchorValidMask = validAnchor(:);
displayCurve.source = "fitObjectiveInterpolation";
displayCurve.solverEvaluated = false;
displayCurve.rawResult = struct();
displayCurve.extension = struct('frequency_Hz', [], 'Cp_mps', [], ...
    'validMask', [], 'rawResult', [], 'errorMessage', ...
    "full curve is evaluated only on explicit user request");
displayCurve.denseSolver = struct('frequency_Hz', [], 'Cp_mps', [], ...
    'validMask', [], 'rawResult', [], 'CpAtData_mps', [], ...
    'denseMinusFitAtData_mps', [], 'maxAbsDenseMinusFit_mps', nan, ...
    'warningThreshold_mps', nan, 'hasGridMismatch', false, ...
    'warningMessage', "", 'errorMessage', ...
    "solver reevaluation skipped until requested", 'note', ...
    "display curve uses fit-objective values only");
displayCurve.note = "fit-consistent interpolation; no solver reevaluation";
displayCurve.elapsedSeconds = 0;
end
