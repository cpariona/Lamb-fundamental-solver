function test_repository_naming_contract()
%TEST_REPOSITORY_NAMING_CONTRACT Guard maintained repository naming rules.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
trackedPaths = trackedMatlabPaths(repoRoot);
names = erase(string({trackedPaths.name}), ".m");
assert(numel(names) == numel(unique(lower(names))), ...
    'Tracked MATLAB filenames must be globally unique, including case-insensitive platforms.');

assertFilenameFunctionAgreement(repoRoot, trackedPaths);
assertExampleTerms(trackedPaths);
assertPrefixContracts(repoRoot, trackedPaths);
assertDocumentedEntrypoints(repoRoot, trackedPaths, names);
assertPermanentValidationNames(trackedPaths, names);

fprintf('Repository naming contract test passed.\n');
end

function paths = trackedMatlabPaths(repoRoot)
command = sprintf('git -C "%s" ls-files "*.m"', repoRoot);
[status, output] = system(command);
assert(status == 0, 'Could not enumerate tracked MATLAB files.');
relative = splitlines(string(strtrim(output)));
relative(relative == "") = [];
paths = repmat(struct('relative', "", 'name', ""), numel(relative), 1);
for i = 1:numel(relative)
    paths(i).relative = replace(relative(i), "\", "/");
    [~, name] = fileparts(paths(i).relative);
    paths(i).name = string(name);
end
end

function assertFilenameFunctionAgreement(repoRoot, paths)
for i = 1:numel(paths)
    filePath = fullfile(repoRoot, paths(i).relative);
    firstCode = firstCodeLine(fileread(filePath));
    if ~startsWith(strtrim(firstCode), "function")
        continue;
    end
    token = regexp(firstCode, ...
        '^\s*function\s+(?:(?:\[[^\]]*\]|[A-Za-z]\w*)\s*=\s*)?([A-Za-z]\w*)', ...
        'tokens', 'once');
    assert(~isempty(token), 'Could not parse top-level function declaration: %s', filePath);
    assert(strcmp(token{1}, paths(i).name), ...
        'Top-level function %s does not match filename %s.m.', token{1}, paths(i).name);
end
end

function line = firstCodeLine(text)
lines = splitlines(string(text));
inBlockComment = false;
line = "";
for i = 1:numel(lines)
    candidate = strtrim(lines(i));
    if inBlockComment
        if startsWith(candidate, "%}")
            inBlockComment = false;
        end
        continue;
    end
    if startsWith(candidate, "%{")
        inBlockComment = true;
        continue;
    end
    if candidate == "" || startsWith(candidate, "%")
        continue;
    end
    line = candidate;
    return;
end
end

function assertExampleTerms(paths)
forbidden = '(?i)(^|_)(prototype|temporary|backup|copy|final2|old|deprecated)($|_)';
for i = 1:numel(paths)
    path = paths(i).relative;
    if ~startsWith(path, "examples/")
        continue;
    end
    assert(isempty(regexp(paths(i).name, forbidden, 'once')), ...
        'Maintained example or diagnostic has a forbidden filename term: %s', path);
end
end

function assertPrefixContracts(repoRoot, paths)
aeExplicit = [ ...
    "buildAcoustoelasticMatrix", ...
    "computeAcoustoelasticSRoots", ...
    "objectiveAcoustoelasticResidual", ...
    "objectiveAcoustoelasticComplexDeterminant", ...
    "computeAcoustoelasticABGFromIOPHGO", ...
    "computeAcoustoelasticAlphaBetaGamma", ...
    "computeAcoustoelasticPrestressSigma", ...
    "solveAcoustoelasticHGOStretch"];

for i = 1:numel(paths)
    path = paths(i).relative;
    name = paths(i).name;
    firstCode = firstCodeLine(fileread(fullfile(repoRoot, path)));
    if ~startsWith(strtrim(firstCode), "function")
        continue;
    end
    if startsWith(path, "src/+lamb/+models/+mrlfe/")
        assert(startsWith(name, "mrlfe"), 'mRLFE model function lacks mrlfe prefix: %s', path);
    elseif startsWith(path, "src/+lamb/+models/+rayleigh_lamb/")
        assert(startsWith(name, "rl"), 'Rayleigh-Lamb model function lacks rl prefix: %s', path);
    elseif startsWith(path, "src/+lamb/+models/+acoustoelastic_iop_hgo/")
        allowed = startsWith(name, "ae") || startsWith(name, "solveAcoustoelastic") || ...
            startsWith(name, "defaultAcoustoelastic") || any(name == aeExplicit);
        assert(allowed, 'AE model function violates the prefix/public-API contract: %s', path);
    elseif startsWith(path, "app/shared/")
        allowed = startsWith(name, "gui") || startsWith(name, "ae") || ...
            startsWith(name, "mrlfe") || startsWith(name, "rl");
        assert(allowed, 'Shared app function has no ownership prefix: %s', path);
    end
end
end

function assertDocumentedEntrypoints(repoRoot, trackedPaths, trackedNames)
docPath = fullfile(repoRoot, 'docs', 'repository', 'maintained_entrypoints.md');
documented = matlabFenceIdentifiers(fileread(docPath));
assert(~isempty(documented), ...
    'maintained_entrypoints.md must document at least one MATLAB entrypoint.');
for i = 1:numel(documented)
    identifier = documented(i);
    if contains(identifier, ".")
        resolved = string(which(identifier));
        assert(strlength(resolved) > 0, ...
            'Documented package entrypoint %s does not resolve.', identifier);
        relative = erase(replace(resolved, "\", "/"), ...
            replace(string(repoRoot), "\", "/") + "/");
        assert(any(string({trackedPaths.relative}) == relative), ...
            'Documented package entrypoint %s does not resolve to a tracked file.', identifier);
    else
        count = nnz(trackedNames == identifier);
        assert(count == 1, ...
            'Documented entrypoint %s must have one tracked definition; found %d.', ...
            identifier, count);
    end
end
end

function names = matlabFenceIdentifiers(text)
lines = splitlines(string(text));
inMatlab = false;
names = strings(0, 1);
for i = 1:numel(lines)
    line = strtrim(lines(i));
    if line == "```matlab"
        inMatlab = true;
        continue;
    elseif startsWith(line, "```")
        inMatlab = false;
        continue;
    end
    if inMatlab && ~isempty(regexp(line, ...
            '^[A-Za-z]\w*(?:\.[A-Za-z]\w*)*$', 'once'))
        names(end + 1, 1) = line; %#ok<AGROW>
    end
end
assert(numel(names) == numel(unique(names)), ...
    'maintained_entrypoints.md contains a duplicate canonical MATLAB identifier.');
end

function assertPermanentValidationNames(paths, trackedNames)
canonical = [ ...
    "run_default_mrlfe", "validate_grid_presets", ...
    "diagnose_modal_atlas", "mrlfeDefaultInternalParameters", ...
    "mrlfeObjectiveResidual", "test_mrlfe_maintained_route_characterization", ...
    "test_mrlfe_canonical_route_contract", ...
    "test_mrlfe_configuration_ownership_contract", ...
    "test_execution_profile_normalization_contract", ...
    "run_repository_hygiene_tests", "run_quick_contract_tests", ...
    "run_quick_smoke_tests", "run_numerical_regression_tests", ...
    "run_extended_integration_tests", "run_performance_and_benchmark_tests"];
for i = 1:numel(canonical)
    assert(nnz(trackedNames == canonical(i)) == 1, ...
        'Canonical maintained name must have one tracked definition: %s', canonical(i));
end

forbidden = '(?i)(^|_)(final|new|old|phase[0-9]*|migration|temporary|architecture_v2)($|_)';
for i = 1:numel(paths)
    if startsWith(paths(i).relative, "tests/") || startsWith(paths(i).relative, "tests/runners/")
        assert(isempty(regexp(paths(i).name, forbidden, 'once')), ...
            'Maintained test or runner has a campaign-relative name: %s', paths(i).relative);
    end
end
end
