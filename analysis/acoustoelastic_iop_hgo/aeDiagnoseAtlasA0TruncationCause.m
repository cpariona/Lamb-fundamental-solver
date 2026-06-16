function diagnosis = aeDiagnoseAtlasA0TruncationCause(result, varargin)
%AEDIAGNOSEATLASA0TRUNCATIONCAUSE Diagnose likely causes of atlasA0 truncation.
%
%   This diagnostic is read-only. It does not modify result.Cp or
%   result.validCp. It inspects the local-minimum landscape around the first
%   missing atlasA0 point and assigns conservative cause labels.

opts = parseOptions(varargin{:});
f = result.frequency(:);
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);

recovery = aeAnalyzeTruncationRecovery(result, ...
    'MaxRelativeCpDistance', opts.MaxRelativeCpJump, ...
    'MaxRelativeBridgeMismatch', opts.MaxRelativeBridgeMismatch, ...
    'MaxGapPoints', opts.MaxGapPoints, ...
    'MaxGapFrequencyRatio', opts.MaxGapFrequencyRatio);

persistence = aeAnalyzeBranchPersistenceCandidates(result, ...
    'MaxRelativeCpJump', opts.MaxRelativeCpJump, ...
    'MaxRelativeBridgeMismatch', opts.MaxRelativeBridgeMismatch, ...
    'MaxGapPoints', opts.MaxGapPoints, ...
    'MaxGapFrequencyRatio', opts.MaxGapFrequencyRatio, ...
    'MaxCandidateRank', opts.MaxCandidateRank, ...
    'StrongCandidateRank', opts.StrongCandidateRank);

[firstBreak, previousIdx] = findFirstBreak(valid);
windowIdx = buildWindow(firstBreak, numel(f), opts.WindowPoints);

localTable = buildLocalTable(result, f, cp, valid, recovery, persistence, windowIdx, previousIdx, opts);
summary = buildSummary(result, f, cp, valid, firstBreak, previousIdx, localTable, persistence, opts);

resolutionTable = buildAtlasResolutionPlan(opts);

diagnosis = struct();
diagnosis.options = opts;
diagnosis.summary = summary;
diagnosis.localCauseTable = localTable;
diagnosis.persistence = persistence;
diagnosis.recovery = recovery;
diagnosis.atlasResolutionPlan = resolutionTable;
end

function opts = parseOptions(varargin)
opts = struct();
opts.Label = "";
opts.WindowPoints = 6;
opts.MaxRelativeCpJump = 0.15;
opts.MaxRelativeBridgeMismatch = 0.03;
opts.MaxGapPoints = 2;
opts.MaxGapFrequencyRatio = 1.12;
opts.MaxCandidateRank = 12;
opts.StrongCandidateRank = 3;
opts.MinimaFrequencyTolerance_Hz = 1e-6;
opts.CrowdingRelativeCp = 0.05;
opts.ObjectiveRatioDistinct = 1.25;
opts.AtlasNumYPointsValues = [1000 1500 2000 3000];
opts.AtlasTopNMinimaValues = [18 24 32];
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = lower(string(varargin{i}));
    value = varargin{i+1};
    switch name
        case 'label'
            opts.Label = string(value);
        case 'windowpoints'
            opts.WindowPoints = value;
        case 'maxrelativecpjump'
            opts.MaxRelativeCpJump = value;
        case 'maxrelativebridgemismatch'
            opts.MaxRelativeBridgeMismatch = value;
        case 'maxgappoints'
            opts.MaxGapPoints = value;
        case 'maxgapfrequencyratio'
            opts.MaxGapFrequencyRatio = value;
        case 'maxcandidaterank'
            opts.MaxCandidateRank = value;
        case 'strongcandidaterank'
            opts.StrongCandidateRank = value;
        case 'minimafrequencytolerance_hz'
            opts.MinimaFrequencyTolerance_Hz = value;
        case 'crowdingrelativecp'
            opts.CrowdingRelativeCp = value;
        case 'objectiveratiodistinct'
            opts.ObjectiveRatioDistinct = value;
        case 'atlasnumypointsvalues'
            opts.AtlasNumYPointsValues = value;
        case 'atlastopnminimavalues'
            opts.AtlasTopNMinimaValues = value;
        otherwise
            error('Unknown aeDiagnoseAtlasA0TruncationCause option: %s', name);
    end
end
end

