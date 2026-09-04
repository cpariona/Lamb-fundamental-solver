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
        if isempty(regexp(value, '^(?:\.\./|[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.md$', 'once'))
            continue;
        end
        resolved = fullfile(repoRoot, fileparts(documentPath), value);
    else
        resolved = fullfile(repoRoot, value);
    end
    assert(isfile(resolved), 'Documented repository file does not exist in %s: %s', documentPath, value);
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
paths = paths(arrayfun(@(p)isfile(fullfile(repoRoot, p)), paths));
end
