% TEMPORARY_DIAGNOSTIC
function summary = diagnoseAeCoarseRescueTrigger(varargin)
%DIAGNOSEAECOARSERESCUETRIGGER Characterize coarse-atlas selection confidence.

p = inputParser;
p.addParameter('CoarsePoints', 180, @(x)isnumeric(x) && isscalar(x) && x >= 20);
p.addParameter('ReferencePoints', 300, @(x)isnumeric(x) && isscalar(x) && x >= 20);
p.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

cases = buildCases();
rows = repmat(emptyRow(), 0, 1);

fprintf('\nAE coarse rescue-trigger diagnostic\n');
fprintf('===================================\n');
fprintf('Coarse: %d | Reference: %d\n\n', opt.CoarsePoints, opt.ReferencePoints);

for iCase = 1:numel(cases)
    params = cases(iCase).params;
    coarseOptions = aeDefaultSweepOptions("Fast");
    coarseOptions.atlasNumYPoints = opt.CoarsePoints;
    refOptions = coarseOptions;
    refOptions.atlasNumYPoints = opt.ReferencePoints;

    t = tic;
    coarse = solveAcoustoelasticIOPHGOBranch(params, coarseOptions);
    coarseSeconds = toc(t);
    t = tic;
    reference = solveAcoustoelasticIOPHGOBranch(params, refOptions);
    referenceSeconds = toc(t);

    cmp = compareResults(coarse, reference);
    confidence = summarizeConfidence(coarse);

    row = emptyRow();
    row.Case = cases(iCase).name;
    row.CoarseSeconds = coarseSeconds;
    row.ReferenceSeconds = referenceSeconds;
    row.SpeedupVsReference = referenceSeconds / coarseSeconds;
    row.Unsafe = cmp.validMismatch > 0 || ~isfinite(cmp.maxRelCp) || cmp.maxRelCp > 1e-4;
    row.ValidMaskMismatchCount = cmp.validMismatch;
    row.MaxAbsCpDiff_mps = cmp.maxAbsCp;
    row.MaxRelativeCpDiff = cmp.maxRelCp;
    row.SelectedBranchFrequencyMismatchCount = cmp.branchFrequencyMismatch;
    row.FallbackMismatch = cmp.fallbackMismatch;
    row.FallbackUsed = confidence.fallbackUsed;
    row.ValidFraction = confidence.validFraction;
    row.SelectedNumPoints = confidence.selectedNumPoints;
    row.SelectedCoverage_kHz = confidence.selectedCoverage_kHz;
    row.SelectedStartRank = confidence.selectedStartRank;
    row.SelectedStartY = confidence.selectedStartY;
    row.SelectedRoughness = confidence.selectedRoughness;
    row.SelectedMaxRelativeCpDrop = confidence.selectedMaxRelativeCpDrop;
    row.SelectedScore = confidence.selectedScore;
    row.NextEligibleScore = confidence.nextEligibleScore;
    row.SelectionScoreGap = confidence.selectionScoreGap;
    row.EligibleBranchCount = confidence.eligibleBranchCount;
    row.TotalBranchCount = confidence.totalBranchCount;
    rows(end+1,1) = row; %#ok<AGROW>

    fprintf('%-16s unsafe %d | dCp %.3g | validMismatch %d | scoreGap %.3g | eligible %d\n', ...
        row.Case, row.Unsafe, row.MaxAbsCpDiff_mps, row.ValidMaskMismatchCount, ...
        row.SelectionScoreGap, row.EligibleBranchCount);
end

summary = struct2table(rows);

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'acoustoelastic_iop_hgo', ...
        'diagnostics', 'coarse_rescue_trigger');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    outputFile = fullfile(outputFolder, 'ae_coarse_rescue_trigger.csv');
    writetable(summary, outputFile);
    fprintf('\nSaved %s\n', outputFile);
end
end

function confidence = summarizeConfidence(result)
confidence = struct('fallbackUsed',false,'validFraction',NaN,'selectedNumPoints',NaN, ...
    'selectedCoverage_kHz',NaN,'selectedStartRank',NaN,'selectedStartY',NaN, ...
    'selectedRoughness',NaN,'selectedMaxRelativeCpDrop',NaN,'selectedScore',NaN, ...
    'nextEligibleScore',NaN,'selectionScoreGap',NaN,'eligibleBranchCount',0,'totalBranchCount',0);

if isfield(result, 'quality') && isfield(result.quality, 'ValidFraction')
    confidence.validFraction = result.quality.ValidFraction;
end
if ~isfield(result, 'branchTable') || isempty(result.branchTable) || ...
        ~isfield(result, 'selectedBranch') || isempty(result.selectedBranch)
    return;
end

B = result.branchTable;
S = result.selectedBranch;
confidence.totalBranchCount = height(B);
if ismember('A0StartFilterPassed', B.Properties.VariableNames)
    eligible = logical(B.A0StartFilterPassed);
else
    eligible = true(height(B),1);
end
confidence.eligibleBranchCount = nnz(eligible);
if ismember('SelectionFallbackUsed', S.Properties.VariableNames)
    confidence.fallbackUsed = logical(S.SelectionFallbackUsed(1));
