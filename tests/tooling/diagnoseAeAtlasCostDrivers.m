% TEMPORARY_DIAGNOSTIC
function summary = diagnoseAeAtlasCostDrivers(varargin)
%DIAGNOSEAEATLASCOSTDRIVERS Measure AE atlas performance bottlenecks.

parser = inputParser;
parser.addParameter('Repeats', 2, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

[params, options] = benchmarkCase();
methods = ["current", "scalarSvd", "cachedState"];

fprintf('\nAE atlas cost-driver diagnostic\n');
fprintf('===============================\n');
fprintf('Tracking frequencies: %d\n', numel(params.frequency));
fprintf('Atlas Cp points:       %d\n\n', options.atlasNumYPoints);

reference = runMethod(methods(1), params, options, opt.Repeats);
rows = repmat(emptyRow(), 0, 1);

for method = methods
    if method == "current"
        out = reference;
    else
        out = runMethod(method, params, options, opt.Repeats);
    end
    cmp = compareMaps(out.objectiveMap, reference.objectiveMap);
    branchCmp = compareDiscreteBranches(out.branch, reference.branch);

    row = emptyRow();
    row.Method = method;
    row.MedianSeconds = out.medianSeconds;
    row.SpeedupVsCurrent = reference.medianSeconds / out.medianSeconds;
    row.MaxAbsObjectiveDiff = cmp.maxAbs;
    row.MaxRelativeObjectiveDiff = cmp.maxRel;
    row.SelectedBranchPointMismatchCount = branchCmp.pointMismatch;
    row.SelectedRankMismatchCount = branchCmp.rankMismatch;
    row.SelectedCpMaxAbsDiff_mps = branchCmp.maxAbsCp;
    rows(end+1,1) = row; %#ok<AGROW>

    fprintf('%-12s | %.4f s | %5.2fx | max dObj %.3g | branch mismatches %d\n', ...
        method, row.MedianSeconds, row.SpeedupVsCurrent, ...
        row.MaxAbsObjectiveDiff, row.SelectedBranchPointMismatchCount);
end

summary = struct2table(rows);

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'acoustoelastic_iop_hgo', 'diagnostics', 'atlas_cost_drivers');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(summary, fullfile(outputFolder, 'ae_atlas_cost_drivers.csv'));
    fprintf('\nSaved Results/acoustoelastic_iop_hgo/diagnostics/atlas_cost_drivers/ae_atlas_cost_drivers.csv\n');
end
end

function out = runMethod(method, params, options, repeats)
builder = @(m) buildAtlasByMethod(m, params, options);
[objectiveMap, cGrid, cShear] = builder(method); %#ok<ASGLU>

times = nan(repeats,1);
for r = 1:repeats
    t = tic;
    [objectiveMap, cGrid, cShear] = builder(method);
    times(r) = toc(t);
end

branch = selectDiscreteBranch(params.frequency, objectiveMap, cGrid, cShear, options);
out = struct('objectiveMap', objectiveMap, 'branch', branch, ...
    'medianSeconds', median(times));
end

function [objectiveMap, cGrid, cShear] = buildAtlasByMethod(method, params, options)
switch method
    case "current"
        [objectiveMap, ~, cGrid, cShear] = aeBuildAtlas(params, options);
    case "scalarSvd"
        [objectiveMap, cGrid, cShear] = buildScalarSvdAtlas(params, options);
    case "cachedState"
        [objectiveMap, cGrid, cShear] = buildCachedStateAtlas(params, options);
    otherwise
        error('Unknown diagnostic method: %s', method);
end
end

function [objectiveMap, cGrid, cShear] = buildScalarSvdAtlas(params, options)
frequency = params.frequency(:).';
cShear = sqrt(params.alpha / params.rho);
yGrid = logspace(log10(options.atlasYMin), log10(options.atlasYMax), options.atlasNumYPoints);
cGrid = yGrid(:) * cShear;
objectiveMap = nan(numel(cGrid), numel(frequency));

for k = 1:numel(frequency)
    f = frequency(k);
    for j = 1:numel(cGrid)
        M = buildAcoustoelasticMatrix(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, ...
            f, cGrid(j), options);
        s = svd(M);
        sigmaMin = min(s);
        objectiveMap(j,k) = objectiveFromSigma(sigmaMin);
    end
end
end

function [objectiveMap, cGrid, cShear] = buildCachedStateAtlas(params, options)
frequency = params.frequency(:).';
cShear = sqrt(params.alpha / params.rho);
yGrid = logspace(log10(options.atlasYMin), log10(options.atlasYMax), options.atlasNumYPoints);
cGrid = yGrid(:) * cShear;
objectiveMap = nan(numel(cGrid), numel(frequency));
state = precomputeCpState(cGrid, params);

for k = 1:numel(frequency)
    f = frequency(k);
    for j = 1:numel(cGrid)
        M = buildMatrixFromState(state(j), params, f, options);
        s = svd(M);
        sigmaMin = min(s);
        objectiveMap(j,k) = objectiveFromSigma(sigmaMin);
    end
end
end

function state = precomputeCpState(cGrid, params)
template = struct('c',NaN,'s1',NaN,'s2',NaN,'xi',NaN);
state = repmat(template, numel(cGrid), 1);
for j = 1:numel(cGrid)
    c = cGrid(j);
    [s1, s2] = computeAcoustoelasticSRoots(params.alpha, params.beta, params.gamma, params.rho, c);
    state(j).c = c;
    state(j).s1 = s1;
    state(j).s2 = s2;
    state(j).xi = sqrt(complex(1 - (c^2 * params.rhoF / params.fluidBulkModulus)));
end
end

