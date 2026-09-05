% TEMPORARY_DIAGNOSTIC
function summary = diagnoseAeAdaptiveRescueMatrix(varargin)
%DIAGNOSEAEADAPTIVERESCUEMATRIX Validate coarse AE atlas with dense rescue.

p = inputParser;
p.addParameter('CoarsePoints', 180, @(x)isnumeric(x) && isscalar(x) && x >= 20);
p.addParameter('ReferencePoints', 300, @(x)isnumeric(x) && isscalar(x) && x >= 20);
p.addParameter('Repeats', 1, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
p.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

cases = buildCases();
rows = repmat(emptyRow(), 0, 1);

fprintf('\nAE adaptive coarse-rescue matrix\n');
fprintf('================================\n');
fprintf('Cases: %d | coarse: %d | rescue/reference: %d\n\n', ...
    numel(cases), opt.CoarsePoints, opt.ReferencePoints);

for iCase = 1:numel(cases)
    params = cases(iCase).params;

    coarseOptions = aeDefaultSweepOptions("Fast");
    coarseOptions.atlasNumYPoints = opt.CoarsePoints;
    coarse = runSolver(params, coarseOptions, opt.Repeats);

    referenceOptions = aeDefaultSweepOptions("Fast");
    referenceOptions.atlasNumYPoints = opt.ReferencePoints;
    reference = runSolver(params, referenceOptions, opt.Repeats);

    coarseCmp = compareResults(coarse.result, reference.result);
    rescueUsed = nnz(coarse.result.validMask) < numel(coarse.result.validMask);
    coarseUnsafe = isUnsafe(coarseCmp);

    if rescueUsed
        adaptiveResult = reference.result;
        adaptiveSeconds = coarse.seconds + reference.seconds;
    else
        adaptiveResult = coarse.result;
        adaptiveSeconds = coarse.seconds;
    end
    adaptiveCmp = compareResults(adaptiveResult, reference.result);

    row = emptyRow();
    row.Case = cases(iCase).name;
    row.CoarseSeconds = coarse.seconds;
    row.ReferenceSeconds = reference.seconds;
    row.AdaptiveSeconds = adaptiveSeconds;
    row.AdaptiveSpeedupVsReference = reference.seconds / adaptiveSeconds;
    row.RescueUsed = rescueUsed;
    row.CoarseUnsafe = coarseUnsafe;
    row.FalseNegative = coarseUnsafe && ~rescueUsed;
    row.FalsePositive = ~coarseUnsafe && rescueUsed;
    row.CoarseValidFraction = nnz(coarse.result.validMask) / numel(coarse.result.validMask);
    row.CoarseValidMaskMismatchCount = coarseCmp.validMismatch;
    row.CoarseBranchFrequencyMismatchCount = coarseCmp.branchFrequencyMismatch;
    row.CoarseMaxAbsCpDiff_mps = coarseCmp.maxAbsCp;
    row.AdaptiveValidMaskMismatchCount = adaptiveCmp.validMismatch;
    row.AdaptiveBranchFrequencyMismatchCount = adaptiveCmp.branchFrequencyMismatch;
    row.AdaptiveMaxAbsCpDiff_mps = adaptiveCmp.maxAbsCp;
    rows(end+1,1) = row; %#ok<AGROW>

    fprintf('%-28s | rescue %d | coarseUnsafe %d | falseNeg %d | adaptive %.2fx\n', ...
        row.Case, row.RescueUsed, row.CoarseUnsafe, row.FalseNegative, ...
        row.AdaptiveSpeedupVsReference);
end

summary = struct2table(rows);

fprintf('\nFalse negatives: %d/%d\n', nnz(summary.FalseNegative), height(summary));
fprintf('False positives: %d/%d\n', nnz(summary.FalsePositive), height(summary));
fprintf('Rescue cases:    %d/%d\n', nnz(summary.RescueUsed), height(summary));
fprintf('Median adaptive speedup: %.3fx\n', median(summary.AdaptiveSpeedupVsReference));
fprintf('Min adaptive speedup:    %.3fx\n', min(summary.AdaptiveSpeedupVsReference));

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'acoustoelastic_iop_hgo', ...
        'diagnostics', 'adaptive_rescue_matrix');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    outputFile = fullfile(outputFolder, 'ae_adaptive_rescue_matrix.csv');
    writetable(summary, outputFile);
    fprintf('\nSaved %s\n', outputFile);
end
end

