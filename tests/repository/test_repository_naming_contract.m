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
retiredNames = retiredFunctionNames();
assertRetiredFilenamesAbsent(names, retiredNames);
assertRetiredExecutableReferencesAbsent(repoRoot, trackedPaths, retiredNames);

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
for i = 1:numel(paths)
    path = paths(i).relative;
    name = paths(i).name;
    firstCode = firstCodeLine(fileread(fullfile(repoRoot, path)));

    if startsWith(path, "src/+lamb/+models/+mrlfe/") && startsWith(strtrim(firstCode), "function")
        assert(startsWith(name, "mrlfe"), 'mRLFE model function lacks mrlfe prefix: %s', path);
    elseif startsWith(path, "src/+lamb/+models/+rayleigh_lamb/") && startsWith(strtrim(firstCode), "function")
        assert(startsWith(name, "rl"), 'Rayleigh-Lamb model function lacks rl prefix: %s', path);
    elseif startsWith(path, "src/+lamb/+models/+acoustoelastic_iop_hgo/") && startsWith(strtrim(firstCode), "function")
        assert(startsWith(name, "ae"), 'AE model function lacks ae prefix: %s', path);
    elseif startsWith(path, "studies/sensitivity/acoustoelastic_iop_hgo/") || ...
            startsWith(path, "studies/solver_diagnostics/acoustoelastic_iop_hgo/")
        assert(startsWith(name, "ae"), 'AE study file lacks ae prefix: %s', path);
    elseif startsWith(path, "studies/sensitivity/mrlfe/") || ...
            startsWith(path, "studies/solver_diagnostics/mrlfe/")
        assert(startsWith(name, "mrlfe"), 'mRLFE study file lacks mrlfe prefix: %s', path);
    elseif startsWith(path, "studies/sensitivity/rayleigh_lamb/")
        assert(startsWith(name, "rl"), 'Rayleigh-Lamb study file lacks rl prefix: %s', path);
    elseif startsWith(path, "examples/acoustoelastic_iop_hgo/")
        assert(startsWith(name, "ae"), 'AE example file lacks ae prefix: %s', path);
    elseif startsWith(path, "examples/mrlfe/")
        assert(startsWith(name, "mrlfe"), 'mRLFE example file lacks mrlfe prefix: %s', path);
    elseif startsWith(path, "examples/rayleigh_lamb/")
        assert(startsWith(name, "rl"), 'Rayleigh-Lamb example file lacks rl prefix: %s', path);
    elseif startsWith(path, "tests/models/acoustoelastic_iop_hgo/")
        assert(startsWith(name, "test_ae_"), 'AE model test lacks test_ae_ prefix: %s', path);
    elseif startsWith(path, "tests/models/mrlfe/")
        assert(startsWith(name, "test_mrlfe_"), 'mRLFE model test lacks test_mrlfe_ prefix: %s', path);
    elseif startsWith(path, "tests/models/rayleigh_lamb/")
        assert(startsWith(name, "test_rl_"), 'Rayleigh-Lamb model test lacks test_rl_ prefix: %s', path);
    elseif startsWith(path, "app/execution_profiles/") || startsWith(path, "app/utilities/")
        allowed = startsWith(name, "gui") || startsWith(name, "ae") || ...
            startsWith(name, "mrlfe") || startsWith(name, "rl");
        assert(allowed, 'Neutral app function has no ownership prefix: %s', path);
    end
end
end

function assertDocumentedEntrypoints(repoRoot, trackedPaths, trackedNames)
docPath = fullfile(repoRoot, 'docs', 'architecture.md');
documented = matlabFenceIdentifiers(fileread(docPath));
assert(~isempty(documented), ...
    'docs/architecture.md must document at least one MATLAB entrypoint.');
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
    'docs/architecture.md contains a duplicate canonical MATLAB identifier.');
end

function assertPermanentValidationNames(paths, trackedNames)
canonical = [ ...
    "mrlfeRunDefault", "mrlfeInvestigateGridPresets", ...
    "aeDiagnoseModalAtlas", "mrlfeDefaultInternalParameters", ...
    "mrlfeObjectiveResidual", "test_mrlfe_maintained_route_characterization", ...
    "test_mrlfe_canonical_route_contract", ...
    "test_mrlfe_configuration_ownership_contract", ...
    "test_execution_profile_normalization_contract", "test_execution_profile_contract", ...
    "run_repository_hygiene_tests", "run_quick_contract_tests", ...
    "run_quick_smoke_tests", "run_numerical_regression_tests", ...
    "run_extended_integration_tests", "run_performance_and_benchmark_tests"];
for i = 1:numel(canonical)
    assert(nnz(trackedNames == canonical(i)) == 1, ...
        'Canonical maintained name must have one tracked definition: %s', canonical(i));
end

forbidden = '(?i)(^|_)(final|new|old|phase[0-9]*|migration|temporary|architecture_v2)($|_)';
for i = 1:numel(paths)
    if startsWith(paths(i).relative, "tests/")
        assert(isempty(regexp(paths(i).name, forbidden, 'once')), ...
            'Maintained test or runner has a campaign-relative name: %s', paths(i).relative);
    end
end
end