function [firstBreak, previousIdx] = findFirstBreak(valid)
firstValid = find(valid, 1, 'first');
if isempty(firstValid)
    firstBreak = nan;
    previousIdx = nan;
    return;
end
firstBreak = find(~valid & (1:numel(valid)).' >= firstValid, 1, 'first');
if isempty(firstBreak)
    firstBreak = nan;
    previousIdx = find(valid, 1, 'last');
else
    previousIdx = find(valid & (1:numel(valid)).' < firstBreak, 1, 'last');
    if isempty(previousIdx), previousIdx = nan; end
end
end

function idx = buildWindow(centerIdx, n, windowPoints)
if isnan(centerIdx)
    idx = (1:n).';
else
    idx = (max(1, centerIdx-windowPoints):min(n, centerIdx+windowPoints)).';
end
end

function T = buildLocalTable(result, f, cp, valid, recovery, persistence, idx, previousIdx, opts)
if isempty(idx)
    T = table();
    return;
end
rows = [];
previousCp = nan;
previousBranchID = nan;
if isfinite(previousIdx)
    previousCp = cp(previousIdx);
    previousBranchID = getVectorValue(result, 'nearestBranchID', previousIdx, nan);
end
P = persistence.candidateTable;
for ii = 1:numel(idx)
    k = idx(ii);
    row = struct();
    row.Index = k;
    row.Frequency_kHz = f(k) / 1e3;
    row.OfficialValid = valid(k);
    row.OfficialCp_mps = cp(k);
    row.PreviousOfficialCp_mps = previousCp;
    row.BranchIDBeforeBreak = previousBranchID;
    row.OfficialNearestRank = getVectorValue(result, 'nearestRank', k, nan);
    row.OfficialNearestBranchID = getVectorValue(result, 'nearestBranchID', k, nan);
    row.OfficialObjective = getVectorValue(result, 'objective', k, nan);

    Mf = minimaAtFrequency(result, f(k), opts.MinimaFrequencyTolerance_Hz);
    stats = summarizeMinima(Mf, previousCp, opts);
    row.NumMinimaAtFrequency = stats.NumMinimaAtFrequency;
    row.NearestMinimumCp_mps = stats.NearestMinimumCp_mps;
    row.NearestMinimumRank = stats.NearestMinimumRank;
    row.NearestMinimumObjective = stats.NearestMinimumObjective;
    row.NearestMinimumBranchID = stats.NearestMinimumBranchID;
    row.NearestRelativeCpDistance = stats.NearestRelativeCpDistance;
    row.BestMinimumCp_mps = stats.BestMinimumCp_mps;
    row.BestMinimumRank = stats.BestMinimumRank;
    row.BestMinimumObjective = stats.BestMinimumObjective;
    row.BestObjectiveRatio = stats.BestObjectiveRatio;
    row.MinimaCrowdingScore = stats.MinimaCrowdingScore;
    row.NearestBranchIDAfterBreak = stats.NearestMinimumBranchID;
    row.AtlasGridBoundaryFlag = false;

    [accepted, quality] = lookupPersistence(P, k);
    row.AcceptedPersistenceCandidate = accepted;
    row.PersistenceQuality = quality;
    row.RawRecovered = logical(recovery.recoveredValid(k)) && ~valid(k);
    row.RawContiguousRecovered = logical(recovery.contiguousRecoveredValid(k)) && ~valid(k);
    row.CandidateCauseLabel = classifyRow(row, opts);
    rows = [rows; row]; %#ok<AGROW>
end
T = struct2table(rows);
end

function Mf = minimaAtFrequency(result, f0, tol)
if ~isfield(result, 'minimaTable') || isempty(result.minimaTable)
    Mf = table();
    return;
end
M = result.minimaTable;
Mf = M(abs(M.Frequency_Hz - f0) <= tol * max(abs(f0), 1), :);
end

function stats = summarizeMinima(Mf, previousCp, opts)
stats = emptyMinimaStats();
stats.NumMinimaAtFrequency = height(Mf);
if isempty(Mf)
    return;
end
if ismember('Objective', Mf.Properties.VariableNames)
    [objSorted, order] = sort(Mf.Objective);
else
    order = (1:height(Mf)).';
    objSorted = nan(height(Mf), 1);
end
best = order(1);
stats.BestMinimumCp_mps = getCol(Mf, 'Cp_mps', best, nan);
stats.BestMinimumRank = getCol(Mf, 'MinRank', best, nan);
stats.BestMinimumObjective = getCol(Mf, 'Objective', best, nan);
if numel(objSorted) >= 2 && isfinite(objSorted(1)) && objSorted(1) > 0
    stats.BestObjectiveRatio = objSorted(2) / objSorted(1);
end
if isfinite(previousCp)
    rel = abs(Mf.Cp_mps - previousCp) ./ max(abs(previousCp), eps);
    [stats.NearestRelativeCpDistance, j] = min(rel);
    stats.NearestMinimumCp_mps = Mf.Cp_mps(j);
    stats.NearestMinimumRank = getCol(Mf, 'MinRank', j, nan);
    stats.NearestMinimumObjective = getCol(Mf, 'Objective', j, nan);
    stats.NearestMinimumBranchID = getCol(Mf, 'BranchID', j, nan);
    stats.MinimaCrowdingScore = nnz(rel <= opts.CrowdingRelativeCp);
end
end

function stats = emptyMinimaStats()
stats = struct();
stats.NumMinimaAtFrequency = 0;
stats.NearestMinimumCp_mps = nan;
stats.NearestMinimumRank = nan;
stats.NearestMinimumObjective = nan;
stats.NearestMinimumBranchID = nan;
stats.NearestRelativeCpDistance = nan;
stats.BestMinimumCp_mps = nan;
stats.BestMinimumRank = nan;
stats.BestMinimumObjective = nan;
stats.BestObjectiveRatio = nan;
stats.MinimaCrowdingScore = 0;
end

function [accepted, quality] = lookupPersistence(P, k)
accepted = false;
quality = "none";
if isempty(P) || ~ismember('Index', P.Properties.VariableNames)
    return;
end
j = find(P.Index == k, 1, 'first');
if isempty(j)
    return;
end
if ismember('PersistenceCandidateAccepted', P.Properties.VariableNames)
    accepted = logical(P.PersistenceCandidateAccepted(j));
end
if ismember('PersistenceQuality', P.Properties.VariableNames)
    quality = string(P.PersistenceQuality(j));
end
end

function label = classifyRow(row, opts)
if row.OfficialValid
    label = "official_valid";
elseif row.NumMinimaAtFrequency == 0
    label = "no_minimum_available";
elseif row.AcceptedPersistenceCandidate && row.NearestMinimumRank > opts.StrongCandidateRank
    label = "candidate_low_rank";
elseif row.AcceptedPersistenceCandidate
    label = "accepted_diagnostic_candidate";
elseif isfinite(row.NearestRelativeCpDistance) && row.NearestRelativeCpDistance > opts.MaxRelativeCpJump
    label = "nearest_minimum_too_far";
elseif row.MinimaCrowdingScore >= 2
    label = "crowded_minima_landscape";
elseif isfinite(row.BestObjectiveRatio) && row.BestObjectiveRatio < opts.ObjectiveRatioDistinct
    label = "objective_not_distinct";
elseif isfinite(row.BranchIDBeforeBreak) && isfinite(row.NearestBranchIDAfterBreak) && row.BranchIDBeforeBreak ~= row.NearestBranchIDAfterBreak
    label = "branch_id_discontinuity";
else
    label = "unclassified_tracker_rejection";
end
end

function summary = buildSummary(result, f, cp, valid, firstBreak, previousIdx, localTable, persistence, opts)
summary = struct();
summary.CaseLabel = opts.Label;
summary.TotalPoints = numel(f);
summary.OfficialValidPoints = nnz(valid);
summary.OfficialValidFraction = nnz(valid) / max(numel(valid), 1);
summary.FirstMissingIndex = firstBreak;
summary.FirstMissingFrequency_kHz = valueFrequency(f, firstBreak);
summary.PreviousValidIndex = previousIdx;
summary.PreviousValidFrequency_kHz = valueFrequency(f, previousIdx);
summary.PreviousValidCp_mps = valueAt(cp, previousIdx);
summary.LastOfficialValidFrequency_kHz = valueFrequency(f, find(valid, 1, 'last'));
summary.DiagnosticAcceptedPoints = persistence.summary.NumContiguousPersistenceCandidates;
summary.DiagnosticExtension_kHz = persistence.summary.PersistenceExtension_kHz;
summary.DiagnosticMedianAcceptedRank = persistence.summary.MedianAcceptedCandidateRank;
summary.DiagnosticStrongAcceptedPoints = persistence.summary.NumStrongAcceptedCandidates;
summary.DiagnosticWeakAcceptedPoints = persistence.summary.NumLowRankOrWeakAcceptedCandidates;
summary.DominantCauseLabel = dominantCause(localTable);
summary.Interpretation = interpretCause(summary.DominantCauseLabel);
summary.AtlasYMin = getReliabilityField(result, 'YMin', nan);
summary.AtlasYMax = getReliabilityField(result, 'YMax', nan);
summary.AtlasYStart = getReliabilityField(result, 'YStart', nan);
summary.AtlasYBoundaryStatus = classifyYBoundary(summary.AtlasYMin, summary.AtlasYMax, summary.AtlasYStart);
summary.Note = "Causal diagnostic only; atlasA0 output remains unchanged.";
end

function label = dominantCause(T)
if isempty(T)
    label = "no_diagnostic_window";
    return;
end
U = T(~T.OfficialValid, :);
if isempty(U)
    label = "no_truncation";
    return;
end
labels = string(U.CandidateCauseLabel);
priority = ["no_minimum_available", "nearest_minimum_too_far", "candidate_low_rank", ...
    "crowded_minima_landscape", "objective_not_distinct", "branch_id_discontinuity", ...
    "accepted_diagnostic_candidate", "unclassified_tracker_rejection"];
for i = 1:numel(priority)
    if any(labels == priority(i))
        label = priority(i);
        return;
    end
end
label = labels(1);
end

function txt = interpretCause(label)
switch string(label)
    case "no_truncation"
        txt = "No official truncation was detected in the inspected branch.";
    case "no_minimum_available"
        txt = "No local minimum was available at the break; inspect atlas coverage or objective sampling.";
    case "nearest_minimum_too_far"
        txt = "Local minima exist, but the nearest one is too far from the previous official Cp.";
    case "candidate_low_rank"
        txt = "A diagnostic continuation exists, but it relies on low-rank or weak minima.";
    case "crowded_minima_landscape"
        txt = "Multiple minima crowd the continuation neighborhood, so branch identity is ambiguous.";
    case "objective_not_distinct"
        txt = "The objective has competing minima with similar values near the break.";
    case "branch_id_discontinuity"
        txt = "The nearest continuation changes branch identity across the break.";
    case "accepted_diagnostic_candidate"
        txt = "A diagnostic candidate exists; verify persistence before promoting any policy.";
    otherwise
        txt = "The break was not classified by the current causal rules.";
end
end

function T = buildAtlasResolutionPlan(opts)
rows = [];
for ny = opts.AtlasNumYPointsValues(:).'
    for nt = opts.AtlasTopNMinimaValues(:).'
        row = struct();
        row.AtlasNumYPoints = ny;
        row.AtlasTopNMinima = nt;
        row.Purpose = "rerun_case_sensitivity";
        rows = [rows; row]; %#ok<AGROW>
    end
end
T = struct2table(rows);
end

function value = getVectorValue(result, fieldName, idx, defaultValue)
if isfield(result, fieldName) && numel(result.(fieldName)) >= idx
    value = result.(fieldName)(idx);
else
    value = defaultValue;
end
end

function value = getCol(T, name, idx, defaultValue)
if ismember(name, T.Properties.VariableNames)
    value = T.(name)(idx);
else
    value = defaultValue;
end
end

function value = valueAt(v, idx)
if isempty(idx) || isnan(idx)
    value = nan;
else
    value = v(idx);
end
end

function value = valueFrequency(f, idx)
if isempty(idx) || isnan(idx)
    value = nan;
else
    value = f(idx) / 1e3;
end
end

function value = getReliabilityField(result, name, defaultValue)
if isfield(result, 'reliability') && isstruct(result.reliability) && isfield(result.reliability, name)
    value = result.reliability.(name);
else
    value = defaultValue;
end
end

function status = classifyYBoundary(ymin, ymax, ystart)
if ~isfinite(ymin) || ~isfinite(ymax) || ~isfinite(ystart) || ymax <= ymin
    status = "unknown";
    return;
end
r = (ystart - ymin) / (ymax - ymin);
if r < 0.05
    status = "near_lower_boundary";
elseif r > 0.95
    status = "near_upper_boundary";
else
    status = "inside_window";
end
end