function tf = isUnsafe(cmp)
cpTolerance_mps = 1e-4;
tf = cmp.validMismatch > 0 || cmp.finiteMismatch > 0 || ...
    cmp.branchFrequencyMismatch > 0 || cmp.fallbackMismatch > 0 || ...
    (isfinite(cmp.maxAbsCp) && cmp.maxAbsCp > cpTolerance_mps);
end

function out = runSolver(params, options, repeats)
times = nan(repeats,1);
result = [];
for r = 1:repeats
    t = tic;
    result = solveAcoustoelasticIOPHGOBranch(params, options);
    times(r) = toc(t);
end
out = struct('result', result, 'seconds', median(times));
end

function cmp = compareResults(candidate, reference)
cmp = struct();
cmp.validMismatch = nnz(candidate.validMask ~= reference.validMask);
cmp.finiteMismatch = nnz(isfinite(candidate.phaseVelocity_mps) ~= isfinite(reference.phaseVelocity_mps));
common = isfinite(candidate.phaseVelocity_mps) & isfinite(reference.phaseVelocity_mps);
if any(common)
    delta = abs(candidate.phaseVelocity_mps(common) - reference.phaseVelocity_mps(common));
    cmp.maxAbsCp = max(delta);
else
    cmp.maxAbsCp = NaN;
end

candidateFreq = selectedFrequency(candidate);
referenceFreq = selectedFrequency(reference);
commonFreq = intersect(candidateFreq, referenceFreq, 'stable');
cmp.branchFrequencyMismatch = numel(candidateFreq) + numel(referenceFreq) - 2*numel(commonFreq);
cmp.fallbackMismatch = double(fallbackUsed(candidate) ~= fallbackUsed(reference));
end

function frequency = selectedFrequency(result)
frequency = [];
if isfield(result, 'selectedBranchPoints') && ~isempty(result.selectedBranchPoints)
    frequency = sort(result.selectedBranchPoints.Frequency_Hz(:));
end
end

function tf = fallbackUsed(result)
tf = false;
if isfield(result, 'selectedBranch') && ~isempty(result.selectedBranch) && ...
        ismember('SelectionFallbackUsed', result.selectedBranch.Properties.VariableNames)
    tf = logical(result.selectedBranch.SelectionFallbackUsed(1));
elseif isfield(result, 'diagnostics') && isfield(result.diagnostics, 'fallbackOutputInvalidated')
    tf = logical(result.diagnostics.fallbackOutputInvalidated);
end
end

function cases = buildCases()
base = aeDefaultSweepParams();
base.frequency = logspace(log10(300), log10(15000), 24).';
mmHg = 133.322;

muValues = [30e3 64e3 150e3];
iopValues = [8 15 30] * mmHg;
thicknessValues = [400e-6 550e-6 700e-6];

cases = repmat(struct('name',"",'params',base), 0, 1);
for iMu = 1:numel(muValues)
    for iIOP = 1:numel(iopValues)
        for iH = 1:numel(thicknessValues)
            params = apply(base, 'mu',muValues(iMu), 'IOP',iopValues(iIOP), ...
                'thickness',thicknessValues(iH));
            name = sprintf('mu%gk_iop%g_h%gum', muValues(iMu)/1e3, ...
                iopValues(iIOP)/mmHg, thicknessValues(iH)*1e6);
            cases(end+1,1) = makeCase(name, params); %#ok<AGROW>
        end
    end
end

fiberSets = [15e3 80; 150e3 400];
for iSet = 1:size(fiberSets,1)
    for iIOP = 1:numel(iopValues)
        params = apply(base, 'k1',fiberSets(iSet,1), 'k2',fiberSets(iSet,2), ...
            'IOP',iopValues(iIOP));
        name = sprintf('fiber%gk_k2%g_iop%g', fiberSets(iSet,1)/1e3, ...
            fiberSets(iSet,2), iopValues(iIOP)/mmHg);
        cases(end+1,1) = makeCase(name, params); %#ok<AGROW>
    end
end
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
row = struct('Case',"", 'CoarseSeconds',NaN, 'ReferenceSeconds',NaN, ...
    'AdaptiveSeconds',NaN, 'AdaptiveSpeedupVsReference',NaN, ...
    'RescueUsed',false, 'CoarseUnsafe',false, 'FalseNegative',false, ...
    'FalsePositive',false, 'CoarseValidFraction',NaN, ...
    'CoarseValidMaskMismatchCount',0, 'CoarseBranchFrequencyMismatchCount',0, ...
    'CoarseMaxAbsCpDiff_mps',NaN, 'AdaptiveValidMaskMismatchCount',0, ...
    'AdaptiveBranchFrequencyMismatchCount',0, 'AdaptiveMaxAbsCpDiff_mps',NaN);
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