function names = retiredFunctionNames()
names = [ ...
    "solveAcoustoelasticIOPHGOBranch", "defaultAcoustoelasticIOPHGOOptions", ...
    "computeAcoustoelasticABGFromIOPHGO", "computeAcoustoelasticAlphaBetaGamma", ...
    "computeAcoustoelasticPrestressSigma", "solveAcoustoelasticHGOStretch", ...
    "buildAcoustoelasticMatrix", "aeComputeAcoustoelasticCpState", ...
    "computeAcoustoelasticSRoots", "objectiveAcoustoelasticResidual", ...
    "objectiveAcoustoelasticComplexDeterminant", "solveAcoustoelasticAtlasBranch", ...
    "solveAcoustoelasticComplexCDispersion", "solveAcoustoelasticDispersion", ...
    "solveAcoustoelasticIOPHGODispersion", ...
    "guiRunAcoustoelasticIOPHGOModel", "guiBuildAcoustoelasticIOPHGORequest", ...
    "guiBuildAcoustoelasticIOPHGOOptions", "guiRunRayleighLambModel", "guiRunMRLFEModel", ...
    "guiFitAcoustoelasticIOPHGOSolver", "guiFitRLSolver", "guiFitMRLFESolver", ...
    "guiBuildMainResultExport", "guiSaveMainResultExport", ...
    "runAcoustoelasticSensitivity", "runAcoustoelasticGridSensitivity", ...
    "buildAcoustoelasticGridSensitivityCube", "buildAcoustoelasticSensitivityPlotData", ...
    "plotAcoustoelasticSensitivity", "plotAcoustoelasticGridSensitivity", ...
    "plotAcoustoelasticGridSensitivityByAxis", "summarizeAcoustoelasticSensitivity", ...
    "summarizeAcoustoelasticGridSensitivity", "writeAcoustoelasticSensitivityOutputs", ...
    "saveAcoustoelasticStudyFigure", "deleteAcoustoelasticStudyFigure", ...
    "acoustoelasticSensitivityParameters", "acoustoelasticSensitivityOptions", ...
    "runMRLFESensitivity", "buildMRLFESensitivitySpec", "saveMRLFEStudyFigure", ...
    "writeMRLFESensitivityOutputs", "summarizeMRLFETrackingQuality", ...
    "runRayleighLambSensitivity", "buildRayleighLambSensitivitySpec", ...
    "saveRayleighLambStudyFigure", "writeRayleighLambSensitivityOutputs", ...
    "rayleighLambSensitivityParameters", "rayleighLambSensitivityOptions", ...
    "study_thickness_A0", "study_etaS_A0Like", "study_iop_A0Like", "study_mu_iop_A0Like", ...
    "run_default_mrlfe", "run_default_A0_S0", "fit_default_A0", ...
    "fit_mrlfe_A0Like", "fit_ae_atlasA0", "investigate_mrlfe_grid_presets", ...
    "diagnose_atlas_truncation", "diagnose_branch_families", ...
    "diagnose_grid_start_sensitivity", "diagnose_modal_atlas", "diagnose_sweep_reliability"];
end

function assertRetiredFilenamesAbsent(trackedNames, retiredNames)
for i = 1:numel(retiredNames)
    assert(~any(trackedNames == retiredNames(i)), ...
        'Retired filename must not reappear: %s', retiredNames(i));
end
end

function assertRetiredExecutableReferencesAbsent(repoRoot, paths, retiredNames)
for i = 1:numel(paths)
    filePath = fullfile(repoRoot, paths(i).relative);
    executable = matlabExecutableText(fileread(filePath));
    for j = 1:numel(retiredNames)
        escaped = regexptranslate('escape', char(retiredNames(j)));
        callPattern = ['(?<![A-Za-z0-9_])', escaped, '\s*\('];
        handlePattern = ['(?<![A-Za-z0-9_])@\s*', escaped, '(?![A-Za-z0-9_])'];
        assert(isempty(regexp(executable, callPattern, 'once')) && ...
                isempty(regexp(executable, handlePattern, 'once')), ...
            'Retired executable symbol %s remains in %s.', retiredNames(j), paths(i).relative);
    end
end
end

function clean = matlabExecutableText(text)
chars = char(text);
clean = repmat(' ', size(chars));
state = 0; % 0 code, 1 line comment, 2 block comment, 3 char literal, 4 string literal
i = 1;
while i <= numel(chars)
    c = chars(i);
    switch state
        case 0
            if c == '%'
                if i < numel(chars) && chars(i + 1) == '{'
                    state = 2;
                    i = i + 1;
                else
                    state = 1;
                end
            elseif c == '"'
                state = 4;
            elseif c == ''''
                if startsCharLiteral(chars, i)
                    state = 3;
                else
                    clean(i) = c;
                end
            else
                clean(i) = c;
            end
        case 1
            if c == newline
                clean(i) = c;
                state = 0;
            end
        case 2
            if c == '%' && i < numel(chars) && chars(i + 1) == '}'
                state = 0;
                i = i + 1;
            elseif c == newline
                clean(i) = c;
            end
        case 3
            if c == ''''
                if i < numel(chars) && chars(i + 1) == ''''
                    i = i + 1;
                else
                    state = 0;
                end
            elseif c == newline
                clean(i) = c;
                state = 0;
            end
        case 4
            if c == '"'
                if i < numel(chars) && chars(i + 1) == '"'
                    i = i + 1;
                else
                    state = 0;
                end
            elseif c == newline
                clean(i) = c;
                state = 0;
            end
    end
    i = i + 1;
end
end

function tf = startsCharLiteral(chars, index)
j = index - 1;
while j >= 1 && isspace(chars(j)) && chars(j) ~= newline
    j = j - 1;
end
if j < 1 || chars(j) == newline
    tf = true;
    return;
end
previous = chars(j);
stringPredecessors = ['(', '[', '{', ',', ';', '=', ':', '+', '-', '*', '/', '\', '^', '<', '>', '&', '|', '~'];
tf = any(previous == stringPredecessors);
end
