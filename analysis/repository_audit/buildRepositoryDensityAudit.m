function outputs = buildRepositoryDensityAudit(varargin)
%BUILDREPOSITORYDENSITYAUDIT Rebuild the tracked repository audit evidence.
%
% outputs = buildRepositoryDensityAudit('WriteCsv', true, ...
%     'ValidatePaths', true)
%
% Baseline and counting rules:
%   * git ls-files is the only source of paths;
%   * paths are repository-relative and use forward slashes;
%   * LineCount counts physical text lines;
%   * MATLAB NonblankNoncommentLineCount excludes blank lines, lines whose
%     first non-whitespace character is %, and lines inside %{ ... %} blocks;
%   * other text files exclude blank lines only;
%   * binary extensions have zero text-line counts.
%
% Architectural decisions are human-reviewed rules recorded below. They are
% not inferred from call counts alone. Static callers are conservative token
% matches and DynamicCallRisk flags constructs requiring manual review.

p = inputParser;
addParameter(p, 'WriteCsv', true, @(x)islogical(x) && isscalar(x));
addParameter(p, 'ValidatePaths', false, @(x)islogical(x) && isscalar(x));
parse(p, varargin{:});
options = p.Results;

repoRoot = repositoryRoot();
paths = trackedPaths(repoRoot);
facts = buildFileFacts(repoRoot, paths);
documentation = buildDocumentationDecisions(repoRoot, facts);
decisions = buildMRLFEFileDecisions(repoRoot, facts, documentation);
composition = buildComposition(facts, documentation, decisions);
duplication = buildDuplicationMatrix();

if options.ValidatePaths
    validateRelativeTrackedPaths(repoRoot, paths, decisions, documentation);
end

if options.WriteCsv
    outputFolder = fileparts(mfilename('fullpath'));
    writetable(decisions, fullfile(outputFolder, 'mrlfe_file_decisions.csv'));
    writetable(composition, fullfile(outputFolder, 'repository_composition.csv'));
    writetable(duplication, fullfile(outputFolder, 'mrlfe_duplication_matrix.csv'));
    writetable(documentation, fullfile(outputFolder, 'documentation_decisions.csv'));
end

outputs = struct('fileDecisions', decisions, 'composition', composition, ...
    'duplication', duplication, 'documentation', documentation, 'facts', facts);
end

function root = repositoryRoot()
[status, text] = system('git rev-parse --show-toplevel');
assert(status == 0, 'repositoryAudit:GitRoot', ...
    'Unable to resolve the Git repository root.');
root = strtrim(string(text));
end

function paths = trackedPaths(repoRoot)
original = pwd;
cleanup = onCleanup(@()cd(original));
cd(repoRoot);
[status, text] = system('git ls-files');
assert(status == 0, 'repositoryAudit:GitFiles', ...
    'Unable to enumerate tracked files.');