end
confidence.selectedNumPoints = fieldValue(S, 'NumPoints');
confidence.selectedCoverage_kHz = fieldValue(S, 'FrequencyCoverage_kHz');
confidence.selectedStartRank = fieldValue(S, 'StartRank');
confidence.selectedStartY = fieldValue(S, 'YStart');
confidence.selectedRoughness = fieldValue(S, 'Roughness');
confidence.selectedMaxRelativeCpDrop = fieldValue(S, 'MaxRelativeCpDrop');
confidence.selectedScore = fieldValue(S, 'SelectionScore');

if ismember('SelectionScore', B.Properties.VariableNames)
    scores = B.SelectionScore;
    scores = scores(isfinite(scores) & eligible);
    scores = sort(scores, 'ascend');
    if numel(scores) >= 2
        confidence.nextEligibleScore = scores(2);
        confidence.selectionScoreGap = scores(2) - scores(1);
    elseif numel(scores) == 1
        confidence.selectionScoreGap = inf;
    end
end
end

function value = fieldValue(T, fieldName)
value = NaN;
if ismember(fieldName, T.Properties.VariableNames)
    value = T.(fieldName)(1);
end
end

function cmp = compareResults(candidate, reference)
cmp = struct();
cmp.validMismatch = nnz(candidate.validMask ~= reference.validMask);
common = isfinite(candidate.phaseVelocity_mps) & isfinite(reference.phaseVelocity_mps);
if any(common)
    delta = abs(candidate.phaseVelocity_mps(common) - reference.phaseVelocity_mps(common));
    cmp.maxAbsCp = max(delta);
    cmp.maxRelCp = max(delta ./ max(abs(reference.phaseVelocity_mps(common)), eps));
else
    cmp.maxAbsCp = NaN;
    cmp.maxRelCp = NaN;
end
[candidateFreq, ~] = selectedSignature(candidate);
[referenceFreq, ~] = selectedSignature(reference);
commonFreq = intersect(candidateFreq, referenceFreq, 'stable');
cmp.branchFrequencyMismatch = numel(candidateFreq) + numel(referenceFreq) - 2*numel(commonFreq);
cmp.fallbackMismatch = double(fallbackUsed(candidate) ~= fallbackUsed(reference));
end

function [frequency, rank] = selectedSignature(result)
frequency = [];
rank = [];
if ~isfield(result, 'selectedBranchPoints') || isempty(result.selectedBranchPoints)
    return;
end
T = sortrows(result.selectedBranchPoints, 'Frequency_Hz');
frequency = T.Frequency_Hz(:);
rank = T.MinRank(:);
end

function tf = fallbackUsed(result)
tf = false;
if isfield(result, 'selectedBranch') && ~isempty(result.selectedBranch) && ...
        ismember('SelectionFallbackUsed', result.selectedBranch.Properties.VariableNames)
    tf = logical(result.selectedBranch.SelectionFallbackUsed(1));
end
end

function cases = buildCases()
base = aeDefaultSweepParams();
base.frequency = logspace(log10(300), log10(15000), 24).';
mmHg = 133.322;
cases = repmat(struct('name',"",'params',base), 9, 1);
cases(1) = makeCase("default", base);
cases(2) = makeCase("soft_lowIOP", apply(base, 'mu',30e3,'IOP',8*mmHg));
cases(3) = makeCase("soft_highIOP", apply(base, 'mu',30e3,'IOP',30*mmHg));
cases(4) = makeCase("stiff_lowIOP", apply(base, 'mu',150e3,'IOP',8*mmHg));
cases(5) = makeCase("stiff_highIOP", apply(base, 'mu',150e3,'IOP',30*mmHg));
cases(6) = makeCase("thin_highIOP", apply(base, 'thickness',400e-6,'IOP',30*mmHg));
cases(7) = makeCase("thick_lowIOP", apply(base, 'thickness',700e-6,'IOP',8*mmHg));
cases(8) = makeCase("fiber_dominant", apply(base, 'k1',150e3,'k2',400,'IOP',20*mmHg));
cases(9) = makeCase("weak_fiber", apply(base, 'k1',15e3,'k2',80,'mu',50e3,'IOP',20*mmHg));
end

function c = makeCase(name, params)
c = struct('name',string(name),'params',params);
end

function s = apply(s, varargin)
for i = 1:2:numel(varargin)
    s.(varargin{i}) = varargin{i+1};
end
end

function row = emptyRow()
row = struct('Case',"",'CoarseSeconds',NaN,'ReferenceSeconds',NaN,'SpeedupVsReference',NaN, ...
    'Unsafe',false,'ValidMaskMismatchCount',0,'MaxAbsCpDiff_mps',NaN,'MaxRelativeCpDiff',NaN, ...
    'SelectedBranchFrequencyMismatchCount',0,'FallbackMismatch',0,'FallbackUsed',false, ...
    'ValidFraction',NaN,'SelectedNumPoints',NaN,'SelectedCoverage_kHz',NaN, ...
    'SelectedStartRank',NaN,'SelectedStartY',NaN,'SelectedRoughness',NaN, ...
    'SelectedMaxRelativeCpDrop',NaN,'SelectedScore',NaN,'NextEligibleScore',NaN, ...
    'SelectionScoreGap',NaN,'EligibleBranchCount',0,'TotalBranchCount',0);
end

function root = findRepositoryRoot(anchorFile)
folder = fileparts(anchorFile);
while true
    if isfile(fullfile(folder, 'startup.m'))
        root = folder;
        return;
    end
    parent = fileparts(folder);
    if strcmp(parent, folder)
        error('ae:RepositoryRootNotFound', 'Could not locate repository root.');
    end
    folder = parent;
end
end
