function test_repository_dependency_boundaries_contract()
%TEST_REPOSITORY_DEPENDENCY_BOUNDARIES_CONTRACT Guard source-layer direction.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
paths = gitTrackedMatlab(repoRoot);

assertLayer(repoRoot, paths, "src/+lamb/+models/", ["analysis/", "app/", "examples/", "tests/"]);
assertLayer(repoRoot, paths, "src/+lamb/+elasticity/", ["analysis/", "app/", "examples/", "tests/"]);
assertLayer(repoRoot, paths, "src/+lamb/+grids/", ["analysis/", "app/", "examples/", "tests/"]);
assertLayer(repoRoot, paths, "analysis/", ["app/", "examples/", "tests/"]);
assertLayer(repoRoot, paths, "app/", ["examples/", "tests/"]);
assertAeInternalBoundaries(repoRoot, paths);

fprintf('Repository dependency-boundary contract test passed.\n');
end

function assertAeInternalBoundaries(repoRoot, paths)
productionInternalNames = [ ...
    "lamb.models.acoustoelastic_iop_hgo.tracking.aeFindAtlasLocalMinima"; "lamb.models.acoustoelastic_iop_hgo.tracking.aeLinkAtlasBranches"; "lamb.models.acoustoelastic_iop_hgo.tracking.aeSplitAtlasBranches"; ...
    "lamb.models.acoustoelastic_iop_hgo.policies.aeSelectAtlasA0Branch"; "lamb.models.acoustoelastic_iop_hgo.policies.aeApplyAtlasA0FallbackPolicy"];
workflowPaths = paths( ...
    startsWith(paths, ["app/", "examples/"]) | ...
    startsWith(paths, [ ...
        "analysis/fitting/acoustoelastic_iop_hgo/", ...
        "analysis/sweeps/acoustoelastic_iop_hgo/"]));
assertNoCalls(repoRoot, workflowPaths, productionInternalNames, ...
    'App, workflow, and example code calls AE tracking or policy internals');

diagnosticAnalysisPaths = paths(startsWith(paths, ...
    "analysis/diagnostics/acoustoelastic_iop_hgo/") & endsWith(paths, ".m"));
diagnosticAnalysisNames = matlabNames(diagnosticAnalysisPaths);
solverPaths = paths(startsWith(paths, ...
    "src/+lamb/+models/+acoustoelastic_iop_hgo/+solvers/") & endsWith(paths, ".m"));
assertNoCalls(repoRoot, solverPaths, diagnosticAnalysisNames, ...
    'AE solver calls an analysis-layer diagnostic');

modelDiagnosticPaths = paths(startsWith(paths, ...
    "src/+lamb/+models/+acoustoelastic_iop_hgo/+diagnostics/") & endsWith(paths, ".m"));
assertNoCalls(repoRoot, modelDiagnosticPaths, productionInternalNames, ...
    'AE model diagnostic owns production tracking or branch policy');
end

function assertNoCalls(repoRoot, sourcePaths, forbiddenNames, message)
for i = 1:numel(sourcePaths)
    source = fileread(fullfile(repoRoot, sourcePaths(i)));
    executable = executableMatlabText(source);
    callTokens = string(regexp(executable, ...
        '(?<![A-Za-z0-9_])([A-Za-z]\w*)\s*\(', 'tokens'));
    if isempty(callTokens)
        callTokens = strings(0, 1);
    else
        callTokens = string([callTokens{:}]);
    end
    dynamicTokens = regexp(source, ...
        '(?:feval|str2func)\s*\(\s*[''"]([A-Za-z]\w*)[''"]', 'tokens');
    if isempty(dynamicTokens)
        dynamicTokens = strings(0, 1);
    else
        dynamicTokens = string([dynamicTokens{:}]);
    end
    offenders = intersect(unique([callTokens(:); dynamicTokens(:)]), forbiddenNames);
    assert(isempty(offenders), '%s through %s: %s', ...
        message, sourcePaths(i), strjoin(offenders, ', '));
end
end

function assertLayer(repoRoot, paths, sourcePrefix, forbiddenPrefixes)
sourcePaths = paths(startsWith(paths, sourcePrefix));
forbiddenPaths = paths(startsWith(paths, forbiddenPrefixes));
forbiddenNames = matlabNames(forbiddenPaths);

for i = 1:numel(sourcePaths)
    source = fileread(fullfile(repoRoot, sourcePaths(i)));
    executable = executableMatlabText(source);
    callTokens = string(regexp(executable, '(?<![A-Za-z0-9_])([A-Za-z]\w*)\s*\(', 'tokens'));
    if ~isempty(callTokens)
        callTokens = string([callTokens{:}]);
    end
    dynamicTokens = regexp(source, '(?:feval|str2func)\s*\(\s*[''"]([A-Za-z]\w*)[''"]', 'tokens');
    if isempty(dynamicTokens)
        dynamicTokens = strings(0, 1);
    else
        dynamicTokens = string([dynamicTokens{:}]);
    end
    offenders = intersect(unique([callTokens(:); dynamicTokens(:)]), forbiddenNames);
    assert(isempty(offenders), '%s depends on a forbidden layer through: %s', ...
        sourcePaths(i), strjoin(offenders, ', '));
end
end

function names = matlabNames(paths)
names = strings(numel(paths), 1);
for i = 1:numel(paths)
    [~, name] = fileparts(paths(i));
    names(i) = string(name);
end
names = unique(names);
end

function paths = gitTrackedMatlab(repoRoot)
[status, output] = system(sprintf('git -C "%s" ls-files "*.m"', repoRoot));
assert(status == 0, 'Could not enumerate tracked MATLAB files.');
paths = replace(splitlines(string(strtrim(output))), "\", "/");
paths(paths == "") = [];
end

function text = executableMatlabText(text)
text = regexprep(text, '%\{[\s\S]*?%\}', ' ');
text = regexprep(text, '''(?:[^'']|'''')*''', '''''');
text = regexprep(text, '"(?:[^"]|"")*"', '""');
text = regexprep(text, '%[^\r\n]*', ' ');
end