paths = splitlines(string(text));
paths = replace(paths, '\', '/');
paths = sort(paths(strlength(paths) > 0));
assert(numel(unique(paths)) == numel(paths), ...
    'repositoryAudit:DuplicatePath', 'git ls-files returned duplicate paths.');
end

function facts = buildFileFacts(repoRoot, paths)
n = numel(paths);
Extension = strings(n,1);
TopLevelArea = strings(n,1);
LineCount = zeros(n,1);
NonblankNoncommentLineCount = zeros(n,1);
IsText = false(n,1);
for i = 1:n
    path = paths(i);
    [~,~,ext] = fileparts(path);
    Extension(i) = lower(string(ext));
    parts = split(path, '/');
    if isscalar(parts)
        TopLevelArea(i) = "root";
    else
        TopLevelArea(i) = parts(1);
    end
    IsText(i) = isTextExtension(Extension(i), path);
    if IsText(i)
        content = fileread(fullfile(repoRoot, nativePath(path)));
        lines = splitlines(string(content));
        if endsWith(content, newline) && ~isempty(lines) && lines(end) == ""
            lines(end) = [];
        end
        LineCount(i) = numel(lines);
        if Extension(i) == ".m"
            NonblankNoncommentLineCount(i) = countMatlabSourceLines(lines);
        else
            NonblankNoncommentLineCount(i) = nnz(strlength(strtrim(lines)) > 0);
        end
    end
end
facts = table(paths, Extension, TopLevelArea, LineCount, ...
    NonblankNoncommentLineCount, IsText, 'VariableNames', ...
    {'Path','Extension','TopLevelArea','LineCount', ...
    'NonblankNoncommentLineCount','IsText'});
end

function tf = isTextExtension(ext, path)
textExtensions = [".m", ".md", ".csv", ".txt", ".json", ".yml", ...
    ".yaml", ".xml", ".gitignore"];
tf = any(ext == textExtensions) || path == "LICENSE" || path == ".gitignore";
end

function count = countMatlabSourceLines(lines)
count = 0;
inBlock = false;
for i = 1:numel(lines)
    text = strtrim(lines(i));
    if inBlock
        if startsWith(text, "%}")
            inBlock = false;
        end
        continue;
    end
    if startsWith(text, "%{")
        inBlock = true;
        continue;
    end
    if text ~= "" && ~startsWith(text, "%")
        count = count + 1;
    end
end
end

function documentation = buildDocumentationDecisions(repoRoot, facts)
docs = facts(facts.Extension == ".md", :);
n = height(docs);
DocumentType = strings(n,1);
ActiveContract = false(n,1);
InboundLinks = zeros(n,1);
UniqueCurrentContent = false(n,1);
HistoricalOnly = false(n,1);
ContradictsCurrentCode = false(n,1);
Decision = strings(n,1);
ReplacementOrConsolidationTarget = strings(n,1);
Risk = strings(n,1);
Evidence = strings(n,1);

allText = strings(n,1);
for i = 1:n
    allText(i) = string(fileread(fullfile(repoRoot, nativePath(docs.Path(i)))));
end

for i = 1:n
    path = docs.Path(i);
    text = allText(i);
    [DocumentType(i), ActiveContract(i), UniqueCurrentContent(i), ...
        HistoricalOnly(i), Decision(i), ReplacementOrConsolidationTarget(i), ...
        Risk(i)] = documentDecision(path, text);
    [~,base,ext] = fileparts(path);
    token = string(base) + string(ext);
    inbound = false(n,1);
    for j = 1:n
        if i ~= j
            inbound(j) = contains(allText(j), path) || contains(allText(j), token);
        end
    end
    InboundLinks(i) = nnz(inbound);
    ContradictsCurrentCode(i) = documentContradiction(path, text);
    Evidence(i) = "tracked Markdown; " + InboundLinks(i) + ...
        " inbound Markdown references; decision reviewed against current code/tests";
end

documentation = table(docs.Path, DocumentType, ActiveContract, InboundLinks, ...
    UniqueCurrentContent, HistoricalOnly, ContradictsCurrentCode, Decision, ...
    ReplacementOrConsolidationTarget, Risk, Evidence, 'VariableNames', ...
    {'Path','DocumentType','ActiveContract','InboundLinks', ...
    'UniqueCurrentContent','HistoricalOnly','ContradictsCurrentCode','Decision', ...
    'ReplacementOrConsolidationTarget','Risk','Evidence'});
documentation = sortrows(documentation, 'Path');
end

function [type, active, uniqueCurrent, historical, decision, target, risk] = documentDecision(path, text)
pathLower = lower(path);
type = "active usage guide";
active = false;
uniqueCurrent = true;
historical = false;
decision = "retain";
target = "";
risk = "low";

if contains(pathLower, "/archive/") || startsWith(pathLower, "docs/archive/")
    type = "archived phase log";
    historical = true;
    uniqueCurrent = false;
    decision = "delete";
    risk = "low";
elseif contains(pathLower, "/audits/") || contains(pathLower, "_audit") || ...
        contains(pathLower, "audit_") || contains(pathLower, "_report") || ...
        contains(pathLower, "failure_diagnosis") || contains(pathLower, "phase1_report")
    type = "completed audit/report";
    historical = true;
    uniqueCurrent = false;
    decision = "delete";
    risk = "low";
elseif contains(pathLower, "proposal") || contains(pathLower, "cleanup.md") || ...
        contains(pathLower, "benchmark.md") && path ~= "docs/validation/mrlfe_execution_profile_benchmark.md"
    type = "historical migration evidence";
    historical = true;
    uniqueCurrent = false;
    decision = "delete";
    risk = "low";
elseif contains(pathLower, "active_context") || contains(pathLower, "session_handoff")
    type = "project operational context";
    active = true;
    decision = "retain";
elseif endsWith(pathLower, "readme.md") || path == "README.md"
    type = "index";
    active = true;
    decision = "retain";
elseif contains(pathLower, "/decisions/")
    type = "active architecture/ADR";
    active = true;
    decision = "retain";
elseif contains(pathLower, "public_api") || contains(pathLower, "production_core") || ...
        contains(pathLower, "naming_strategy") || contains(pathLower, "repository_structure") || ...
        contains(pathLower, "maintained_entrypoints") || contains(pathLower, "architecture.md") || ...
        contains(pathLower, "branch_policy") || contains(pathLower, "test_runner_ownership") || ...
        contains(pathLower, "test_suite_final_architecture")
    type = "active contract";
    active = true;
    decision = "retain";
elseif contains(pathLower, "validation") || contains(pathLower, "current_sweeps") || ...
        contains(pathLower, "workflow") || contains(pathLower, "usage")
    type = "active validation procedure";
    active = true;
    decision = "retain";
end

% Exact human-reviewed decisions for the required focus set.
switch path
    case "docs/repository/mrlfe_line_and_repository_density_audit.md"
        type = "active architecture/diagnostic plan"; active = true; historical = false;
        uniqueCurrent = true; decision = "retain"; target = ""; risk = "low";
    case "docs/models/mrlfe/atlas_policy_notes.md"
        type = "historical migration evidence"; active = false; historical = true;
        uniqueCurrent = false; decision = "delete"; target = "Git history"; risk = "medium";
    case "docs/models/mrlfe/fittool_grid_path_sensitivity.md"
        type = "historical migration evidence"; active = false; historical = true;
        uniqueCurrent = true; decision = "consolidate";
        target = "docs/models/mrlfe/fitting_workflow.md"; risk = "low";
    case "docs/models/mrlfe/docs_cleanup_audit.md"
        type = "completed audit/report"; active = false; historical = true;
        uniqueCurrent = false; decision = "delete"; target = "this audit"; risk = "low";
    case {"docs/validation/mrlfe_legacy_route_inventory.md", ...
          "docs/validation/mrlfe_solver_route_audit.md", ...
          "docs/validation/mrlfe_solver_route_quick_results.md"}
        type = "historical migration evidence"; active = false; historical = true;
        uniqueCurrent = false; decision = "delete"; target = "Git history"; risk = "low";
    case "docs/architecture/execution_profiles_dependency_map.md"
        type = "duplicate/superseded"; active = false; historical = true;
        uniqueCurrent = true; decision = "consolidate";
        target = "docs/architecture/execution_profiles_surface_integration.md"; risk = "low";
    case {"docs/architecture/execution_profiles_audit.md", ...
          "docs/repository/repository_cleanup_audit_2026-07-14.md", ...
          "docs/repository/repository_cleanup_phase1_report.md", ...
          "docs/repository/test_suite_audit.md", ...
          "docs/repository/test_baseline_failure_diagnosis.md"}
        type = "completed audit/report"; active = false; historical = true;
        uniqueCurrent = false; decision = "delete"; target = "Git history"; risk = "low";
    case "references/PYTHON_REPO_NOTES.md"
        type = "duplicate/superseded"; active = false; historical = true;
        uniqueCurrent = false; decision = "delete"; target = "Git history"; risk = "low";
    case "docs/validation/execution_profile_manual_validation.md"
        type = "active validation procedure"; active = true; historical = false;
        uniqueCurrent = true; decision = "consolidate";
        target = "docs/architecture/execution_profiles_surface_integration.md"; risk = "medium";
end

if contains(text, "Last reviewed") && decision == "retain"
    uniqueCurrent = true;
end
end

function tf = documentContradiction(path, text)
historicalPath = contains(lower(path), "archive") || contains(lower(path), "audit") || ...
    contains(lower(path), "proposal") || contains(lower(path), "report") || ...
    contains(lower(path), "diagnosis");
obsolete = contains(text, "mapped_to_fast") || contains(text, "fast_fit_atlas") || ...
    contains(text, "A0DelayedCut") || contains(text, "effective profile is `Fast`");
tf = obsolete && ~historicalPath;
if path == "docs/models/mrlfe/public_api.md"
    tf = contains(text, "maintained Main GUI preset is public `fast`");
end
end

function decisions = buildMRLFEFileDecisions(repoRoot, facts, documentation)
path = facts.Path;
inScope = startsWith(path, "models/mrlfe/") | startsWith(path, "analysis/mrlfe/") | ...
    startsWith(path, "examples/mrlfe/") | contains(lower(path), "mrlfe") | ...
    ismember(path, ["app/adapters/guiRunMRLFEModel.m", ...
    "app/adapters/guiRunMRLFESweep.m", "app/adapters/guiFitMRLFESolver.m", ...
    "app/mrlfeResolveExecutionProfile.m", ...
    "models/rayleigh_lamb/core/rlComputeFundamentalLambModes.m", ...
    "analysis/execution_profiles/benchmarkMRLFEExecutionProfiles.m"]);
selected = facts(inScope, :);
n = height(selected);
Category = strings(n,1);
CurrentRole = strings(n,1);
MainLine = false(n,1);
DirectCallers = strings(n,1);
DynamicCallRisk = strings(n,1);
TestCoverage = strings(n,1);
DocumentationReferences = strings(n,1);
Decision = strings(n,1);
TargetPathOrReplacement = strings(n,1);
Risk = strings(n,1);
RequiredValidation = strings(n,1);
Evidence = strings(n,1);
Notes = strings(n,1);

mFiles = facts.Path(facts.Extension == ".m");
mTexts = readTrackedTexts(repoRoot, mFiles);
testMask = startsWith(mFiles, "tests/");
docPaths = documentation.Path;
docTexts = readTrackedTexts(repoRoot, docPaths);

for i = 1:n
    pth = selected.Path(i);
    [Category(i), CurrentRole(i), MainLine(i), Decision(i), ...
        TargetPathOrReplacement(i), Risk(i), RequiredValidation(i), Notes(i)] = ...
        mrlfeFileDecision(pth, selected.Extension(i));
    if selected.Extension(i) == ".md"
        docIndex = find(documentation.Path == pth, 1);
        Decision(i) = documentation.Decision(docIndex);
        TargetPathOrReplacement(i) = documentation.ReplacementOrConsolidationTarget(docIndex);
        Risk(i) = documentation.Risk(docIndex);
        CurrentRole(i) = documentation.DocumentType(docIndex);
        MainLine(i) = documentation.ActiveContract(docIndex) && documentation.Decision(docIndex) == "retain";
    end
    [~,name] = fileparts(pth);
    if selected.Extension(i) == ".m"
        callers = tokenReferences(mFiles, mTexts, string(name), pth);
        DirectCallers(i) = strjoin(callers, ';');
        DynamicCallRisk(i) = dynamicRisk(mTexts, name);
        coverage = tokenReferences(mFiles(testMask), mTexts(testMask), string(name), "");
        TestCoverage(i) = strjoin(coverage, ';');
    else
        DirectCallers(i) = "";
        DynamicCallRisk(i) = "none";
        TestCoverage(i) = "not applicable";
    end
    docRefs = tokenReferences(docPaths, docTexts, string(name), pth);
    DocumentationReferences(i) = strjoin(docRefs, ';');
    Evidence(i) = "git-tracked; exact token callers=" + countList(DirectCallers(i)) + ...
        "; test references=" + countList(TestCoverage(i)) + ...
        "; documentation references=" + countList(DocumentationReferences(i));
end

decisions = table(selected.Path, selected.Extension, selected.TopLevelArea, ...
    selected.LineCount, selected.NonblankNoncommentLineCount, Category, ...
    CurrentRole, MainLine, DirectCallers, DynamicCallRisk, TestCoverage, ...
    DocumentationReferences, Decision, TargetPathOrReplacement, Risk, ...
    RequiredValidation, Evidence, Notes, 'VariableNames', ...
    {'Path','Extension','TopLevelArea','LineCount','NonblankNoncommentLineCount', ...
    'Category','CurrentRole','MainLine','DirectCallers','DynamicCallRisk', ...
    'TestCoverage','DocumentationReferences','Decision','TargetPathOrReplacement', ...
    'Risk','RequiredValidation','Evidence','Notes'});
decisions = sortrows(decisions, 'Path');
end

function texts = readTrackedTexts(repoRoot, paths)
texts = strings(numel(paths),1);
for i = 1:numel(paths)
    texts(i) = string(fileread(fullfile(repoRoot, nativePath(paths(i)))));
end
end

function refs = tokenReferences(paths, texts, token, excludePath)
if strlength(token) == 0
    refs = strings(0,1);
    return;
end
pattern = "(?<![A-Za-z0-9_])" + regexptranslate('escape', token) + ...
    "(?![A-Za-z0-9_])";
mask = false(numel(paths),1);
for i = 1:numel(paths)
    mask(i) = ~isempty(regexp(texts(i), pattern, 'once')) && paths(i) ~= excludePath;
end
refs = sort(paths(mask));
end

function risk = dynamicRisk(texts, functionName)
risk = "none found";
for i = 1:numel(texts)
    text = texts(i);
    if contains(text, string(functionName)) && ...
            (contains(text, "str2func") || contains(text, "feval") || contains(text, "Callback"))
        risk = "explicit dynamic reference";
        return;
    end
end
end

function n = countList(text)
if strlength(text) == 0 || text == "not applicable"
    n = 0;
else
    n = numel(split(text, ';'));
end
end

function [category, role, mainLine, decision, target, risk, validation, notes] = mrlfeFileDecision(path, ext)
category = "supporting evidence";
role = "mRLFE-related tracked artifact";
mainLine = false;
decision = "retain";
target = "";
risk = "low";
validation = "static path/reference validation";
notes = "";

if ext == ".md"
    category = "documentation";
    role = "contract, guide, or historical evidence";
    decision = "retain";
elseif startsWith(path, "models/mrlfe/")
    category = "main production line";
    role = "public API or production solver helper";
    mainLine = true;
    decision = "retain";
    risk = "high";
    validation = "public contract, production core, quick smoke";
elseif startsWith(path, "app/adapters/")
    category = "application/interface line";
    role = "mRLFE surface adapter";
    mainLine = true;
    decision = "refactor";
    target = "thin orchestrator plus shared request/result metadata helpers";
    risk = "high";
    validation = "surface public-solver test plus parity characterization";
elseif startsWith(path, "analysis/mrlfe/")
    category = "shared reusable support";
    role = "request, fitting, sweep, or diagnostic helper";
    mainLine = ~contains(path, "run_mrlfe_solver_route_audit") && ...
        ~contains(path, "compareMRLFETrackingStrategies") && ...
        ~contains(path, "summarizeMRLFETrackingQuality");
    decision = "retain";
    validation = "focused mRLFE tests";
elseif startsWith(path, "tests/")
    category = "tests and runners";
    role = "mRLFE contract or integration coverage";
    decision = "retain";
    validation = "canonical owner and inventory validation";
elseif startsWith(path, "examples/mrlfe/")
    category = "examples and diagnostics";
    role = "executable example or diagnostic";
    decision = "retain";
    validation = "startup resolution and focused manual execution";
end

switch path
    case "models/mrlfe/solvers/solveMRLFEBranch.m"
        category = "apparently orphaned";
        role = "superseded pre-production branch tracker";
        mainLine = false; decision = "delete";
        target = "models/mrlfe/tracking/mrlfeTrackBranchAdaptive.m";
        risk = "medium";
        validation = "absence check, public/core/smoke suites, startup which check";
        notes = "No exact executable caller or dynamic reference; history ends in 2026-06-13 staging commit.";
    case {"analysis/mrlfe/mrlfeBuildGuiSolveRequest.m", ...
          "analysis/mrlfe/mrlfeBuildSweepSolveRequest.m", ...
          "analysis/mrlfe/mrlfeBuildFitSolveRequest.m"}
        category = "application/interface line";
        role = "surface-specific public request mapper";
        mainLine = true; decision = "consolidate";
        target = "analysis/mrlfe/mrlfeBuildPublicSolveRequest.m plus thin wrappers";
        risk = "high";
        validation = "builder contracts and all three surface parity tests";
    case "models/mrlfe/configuration/mrlfeResolveConfiguration.m"
        decision = "refactor";
        target = "retain orchestrator; extract RL seed/internal option translation only";
        notes = "Defaults, public validation, preset resolution, RL coupling, tracking and termination options are dense.";
    case {"models/mrlfe/results/mrlfeBuildInternalBranchResult.m", ...
          "models/mrlfe/results/mrlfeBuildResult.m"}
        decision = "refactor";
        target = "stable public diagnostics plus explicit debug-only raw internals";
        notes = "Current public result exposes the complete raw internal result and RL seed result.";
    case "models/rayleigh_lamb/core/rlComputeFundamentalLambModes.m"
        category = "legacy/compatibility";
        role = "RL compatibility host for mRLFE model aliases";
        mainLine = true; decision = "refactor";
        target = "consume stable public result adapter instead of rawInternalResult";
        risk = "high";
        validation = "RL/mRLFE smoke and compatibility result tests";
    case "analysis/mrlfe/run_mrlfe_solver_route_audit.m"
        category = "diagnostic-only helper"; role = "obsolete route-audit launcher";
        mainLine = false; decision = "delete"; target = "Git history";
    case "examples/mrlfe/diagnostics/diagnose_mrlfe_atlas_primary_policy_matrix.m"
        category = "one-off investigation"; role = "removed atlas-policy diagnostic";
        decision = "delete"; target = "Git history";
    case {"examples/mrlfe/diagnostics/diagnose_etaS_forward_cache.m", ...
          "examples/mrlfe/diagnostics/diagnose_fit_option_sensitivity.m", ...
          "examples/mrlfe/diagnostics/diagnose_fit_timing.m"}
        category = "performance characterization"; role = "fitting diagnostic using compatibility raw shapes";
        decision = "consolidate"; target = "one maintained mRLFE fitting diagnostic";
    case {"examples/mrlfe/diagnostics/diagnose_mrlfe_gui_performance_32kHz.m", ...
          "examples/mrlfe/diagnostics/diagnose_mrlfe_visco_residual_landscape.m", ...
          "examples/mrlfe/diagnostics/diagnose_mrlfe_visco_validity_breakdown.m", ...
          "examples/mrlfe/diagnostics/stress_test_mrlfe_real_k_range.m", ...
          "examples/mrlfe/diagnostics/compare_mrlfe_tracker_vs_condition_peaks.m"}
        category = "one-off investigation"; role = "pre-public-route numerical investigation";
        decision = "archive"; target = "Git history or one curated diagnostic summary";
    case {"examples/mrlfe/diagnostics/run_mrlfe_targeted_grid_validation.m", ...
          "examples/mrlfe/diagnostics/validate_grid_presets.m", ...
          "examples/mrlfe/diagnostics/validate_grid_presets_full.m"}
        category = "repeatable diagnostic"; role = "current public preset validation";
        decision = "retain"; target = "";
    case "analysis/mrlfe/compareMRLFETrackingStrategies.m"
        category = "diagnostic-only helper"; role = "legacy comparison whose strategies now coincide";
        decision = "delete"; target = "current public solver tests";
    case "analysis/mrlfe/summarizeMRLFETrackingQuality.m"
        category = "diagnostic-only helper"; role = "current tracking quality summarizer";
        decision = "retain";
end
end

function composition = buildComposition(facts, documentation, decisions)
n = height(facts);
Category = strings(n,1);
MainLine = strings(n,1);
for i = 1:n
    path = facts.Path(i);
    ext = facts.Extension(i);
    if ext == ".m"
        [Category(i), MainLine(i)] = matlabCompositionClass(path);
    elseif ext == ".md"
        idx = find(documentation.Path == path, 1);
        Category(i) = documentation.DocumentType(idx);
        if documentation.Decision(idx) == "retain" && documentation.ActiveContract(idx)
            MainLine(i) = "supporting";
        else
            MainLine(i) = "historical_secondary";
        end
    elseif ext == ".csv"
        Category(i) = "generated tooling/inventory";
        MainLine(i) = "supporting";
    elseif facts.IsText(i)
        Category(i) = "repository metadata";
        MainLine(i) = "supporting";
    else
        Category(i) = "binary/generated artifact";
        MainLine(i) = "historical_secondary";
    end
end

% Apply reviewed file decisions to the repository-level line class.
for i = 1:height(decisions)
    idx = find(facts.Path == decisions.Path(i), 1);
    if isempty(idx), continue; end
    if decisions.Decision(i) == "delete" || decisions.Decision(i) == "archive"
        MainLine(idx) = "historical_secondary";
    elseif decisions.Extension(i) == ".m" && decisions.MainLine(i)
        MainLine(idx) = "main";
    end
end

totalFiles = height(facts);
totalTextLines = sum(facts.LineCount(facts.IsText));
keys = unique([facts.TopLevelArea, Category, MainLine], 'rows');
rows = cell(size(keys,1), 9);
for i = 1:size(keys,1)
    mask = facts.TopLevelArea == keys(i,1) & Category == keys(i,2) & MainLine == keys(i,3);
    rows(i,:) = {keys(i,1), keys(i,2), nnz(mask), sum(facts.LineCount(mask)), ...
        sum(facts.NonblankNoncommentLineCount(mask)), 100*nnz(mask)/totalFiles, ...
        100*sum(facts.LineCount(mask))/max(totalTextLines,1), keys(i,3), ...
        "tracked files grouped by area, reviewed category, and line class"};
end
composition = cell2table(rows, 'VariableNames', {'Area','Category','FileCount', ...
    'LineCount','NonblankNoncommentLineCount','PercentOfTrackedFiles', ...
    'PercentOfTrackedTextLines','MainLine','Notes'});

classes = ["main", "supporting", "historical_secondary"];
for i = 1:numel(classes)
    mask = MainLine == classes(i);
    summary = {"repository", classes(i), nnz(mask), sum(facts.LineCount(mask)), ...
        sum(facts.NonblankNoncommentLineCount(mask)), 100*nnz(mask)/totalFiles, ...
        100*sum(facts.LineCount(mask))/max(totalTextLines,1), classes(i), ...
        "repository-wide measured line-class summary"};
    composition = [composition; cell2table(summary, 'VariableNames', composition.Properties.VariableNames)]; %#ok<AGROW>
end
composition = sortrows(composition, {'Area','Category','MainLine'});
end

function [category, lineClass] = matlabCompositionClass(path)
if startsWith(path, "tests/")
    category = "tests and runners"; lineClass = "supporting";
elseif startsWith(path, "examples/")
    category = "examples and diagnostics"; lineClass = "supporting";
elseif startsWith(path, "models/")
    category = "main production line"; lineClass = "main";
elseif startsWith(path, "app/")
    category = "application/interface line"; lineClass = "main";
elseif startsWith(path, "analysis/test_inventory/") || startsWith(path, "analysis/repository_audit/")
    category = "generated tooling/inventory"; lineClass = "supporting";
elseif startsWith(path, "analysis/")
    category = "shared reusable support"; lineClass = "main";
else
    category = "shared reusable support"; lineClass = "main";
end
end

function tableOut = buildDuplicationMatrix()
Responsibility = ["branch validation";"frequency validation";"material aliases"; ...
    "geometry aliases";"fluid aliases";"etaS resolution";"scalar validation"; ...
    "numerical preset";"selection strategy";"termination policy"; ...
    "fallback policy";"grid policy";"sweep point application";"fit settings"];
GuiPath = repmat("analysis/mrlfe/mrlfeBuildGuiSolveRequest.m", numel(Responsibility), 1);
SweepPath = repmat("analysis/mrlfe/mrlfeBuildSweepSolveRequest.m", numel(Responsibility), 1);
FitPath = repmat("analysis/mrlfe/mrlfeBuildFitSolveRequest.m", numel(Responsibility), 1);
EquivalentImplementation = [true(11,1);false;false;false];
DuplicationSeverity = [repmat("high",7,1);repmat("medium",4,1);"low";"none";"none"];
SurfaceSpecific = [false(11,1);true;true;true];
ProposedOwner = repmat("shared public request-construction core", numel(Responsibility), 1);
ProposedOwner(12:14) = ["fit evaluator";"sweep wrapper";"fit wrapper"];
RecommendedAction = repmat("centralize", numel(Responsibility), 1);
RecommendedAction(12:14) = "retain surface-specific";
Evidence = [repmat("near-identical local helper and error-ID implementation in all three builders",11,1); ...
    "fitOptimized/numericalPreset is a Fit workflow concern"; ...
    "applySweepPoint exists only in Sweep builder"; ...
    "fit parameter/options precedence exists only in Fit builder"];
tableOut = table(Responsibility, GuiPath, SweepPath, FitPath, ...
    EquivalentImplementation, DuplicationSeverity, SurfaceSpecific, ...
    ProposedOwner, RecommendedAction, Evidence);
end

function validateRelativeTrackedPaths(repoRoot, paths, decisions, documentation)
assert(all(~startsWith(paths, "/")) && all(cellfun(@isempty, regexp(cellstr(paths), '^[A-Za-z]:', 'once'))), ...
    'repositoryAudit:AbsolutePath', 'Tracked inventory contains an absolute path.');
assert(all(arrayfun(@(p)isfile(fullfile(repoRoot, nativePath(p))), paths)), ...
    'repositoryAudit:MissingTrackedPath', 'A tracked path does not exist.');
assert(all(ismember(decisions.Path, paths)), ...
    'repositoryAudit:UntrackedDecision', 'File-decision inventory contains an untracked path.');
assert(all(ismember(documentation.Path, paths)), ...
    'repositoryAudit:UntrackedDocument', 'Documentation inventory contains an untracked path.');
assert(~any(contains(decisions.Path, repoRoot)) && ~any(contains(documentation.Path, repoRoot)), ...
    'repositoryAudit:LeakedRoot', 'An audit artifact contains the absolute repository root.');
end

function path = nativePath(path)
path = strrep(char(path), '/', filesep);
end
