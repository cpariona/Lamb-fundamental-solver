function test_repository_naming_contract()
%TEST_REPOSITORY_NAMING_CONTRACT Guard maintained repository naming rules.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
trackedPaths = trackedMatlabPaths(repoRoot);
names = erase(string({trackedPaths.name}), ".m");

assertFilenameFunctionAgreement(repoRoot, trackedPaths);
assertExampleTerms(trackedPaths);
assertPrefixContracts(repoRoot, trackedPaths);
assertDocumentedEntrypoints(repoRoot, names);
assertPhase3Names(names);

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
    if startsWith(path, "models/mrlfe/")
        assert(startsWith(name, "mrlfe"), 'mRLFE model function lacks mrlfe prefix: %s', path);
    elseif startsWith(path, "models/rayleigh_lamb/")
        assert(startsWith(name, "rl"), 'Rayleigh-Lamb model function lacks rl prefix: %s', path);
    elseif startsWith(path, "models/acoustoelastic_iop_hgo/")
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

function assertDocumentedEntrypoints(repoRoot, trackedNames)
docPath = fullfile(repoRoot, 'docs', 'repository', 'maintained_entrypoints.md');
documented = matlabFenceIdentifiers(fileread(docPath));
wrapperNames = [ ...
    "run_acoustoelastic_smoke_tests", "run_all_smoke_tests", ...
    "run_core_smoke_tests", "run_gui_smoke_tests", ...
    "run_mrlfe_smoke_tests"];

for i = 1:numel(documented)
    count = nnz(trackedNames == documented(i));
    expected = 1 + any(wrapperNames == documented(i));
    assert(count == expected, ...
        'Documented entrypoint %s has %d tracked definitions; expected %d.', ...
        documented(i), count, expected);
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
    if inMatlab && ~isempty(regexp(line, '^[A-Za-z]\w*$', 'once'))
        names(end + 1, 1) = line; %#ok<AGROW>
    end
end
assert(numel(names) == numel(unique(names)), ...
    'maintained_entrypoints.md contains a duplicate canonical MATLAB identifier.');
end

function assertPhase3Names(trackedNames)
canonical = [ ...
    "run_default_mrlfe", "validate_mrlfe_targeted_grid", ...
    "diagnose_modal_atlas", "validate_idA0_score_grid", ...
    "validate_idA0_grid", "diagnose_idA0_plausibility", ...
    "mrlfeDefaultInternalParameters", "mrlfeObjectiveResidual", ...
    "test_mrlfe_maintained_route_characterization", ...
    "test_mrlfe_removed_routes_absent", ...
    "test_mrlfe_removed_route_flags_absent", ...
    "test_execution_profile_normalization_contract"];
for i = 1:numel(canonical)
    assert(nnz(trackedNames == canonical(i)) == 1, ...
        'Canonical Phase 3 name must have one tracked definition: %s', canonical(i));
end
assert(nnz(trackedNames == "run_mrlfe_route_integrity_tests") == 1, ...
    'The specialized route-integrity command must have one canonical runner definition.');

removed = [ ...
    "run_mrlfe_prototype", "run_mrlfe_targeted_grid_validation", ...
    "diagnose_acoustoelastic_iop_hgo_modal_atlas", ...
    "validate_acoustoelastic_iop_hgo_branch_identity_score_grid", ...
    "validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid", ...
    "diagnose_idA0_plausibility_impl", "defaultMRLFEParams", ...
    "objectiveMRLFEResidual", "test_mrlfe_legacy_cleanup_characterization", ...
    "test_mrlfe_no_legacy_routes", "test_mrlfe_no_legacy_route_flags", ...
    "run_mrlfe_legacy_cleanup_tests", "test_execution_profile_cleanup_contract", ...
    "run_execution_profile_cleanup_tests"];
for i = 1:numel(removed)
    assert(~any(trackedNames == removed(i)), ...
        'Removed Phase 3 name still has a tracked definition: %s', removed(i));
    assert(isempty(which(removed(i))), ...
        'Removed Phase 3 name still resolves on the MATLAB path: %s', removed(i));
end
end
