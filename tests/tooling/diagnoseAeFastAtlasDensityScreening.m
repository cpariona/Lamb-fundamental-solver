% TEMPORARY_DIAGNOSTIC
function summary = diagnoseAeFastAtlasDensityScreening(varargin)
%DIAGNOSEAEFASTATLASDENSITYSCREENING Screen coarse AE atlas densities vs Fast=300.

p = inputParser;
p.addParameter('AtlasPoints', [80 100 120 150 180 220 260 300], ...
    @(x)isnumeric(x) && isvector(x) && all(x >= 20));
p.addParameter('Repeats', 1, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
p.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

cases = buildCases();
rows = repmat(emptyRow(), 0, 1);

fprintf('\nAE Fast atlas-density screening\n');
fprintf('================================\n');
fprintf('Cases: %d | requested frequencies: %d\n\n', numel(cases), numel(cases(1).params.frequency));

for iCase = 1:numel(cases)
    caseName = cases(iCase).name;
    params = cases(iCase).params;
    refOptions = aeDefaultSweepOptions("Fast");
    refOptions.atlasNumYPoints = 300;
    reference = runSolver(params, refOptions, opt.Repeats);

    fprintf('%s | reference %.4f s\n', caseName, reference.seconds);

    for atlasPoints = opt.AtlasPoints(:).'
        options = refOptions;
        options.atlasNumYPoints = atlasPoints;
        if atlasPoints == 300
            candidate = reference;
        else
            candidate = runSolver(params, options, opt.Repeats);
        end

        cmp = compareResults(candidate.result, reference.result);
        row = emptyRow();
        row.Case = caseName;
        row.AtlasPoints = atlasPoints;
        row.MedianSeconds = candidate.seconds;
        row.SpeedupVs300 = reference.seconds / candidate.seconds;
        row.ValidMaskMismatchCount = cmp.validMismatch;
        row.FiniteMaskMismatchCount = cmp.finiteMismatch;
        row.MaxAbsCpDiff_mps = cmp.maxAbsCp;
        row.MaxRelativeCpDiff = cmp.maxRelCp;
        row.SelectedBranchFrequencyMismatchCount = cmp.branchFrequencyMismatch;
        row.SelectedRankMismatchCount = cmp.rankMismatch;
        row.FallbackMismatch = cmp.fallbackMismatch;
        row.CandidateFallbackUsed = cmp.candidateFallbackUsed;
        row.ReferenceFallbackUsed = cmp.referenceFallbackUsed;
        rows(end+1,1) = row; %#ok<AGROW>

        fprintf('  %3d | %6.2fx | dCp %.3g | valid %d | rank %d | fallbackMismatch %d\n', ...
            atlasPoints, row.SpeedupVs300, row.MaxAbsCpDiff_mps, ...
            row.ValidMaskMismatchCount, row.SelectedRankMismatchCount, row.FallbackMismatch);
    end
end

summary = struct2table(rows);

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'acoustoelastic_iop_hgo', ...
        'diagnostics', 'fast_atlas_density_screening');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    outputFile = fullfile(outputFolder, 'ae_fast_atlas_density_screening.csv');
    writetable(summary, outputFile);
    fprintf('\nSaved %s\n', outputFile);
end
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
    cmp.maxRelCp = max(delta ./ max(abs(reference.phaseVelocity_mps(common)), eps));
else
    cmp.maxAbsCp = NaN;
    cmp.maxRelCp = NaN;
end

[candidateFreq, candidateRank] = selectedSignature(candidate);
[referenceFreq, referenceRank] = selectedSignature(reference);
[commonFreq, ia, ib] = intersect(candidateFreq, referenceFreq, 'stable');
cmp.branchFrequencyMismatch = numel(candidateFreq) + numel(referenceFreq) - 2*numel(commonFreq);
if isempty(commonFreq)
    cmp.rankMismatch = double(~(isempty(candidateFreq) && isempty(referenceFreq)));
else
    cmp.rankMismatch = nnz(candidateRank(ia) ~= referenceRank(ib));
end

cmp.candidateFallbackUsed = fallbackUsed(candidate);
cmp.referenceFallbackUsed = fallbackUsed(reference);
cmp.fallbackMismatch = double(cmp.candidateFallbackUsed ~= cmp.referenceFallbackUsed);
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
elseif isfield(result, 'diagnostics') && isfield(result.diagnostics, 'fallbackOutputInvalidated')
    tf = logical(result.diagnostics.fallbackOutputInvalidated);
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
row = struct('Case',"", 'AtlasPoints',NaN, 'MedianSeconds',NaN, 'SpeedupVs300',NaN, ...
    'ValidMaskMismatchCount',0, 'FiniteMaskMismatchCount',0, ...
    'MaxAbsCpDiff_mps',NaN, 'MaxRelativeCpDiff',NaN, ...
    'SelectedBranchFrequencyMismatchCount',0, 'SelectedRankMismatchCount',0, ...
    'FallbackMismatch',0, 'CandidateFallbackUsed',false, 'ReferenceFallbackUsed',false);
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
