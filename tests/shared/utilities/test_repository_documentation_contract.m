function test_repository_documentation_contract()
%TEST_REPOSITORY_DOCUMENTATION_CONTRACT Validate maintained documentation references.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
markdownPaths = gitTrackedMarkdown(repoRoot);

for i = 1:numel(markdownPaths)
    path = markdownPaths(i);
    text = string(fileread(fullfile(repoRoot, path)));
    assertRelativeLinks(repoRoot, path, text);
    assertCodeSpanPaths(repoRoot, path, text);
end

assertNoRetiredReferences(repoRoot, markdownPaths);
fprintf('Repository documentation contract test passed.\n');
end

function assertRelativeLinks(repoRoot, documentPath, text)
tokens = regexp(char(text), '!?(?<!\!)\[[^\]]*\]\(([^)]+)\)', 'tokens');
for i = 1:numel(tokens)
    target = string(tokens{i}{1});
    target = stripAngleBrackets(strtrim(target));
    if target == "" || startsWith(target, ["#", "http://", "https://", "mailto:"])
        continue;
    end
    target = extractBefore(target + "#", "#");
    target = replace(target, "%20", " ");
    resolved = fullfile(repoRoot, fileparts(documentPath), target);
    assert(isfile(resolved) || isfolder(resolved), ...
        'Broken relative Markdown link in %s: %s', documentPath, target);
end
end

function assertCodeSpanPaths(repoRoot, documentPath, text)
tokens = regexp(char(text), '`([^`\r\n]+)`', 'tokens');
for i = 1:numel(tokens)
    value = string(strtrim(tokens{i}{1}));
    if contains(value, ["*", "<", ">", "|", " -> "]) || startsWith(value, "Results/")
        continue;
    end
    if isempty(regexp(value, '^(?:analysis|app|docs|examples|models|tests)/.+\.(?:m|md)$', 'once'))
        if isempty(regexp(value, '^[A-Za-z0-9_.-]+\.md$', 'once'))
            continue;
        end
        resolved = fullfile(repoRoot, fileparts(documentPath), value);
    else
        resolved = fullfile(repoRoot, value);
    end
    assert(isfile(resolved), 'Documented repository file does not exist in %s: %s', documentPath, value);
end
end

function assertNoRetiredReferences(repoRoot, markdownPaths)
retired = [ ...
    "mrlfe_line_and_repository_density_audit.md", ...
    "mrlfe_line_and_repository_cleanup_report.md", ...
    "repository_hygiene_plan.md", ...
    "test_suite_runtime_evidence.md", ...
    "examples/mrlfe/diagnostics/archive/", ...
    "run_mrlfe_prototype", ...
    "run_mrlfe_targeted_grid_validation", ...
    "diagnose_acoustoelastic_iop_hgo_modal_atlas", ...
    "validate_acoustoelastic_iop_hgo_branch_identity_score_grid", ...
    "validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid", ...
    "diagnose_idA0_plausibility_impl", ...
    "defaultMRLFEParams", ...
    "objectiveMRLFEResidual", ...
    "run_mrlfe_legacy_cleanup_tests", ...
    "run_execution_profile_cleanup_tests"];
for i = 1:numel(markdownPaths)
    text = string(fileread(fullfile(repoRoot, markdownPaths(i))));
    for j = 1:numel(retired)
        assert(~contains(text, retired(j)), ...
            'Retired path or identifier remains in active documentation %s: %s', ...
            markdownPaths(i), retired(j));
    end
end
end

function value = stripAngleBrackets(value)
if startsWith(value, "<") && endsWith(value, ">")
    value = extractBetween(value, 2, strlength(value) - 1);
end
end

function paths = gitTrackedMarkdown(repoRoot)
[status, output] = system(sprintf('git -C "%s" ls-files "*.md"', repoRoot));
assert(status == 0, 'Could not enumerate tracked Markdown files.');
paths = replace(splitlines(string(strtrim(output))), "\", "/");
paths(paths == "") = [];
end