function M = buildMatrixFromState(state, params, f, options)
c = state.c;
s1 = state.s1;
s2 = state.s2;
xi = state.xi;
k = 2*pi*f/c;
kh = k * params.thickness;

M = complex(zeros(5,5));
M(1,1) = s1^2 + 1;
M(1,3) = s2^2 + 1;
M(2,2) = params.gamma*s1*(s2^2 + 1);
M(2,4) = params.gamma*s2*(s1^2 + 1);
M(2,5) = 1i*params.rhoF*c^2;
M(3,1) = 1;
M(3,3) = 1;
M(3,5) = -1i*xi;
M(4,1) = (s1^2 + 1)*cosh(s1*kh);
M(4,2) = (s1^2 + 1)*sinh(s1*kh);
M(4,3) = (s2^2 + 1)*cosh(s2*kh);
M(4,4) = (s2^2 + 1)*sinh(s2*kh);
M(5,1) = s1*(s2^2 + 1)*sinh(s1*kh);
M(5,2) = s1*(s2^2 + 1)*cosh(s1*kh);
M(5,3) = s2*(s1^2 + 1)*sinh(s2*kh);

if string(options.M54_variant) == "paper"
    M(5,4) = s2*(s1^2 + 1)*cosh(s1*kh);
else
    M(5,4) = s2*(s1^2 + 1)*cosh(s2*kh);
end

if isfield(options, 'normalizeRows') && options.normalizeRows
    for r = 1:size(M,1)
        scale = norm(M(r,:));
        if isfinite(scale) && scale > 0
            M(r,:) = M(r,:) ./ scale;
        end
    end
end
end

function value = objectiveFromSigma(sigmaMin)
if sigmaMin <= 0 || ~isfinite(sigmaMin)
    value = inf;
else
    value = log10(sigmaMin);
end
end

function branch = selectDiscreteBranch(frequency, objectiveMap, cGrid, cShear, options)
rows = [];
for k = 1:numel(frequency)
    minima = aeFindAtlasLocalMinima(cGrid, objectiveMap(:,k), cShear, options.atlasTopNMinima);
    for m = 1:height(minima)
        row = struct('Frequency_Hz',frequency(k), 'Frequency_kHz',frequency(k)/1e3, ...
            'MinRank',m, 'Cp_mps',minima.Cp_mps(m), 'y',minima.y(m), ...
            'log10y',log10(minima.y(m)), 'Objective',minima.Objective(m), ...
            'DepthRelativeToMedian',minima.DepthRelativeToMedian(m), ...
            'DepthRelativeToDeepest',minima.DepthRelativeToDeepest(m), ...
            'SpacingToNearestLogY',minima.SpacingToNearestLogY(m), 'BranchID',nan);
        rows = [rows; row]; %#ok<AGROW>
    end
end
if isempty(rows)
    branch = table();
    return;
end
minimaTable = struct2table(rows);
[minimaTable, branchTable] = aeLinkAtlasBranches(minimaTable, options);
if isempty(branchTable)
    branch = table();
    return;
end
[~, selectedBranchID] = aeSelectAtlasA0Branch(branchTable, options);
branch = sortrows(minimaTable(minimaTable.BranchID == selectedBranchID,:), 'Frequency_Hz');
end

function cmp = compareMaps(a, b)
finite = isfinite(a) & isfinite(b);
if any(finite(:))
    delta = abs(a(finite) - b(finite));
    cmp.maxAbs = max(delta);
    cmp.maxRel = max(delta ./ max(abs(b(finite)), eps));
else
    cmp.maxAbs = NaN;
    cmp.maxRel = NaN;
end
end

function cmp = compareDiscreteBranches(a, b)
cmp = struct('pointMismatch',0,'rankMismatch',0,'maxAbsCp',NaN);
if isempty(a) || isempty(b)
    cmp.pointMismatch = double(~(isempty(a) && isempty(b)));
    return;
end
[common, ia, ib] = intersect(a.Frequency_Hz, b.Frequency_Hz, 'stable'); %#ok<ASGLU>
cmp.pointMismatch = height(a) + height(b) - 2*numel(common);
cmp.rankMismatch = nnz(a.MinRank(ia) ~= b.MinRank(ib));
if ~isempty(common)
    cmp.maxAbsCp = max(abs(a.Cp_mps(ia) - b.Cp_mps(ib)));
end
end

function [params, options] = benchmarkCase()
physical = struct('R',7.8e-3, 'thickness',550e-6, 'IOP',15*133.322, ...
    'mu',64e3, 'k1',50e3, 'k2',200, 'rho',1060, 'rhoF',1000, ...
    'fluidBulkModulus',2.2e9, 'frequency',logspace(log10(300),log10(15000),24));
options = aeDefaultSweepOptions("Fast");
[alpha, beta, gamma] = computeAcoustoelasticABGFromIOPHGO( ...
    physical.IOP, physical.R, physical.thickness, physical.mu, physical.k1, physical.k2);
params = struct('alpha',alpha, 'beta',beta, 'gamma',gamma, ...
    'thickness',physical.thickness, 'rho',physical.rho, 'rhoF',physical.rhoF, ...
    'fluidBulkModulus',physical.fluidBulkModulus);
params.frequency = aeBuildInternalTrackingGrid(physical.frequency, options);
end

function row = emptyRow()
row = struct('Method',"", 'MedianSeconds',NaN, 'SpeedupVsCurrent',NaN, ...
    'MaxAbsObjectiveDiff',NaN, 'MaxRelativeObjectiveDiff',NaN, ...
    'SelectedBranchPointMismatchCount',0, 'SelectedRankMismatchCount',0, ...
    'SelectedCpMaxAbsDiff_mps',NaN);
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
