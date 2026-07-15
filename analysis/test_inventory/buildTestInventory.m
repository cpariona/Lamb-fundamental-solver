function [inventory, edges] = buildTestInventory(varargin)
%BUILDTESTINVENTORY Build a static inventory of tracked MATLAB tests.
%
%   inventory = buildTestInventory()
%   [inventory, edges] = buildTestInventory()
%   [inventory, edges] = buildTestInventory('WriteCsv', true)
%
% The parser reads Git-tracked MATLAB source and never executes test files.
% CSV writing is opt-in. Results use repository-relative forward-slash paths,
% stable columns, and deterministic path ordering.

p = inputParser;
addParameter(p, 'WriteCsv', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
parse(p, varargin{:});

repoRoot = findRepositoryRoot(mfilename('fullpath'));
testPaths = gitTrackedFiles(repoRoot, {'tests/*.m', 'tests/**/*.m'});
testPaths = sort(unique(testPaths));

sources = strings(numel(testPaths), 1);
entrypoints = strings(numel(testPaths), 1);
fileTypes = strings(numel(testPaths), 1);
for i = 1:numel(testPaths)
    sources(i) = string(fileread(fullfile(repoRoot, nativePath(testPaths(i)))));
    [~, name] = fileparts(testPaths(i));
    entrypoints(i) = string(name);
    fileTypes(i) = classifyFileType(testPaths(i), entrypoints(i), sources(i));
end

edges = buildEdges(testPaths, entrypoints, fileTypes, sources);
maintainedRunnerPaths = testPaths(fileTypes == "runner" & ...
    (startsWith(testPaths, "tests/runners/") | testPaths == "tests/run_main_gui_export_tests.m"));
runnerMemberships = computeRunnerMemberships(testPaths, fileTypes, maintainedRunnerPaths, edges);
runAllReachable = reachableTests("tests/runners/run_all_smoke_tests.m", edges, testPaths, fileTypes);

maintainedText = string(fileread(fullfile(repoRoot, 'docs', 'repository', 'maintained_entrypoints.md')));
readmeText = string(fileread(fullfile(repoRoot, 'tests', 'README.md')));

rows = repmat(emptyInventoryRow(), numel(testPaths), 1);
for i = 1:numel(testPaths)
    path = testPaths(i);
    entrypoint = entrypoints(i);
    source = sources(i);
    fileType = fileTypes(i);
    directEdges = edges(edges.CalleePath == path & edges.DirectOrDynamic ~= "reference_only", :);
    directRunnerEdges = directEdges(startsWith(directEdges.CallerPath, "tests/runners/") | ...
        directEdges.CallerPath == "tests/run_main_gui_export_tests.m", :);
    memberships = runnerMemberships{i};
    isWrapper = fileType == "compatibility_wrapper";
    wrapperTarget = "";
    if isWrapper
        target = edges(edges.CallerPath == path & edges.EdgeType == "wrapper_to_runner", :);
        if ~isempty(target)
            wrapperTarget = target.CalleePath(1);
        end
    end
    category = classifyCategory(path, entrypoint, fileType, source);
    likelyNumerical = hasNumericalIndicators(source);
    likelyHeavy = hasHeavyIndicators(path, entrypoint, category, source);
    documented = contains(maintainedText, entrypoint) || contains(readmeText, path) || ...
        contains(readmeText, entrypoint);
    dynamicRisk = classifyDynamicRisk(path, fileType, source, isempty(directEdges));
    [action, confidence, notes] = recommendation(path, entrypoint, fileType, category, likelyHeavy);

    rows(i).Path = path;
    rows(i).Entrypoint = entrypoint;
    rows(i).FileType = fileType;
    rows(i).OwningArea = classifyOwningArea(path);
    rows(i).ModelOrSurface = classifyModelOrSurface(path, entrypoint);
    rows(i).Category = category;
    rows(i).IsRootLevel = count(path, "/") == 1;
    rows(i).IsCompatibilityWrapper = isWrapper;
    rows(i).WrapperTarget = wrapperTarget;
    rows(i).DirectCallers = joinStable(directEdges.CallerPath);
    rows(i).DirectRunnerCount = numel(unique(directRunnerEdges.CallerPath));
    rows(i).TransitiveRunnerCount = numel(memberships);
    rows(i).RunnerMembership = joinStable(memberships);
    rows(i).ReachableFromRunAllSmoke = any(runAllReachable == path);
    rows(i).DocumentedAsMaintained = documented;
    rows(i).LikelyNumerical = likelyNumerical;
    rows(i).LikelyHeavy = likelyHeavy;
    rows(i).DynamicInvocationRisk = dynamicRisk;
    rows(i).RecommendedAction = action;
    rows(i).Confidence = confidence;
    rows(i).Evidence = buildEvidence(path, fileType, category, directEdges, memberships, source);
    rows(i).Notes = notes;
end

inventory = struct2table(rows);
inventory = sortrows(inventory, 'Path');
edges = sortrows(edges, {'CallerPath', 'CalleePath', 'EdgeType'});

if logical(p.Results.WriteCsv)
    outputFolder = fullfile(repoRoot, 'analysis', 'test_inventory');
    writetable(inventory, fullfile(outputFolder, 'test_inventory.csv'));
    writetable(edges, fullfile(outputFolder, 'runner_edges.csv'));
end
end

function row = emptyInventoryRow()
row = struct( ...
    'Path', "", 'Entrypoint', "", 'FileType', "", 'OwningArea', "", ...
    'ModelOrSurface', "", 'Category', "", 'IsRootLevel', false, ...
    'IsCompatibilityWrapper', false, 'WrapperTarget', "", 'DirectCallers', "", ...
    'DirectRunnerCount', 0, 'TransitiveRunnerCount', 0, 'RunnerMembership', "", ...
    'ReachableFromRunAllSmoke', false, 'DocumentedAsMaintained', false, ...
    'LikelyNumerical', false, 'LikelyHeavy', false, 'DynamicInvocationRisk', "", ...
    'RecommendedAction', "", 'Confidence', "", 'Evidence', "", 'Notes', "");
end

function root = findRepositoryRoot(anchor)
folder = fileparts(anchor);
while true
    if isfolder(fullfile(folder, '.git')) && isfolder(fullfile(folder, 'tests'))
        root = folder;
        return;
    end
    parent = fileparts(folder);
    if strcmp(parent, folder)
        error('buildTestInventory:RepositoryRootNotFound', ...
            'Could not locate the repository root from %s.', anchor);
    end
    folder = parent;
end
end

function paths = gitTrackedFiles(root, patterns)
quotedPatterns = strings(size(patterns));
for i = 1:numel(patterns)
    quotedPatterns(i) = '"' + string(patterns{i}) + '"';
end
command = sprintf('git -C "%s" ls-files -- %s', root, strjoin(quotedPatterns, ' '));
[status, output] = system(command);
if status ~= 0
    error('buildTestInventory:GitLsFilesFailed', ...
        'git ls-files failed with status %d: %s', status, output);
end
paths = string(splitlines(strtrim(string(output))));
paths(paths == "") = [];
paths = replace(paths, "\", "/");
end

function path = nativePath(path)
path = char(replace(string(path), "/", string(filesep)));
end

function fileType = classifyFileType(path, entrypoint, source)
if contains(source, "runRepositoryTestRunner") && ...
        (count(path, "/") == 1 || startsWith(path, "tests/fitting/"))
    fileType = "compatibility_wrapper";
elseif startsWith(path, "tests/runners/") || startsWith(entrypoint, "run_")
    fileType = "runner";
elseif any(entrypoint == ["assertFitRecovery", "runRepositoryTestRunner", "testRepositoryRoot"])
    fileType = "helper";
elseif startsWith(entrypoint, "test_")
    fileType = "test";
else
    fileType = "unknown";
end
end

function edges = buildEdges(paths, entrypoints, fileTypes, sources)
edgeRows = repmat(emptyEdgeRow(), 0, 1);
canonicalPaths = strings(size(entrypoints));
uniqueNames = unique(entrypoints);
for i = 1:numel(uniqueNames)
    name = uniqueNames(i);
    matches = find(entrypoints == name);
    runnerMatch = matches(startsWith(paths(matches), "tests/runners/"));
    if ~isempty(runnerMatch)
        canonicalPaths(matches) = paths(runnerMatch(1));
    else
        canonicalPaths(matches) = paths(matches(1));
    end
end

for i = 1:numel(paths)
    callerPath = paths(i);
    callerName = entrypoints(i);
    source = sources(i);
    executable = executableText(source);

    if fileTypes(i) == "compatibility_wrapper"
        targetName = string(regexp(char(source), ...
            'runRepositoryTestRunner\s*\([^,]+,\s*''([^'']+)''', 'tokens', 'once'));
        if ~isempty(targetName)
            targetIndex = find(entrypoints == targetName & startsWith(paths, "tests/runners/"), 1);
            if ~isempty(targetIndex)
                edgeRows(end+1, 1) = makeEdge(callerPath, callerName, paths(targetIndex), ...
                    entrypoints(targetIndex), "wrapper_to_runner", "dynamic", "high", ...
                    "runRepositoryTestRunner delegates to the same-named maintained runner"); %#ok<AGROW>
            end
        end
        continue;
    end

    for j = 1:numel(uniqueNames)
        targetName = uniqueNames(j);
        targetPath = canonicalPaths(find(entrypoints == targetName, 1));
        if targetPath == callerPath
            continue;
        end
        tokenPattern = ['(?<![A-Za-z0-9_])', regexptranslate('escape', char(targetName)), ...
            '(?![A-Za-z0-9_])'];
        explicit = ~isempty(regexp(char(executable), tokenPattern, 'once'));
        dynamicPath = contains(source, targetName) && contains(source, "runtests") && ~explicit;
        referenceOnly = contains(source, targetName) && ...
            (contains(source, "which(") || contains(source, "which (")) && ~explicit;
        if explicit
            targetType = fileTypes(find(paths == targetPath, 1));
            edgeType = inferEdgeType(fileTypes(i), targetType);
            edgeRows(end+1, 1) = makeEdge(callerPath, callerName, targetPath, targetName, ...
                edgeType, "direct", "high", "entrypoint token in executable MATLAB source"); %#ok<AGROW>
        elseif dynamicPath
            targetType = fileTypes(find(paths == targetPath, 1));
            edgeType = inferEdgeType(fileTypes(i), targetType);
            edgeRows(end+1, 1) = makeEdge(callerPath, callerName, targetPath, targetName, ...
                edgeType, "dynamic", "medium", "path string passed through runtests"); %#ok<AGROW>
        elseif referenceOnly
            edgeRows(end+1, 1) = makeEdge(callerPath, callerName, targetPath, targetName, ...
                "dynamic_candidate", "reference_only", "low", "which/path reference does not prove execution"); %#ok<AGROW>
        end
    end
end
if isempty(edgeRows)
    edges = struct2table(repmat(emptyEdgeRow(), 0, 1));
else
    edges = unique(struct2table(edgeRows), 'rows', 'stable');
end
end

function text = executableText(source)
text = regexprep(char(source), '(?s)%\{.*?%\}', ' ');
lines = regexp(text, '\r?\n', 'split');
for i = 1:numel(lines)
    lines{i} = regexprep(lines{i}, '%.*$', ' ');
    lines{i} = regexprep(lines{i}, '''(?:''''|[^''])*''', ' ');
    lines{i} = regexprep(lines{i}, '"(?:""|[^"])*"', ' ');
end
text = string(strjoin(lines, newline));
end

function edgeType = inferEdgeType(callerType, targetType)
if callerType == "runner" && targetType == "runner"
    edgeType = "runner_to_runner";
elseif callerType == "runner" && targetType == "test"
    edgeType = "runner_to_test";
elseif callerType == "test" && targetType == "helper"
    edgeType = "test_to_helper";
elseif callerType == "runner" && targetType == "helper"
    edgeType = "test_to_helper";
else
    edgeType = "dynamic_candidate";
end
end

function row = emptyEdgeRow()
row = struct('CallerPath', "", 'CallerEntrypoint', "", 'CalleePath', "", ...
    'CalleeEntrypoint', "", 'EdgeType', "", 'DirectOrDynamic', "", ...
    'Confidence', "", 'Evidence', "");
end

function row = makeEdge(callerPath, callerName, calleePath, calleeName, edgeType, direct, confidence, evidence)
row = struct('CallerPath', callerPath, 'CallerEntrypoint', callerName, ...
    'CalleePath', calleePath, 'CalleeEntrypoint', calleeName, ...
    'EdgeType', edgeType, 'DirectOrDynamic', direct, ...
    'Confidence', confidence, 'Evidence', evidence);
end

function memberships = computeRunnerMemberships(paths, fileTypes, runnerPaths, edges)
memberships = cell(numel(paths), 1);
for i = 1:numel(runnerPaths)
    reached = reachableTests(runnerPaths(i), edges, paths, fileTypes);
    for j = 1:numel(reached)
        index = find(paths == reached(j), 1);
        memberships{index}(end+1, 1) = runnerPaths(i);
    end
end
for i = 1:numel(memberships)
    memberships{i} = sort(unique(string(memberships{i})));
end
end

function reachedTests = reachableTests(startPath, edges, paths, fileTypes)
reachedTests = strings(0, 1);
if ~any(paths == startPath)
    return;
end
queue = string(startPath);
visited = strings(0, 1);
while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    if any(visited == current)
        continue;
    end
    visited(end+1, 1) = current; %#ok<AGROW>
    outgoing = edges(edges.CallerPath == current & edges.DirectOrDynamic ~= "reference_only", :);
    for i = 1:height(outgoing)
        target = outgoing.CalleePath(i);
        targetIndex = find(paths == target, 1);
        if isempty(targetIndex)
            continue;
        end
        if fileTypes(targetIndex) == "test"
            reachedTests(end+1, 1) = target; %#ok<AGROW>
        elseif fileTypes(targetIndex) == "runner" || fileTypes(targetIndex) == "compatibility_wrapper"
            queue(end+1, 1) = target; %#ok<AGROW>
        end
    end
end
reachedTests = sort(unique(reachedTests));
end

function area = classifyOwningArea(path)
parts = split(path, "/");
if numel(parts) == 2
    area = "root";
else
    area = parts(2);
end
end

function surface = classifyModelOrSurface(path, entrypoint)
pathLower = lower(path);
nameLower = lower(entrypoint);
if contains(pathLower, "/execution_profiles/") || contains(nameLower, "execution_profile")
    surface = "execution_profiles";
elseif contains(pathLower, "/models/mrlfe/") || contains(nameLower, "mrlfe")
    surface = "mrlfe";
elseif contains(pathLower, "/models/acoustoelastic_iop_hgo/") || contains(nameLower, "acoustoelastic") || startsWith(nameLower, "test_ae_")
    surface = "acoustoelastic_iop_hgo";
elseif contains(pathLower, "/models/rayleigh_lamb/") || contains(nameLower, "rayleigh_lamb") || startsWith(nameLower, "test_rl_")
    surface = "rayleigh_lamb";
elseif contains(pathLower, "/sweeps/") || contains(nameLower, "sweep")
    surface = "sweeps";
elseif contains(pathLower, "/fitting/") || contains(nameLower, "fit")
    surface = "fitting";
elseif contains(pathLower, "/gui/") || contains(nameLower, "gui") || contains(nameLower, "main_gui")
    surface = "gui";
else
    surface = "shared";
end
end

function category = classifyCategory(path, entrypoint, fileType, source)
name = lower(entrypoint);
if fileType == "helper"
    category = "helper";
elseif contains(name, "benchmark") || contains(name, "performance")
    category = "benchmark_performance";
elseif contains(name, "validation_matrix") || contains(name, "end_to_end") || ...
        contains(name, "fit_validation") || entrypoint == "run_all_smoke_tests"
    category = "integration";
elseif contains(name, "characterization")
    category = "characterization";
elseif contains(name, "regression") || contains(name, "fit_synthetic") || ...
        contains(name, "fit_public_solver_parameter") || contains(name, "branch_consistency") || ...
        contains(name, "fit_fast_options_quality") || contains(name, "etas_fit_forward_cache")
    category = "regression";
elseif contains(name, "smoke")
    category = "smoke";
elseif contains(name, "contract") || contains(name, "policy") || contains(name, "defaults") || ...
        contains(name, "schema") || contains(name, "naming") || contains(name, "normalization") || ...
        contains(name, "cleanup") || contains(name, "metadata") || contains(name, "resolvers") || ...
        contains(name, "entrypoints") || contains(name, "grid") || contains(name, "termination")
    category = "contract";
elseif contains(name, "diagnostic") && fileType ~= "runner"
    category = "diagnostic";
elseif fileType == "runner" || fileType == "compatibility_wrapper"
    category = "integration";
elseif contains(lower(source), "tic") && contains(lower(source), "toc")
    category = "benchmark_performance";
else
    category = "contract";
end
end

function tf = hasNumericalIndicators(source)
patterns = ["mrlfeSolve", "rlComputeFundamentalLambModes", "solveAcoustoelastic", ...
    "guiRunFit", "guiRunSweep", "FitDispersionData", "EvaluateFitModel", ...
    "fminsearch", "lsqnonlin"];
tf = any(contains(source, patterns, 'IgnoreCase', true));
end

function tf = hasHeavyIndicators(path, entrypoint, category, source)
name = lower(entrypoint);
tf = category == "benchmark_performance" || ...
    contains(name, "validation_matrix") || contains(name, "fit_validation") || ...
    contains(name, "fit_synthetic") || contains(name, "production_core_characterization") || ...
    contains(name, "surface_integration") || contains(name, "fit_curve_metadata") || ...
    contains(name, "main_gui_characterization") || contains(name, "sweep_point_characterization") || ...
    (contains(lower(source), "guiRunFit") && contains(lower(source), "for ")) || ...
    path == "tests/runners/run_all_smoke_tests.m" || ...
    path == "tests/runners/run_core_smoke_tests.m" || ...
    path == "tests/runners/run_gui_smoke_tests.m" || ...
    path == "tests/runners/run_acoustoelastic_smoke_tests.m" || ...
    path == "tests/runners/run_mrlfe_production_core_tests.m" || ...
    path == "tests/runners/run_execution_profile_end_to_end_tests.m" || ...
    path == "tests/runners/run_fit_validation_tests.m";
end

function risk = classifyDynamicRisk(path, fileType, source, noCallers)
if contains(source, "runtests") || contains(source, "feval") || contains(source, "str2func") || contains(source, "eval(")
    risk = "high";
elseif fileType == "compatibility_wrapper" || (noCallers && startsWith(path, "tests/"))
    risk = "medium";
elseif contains(source, "which(") || contains(source, "run(")
    risk = "medium";
else
    risk = "low";
end
end

function [action, confidence, notes] = recommendation(path, entrypoint, fileType, category, likelyHeavy)
action = "retain";
confidence = "high";
notes = "";
if fileType == "compatibility_wrapper"
    action = "document";
    notes = "Preserve public command compatibility; compare wrapper inventory with tests/README.md.";
elseif path == "tests/run_main_gui_export_tests.m"
    action = "document";
    confidence = "medium";
    notes = "Standalone root runner, not a wrapper; decide whether it is an intentional public command.";
elseif likelyHeavy && fileType == "runner"
    action = "split_later";
    notes = "Keep behavior unchanged here; separate quick and extended membership in a future PR.";
elseif fileType == "unknown"
    action = "investigate";
    confidence = "low";
end
end

function evidence = buildEvidence(path, fileType, category, directEdges, memberships, source)
pieces = ["tracked by git", "path=" + path, "type=" + fileType, "category=" + category];
if ~isempty(directEdges)
    pieces(end+1) = "direct callers=" + string(numel(unique(directEdges.CallerPath)));
else
    pieces(end+1) = "no executable static caller found";
end
pieces(end+1) = "runner memberships=" + string(numel(memberships));
if contains(source, "tic") && contains(source, "toc")
    pieces(end+1) = "contains tic/toc";
end
if contains(source, "runtests") || contains(source, "eval(") || contains(source, "feval")
    pieces(end+1) = "contains dynamic invocation indicator";
end
evidence = strjoin(pieces, "; ");
end

function value = joinStable(values)
values = sort(unique(string(values)));
values(values == "") = [];
value = strjoin(values, ";");
end
