function test_ae_final_architecture_contract()
%TEST_AE_FINAL_ARCHITECTURE_CONTRACT Guard final AE ownership and documentation.

repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
modelRoot = fullfile(repoRoot, 'models', 'acoustoelastic_iop_hgo');

expectedFolders = sort(["configuration"; "constitutive"; "core"; "options"; ...
    "policies"; "quality"; "results"; "solvers"; "tracking"]);
folderEntries = dir(modelRoot);
actualFolders = sort(string({folderEntries([folderEntries.isdir]).name}).');
actualFolders = actualFolders(~ismember(actualFolders, [".", ".."]));
assert(isequal(actualFolders, expectedFolders), ...
    'The final AE model responsibility folders changed.');

canonicalOwners = [ ...
    "configuration/aeValidateRequest.m"
    "configuration/aeResolveConfiguration.m"
    "configuration/aeGetNumericalPreset.m"
    "configuration/aeBuildInternalTrackingGrid.m"
    "solvers/solveAcoustoelasticIOPHGOBranch.m"
    "solvers/solveAcoustoelasticIOPHGOAtlasBranch.m"
    "solvers/solveAcoustoelasticAtlasBranch.m"
    "solvers/aeBuildAtlas.m"
    "tracking/aeFindAtlasLocalMinima.m"
    "tracking/aeLinkAtlasBranches.m"
    "tracking/aeSplitAtlasBranches.m"
    "policies/aeSelectAtlasA0Branch.m"
    "policies/aeApplyAtlasA0FallbackPolicy.m"
    "quality/aeEvaluateAtlasA0Quality.m"
    "results/aeBuildResult.m"
    "results/aeBuildIdentityA0DiagnosticBranch.m"
    "results/aeScoreBranchIdentityCandidates.m"];
for i = 1:numel(canonicalOwners)
    assert(isfile(fullfile(modelRoot, canonicalOwners(i))), ...
        'Missing canonical AE owner: %s', canonicalOwners(i));
end

modelText = readMatlabTree(modelRoot);
assert(~contains(lower(modelText), "analysis/acoustoelastic_iop_hgo"), ...
    'AE model code must not depend on the analysis layer.');
assert(~contains(lower(modelText), "analysis\acoustoelastic_iop_hgo"), ...
    'AE model code must not depend on the analysis layer.');

advancedSolvers = [ ...
    "solveAcoustoelasticIOPHGOAtlasBranch"
    "solveAcoustoelasticAtlasBranch"
    "solveAcoustoelasticIOPHGODispersion"
    "solveAcoustoelasticDispersion"
    "solveAcoustoelasticComplexCDispersion"];
for i = 1:numel(advancedSolvers)
    definitions = dir(fullfile(repoRoot, '**', advancedSolvers(i) + ".m"));
    assert(isscalar(definitions), ...
        'Expected one tracked definition for advanced AE API %s.', advancedSolvers(i));
end

deferredHelpers = [ ...
    "summarizeAcoustoelasticIOPHGOTrackingQuality"
    "aePlotGridSweepCp"
    "aeAnalyzeFirstUnrecoveredBreak"
    "aeClassifyTruncationRecovery"
    "aeClassifyAmbiguityRegime"
    "aeRefineAtlasA0BranchPersistence"];
for i = 1:numel(deferredHelpers)
    definitions = dir(fullfile(repoRoot, '**', deferredHelpers(i) + ".m"));
    assert(isscalar(definitions), ...
        'Expected one retained definition for AE helper %s.', deferredHelpers(i));
end

architecturePath = fullfile(repoRoot, 'docs', 'models', ...
    'acoustoelastic_iop_hgo', 'active', 'architecture.md');
assert(isfile(architecturePath), 'Missing final AE architecture contract.');
assert(~isfile(fullfile(fileparts(architecturePath), 'architecture_audit.md')), ...
    'The historical architecture-audit path must not remain active.');
architectureText = string(fileread(architecturePath));
for identifier = [advancedSolvers; deferredHelpers; "aeResolveResultFile"]
    assert(contains(architectureText, identifier), ...
        'Final architecture contract does not classify %s.', identifier);
end

fprintf('AE final architecture contract passed.\n');
end

function text = readMatlabTree(root)
files = dir(fullfile(root, '**', '*.m'));
text = "";
for i = 1:numel(files)
    text = text + newline + string(fileread(fullfile(files(i).folder, files(i).name)));
end
end
