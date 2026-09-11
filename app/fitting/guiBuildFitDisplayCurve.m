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

% Segment before sorting: an invalid anchor is a boundary, never discarded.
boundaries = diff([false; validAnchor; false]);
starts = find(boundaries == 1);
stops = find(boundaries == -1) - 1;
frequencySmooth_Hz = [];
CpSmooth_mps = [];
nextAnchor = 1;
for segment = 1:numel(starts)
    first = starts(segment);
    last = stops(segment);
    frequencySmooth_Hz = [frequencySmooth_Hz; frequencyAnchor_Hz(nextAnchor:first-1)]; %#ok<AGROW>
    CpSmooth_mps = [CpSmooth_mps; nan(first-nextAnchor, 1)]; %#ok<AGROW>
    [frequencySorted, idx] = sort(frequencyAnchor_Hz(first:last));
    CpSorted = CpAnchor_mps(first:last);
    CpSorted = CpSorted(idx);
    if first == last
        segmentFrequency = frequencySorted;
        segmentCp = CpSorted;
    else
        segmentFrequency = linspace(frequencySorted(1), frequencySorted(end), ...
            max(20, round(nPoints))).';
        segmentCp = interp1(frequencySorted, CpSorted, segmentFrequency, 'pchip', nan);
    end
    frequencySmooth_Hz = [frequencySmooth_Hz; segmentFrequency]; %#ok<AGROW>
    CpSmooth_mps = [CpSmooth_mps; segmentCp]; %#ok<AGROW>
    nextAnchor = last + 1;
end
frequencySmooth_Hz = [frequencySmooth_Hz; frequencyAnchor_Hz(nextAnchor:end)];
CpSmooth_mps = [CpSmooth_mps; nan(numel(validAnchor)-nextAnchor+1, 1)];
validSmooth = isfinite(CpSmooth_mps);

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
