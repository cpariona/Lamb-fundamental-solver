function test_ae_final_architecture_contract()
%TEST_AE_FINAL_ARCHITECTURE_CONTRACT Guard final AE ownership and documentation.

repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
modelRoot = fullfile(repoRoot, 'models', 'acoustoelastic_iop_hgo');

expectedFolders = sort(["configuration"; "constitutive"; "core"; "diagnostics"; "options"; ...
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
    "tracking/aeRefineSelectedAtlasBranch.m"
    "policies/aeSelectAtlasA0Branch.m"
    "policies/aeApplyAtlasA0FallbackPolicy.m"
    "quality/aeEvaluateAtlasA0Quality.m"
    "results/aeBuildResult.m"
    "diagnostics/aeBuildIdentityA0DiagnosticBranch.m"
    "diagnostics/aeScoreBranchIdentityCandidates.m"];
for i = 1:numel(canonicalOwners)
    assert(isfile(fullfile(modelRoot, canonicalOwners(i))), ...
        'Missing canonical AE owner: %s', canonicalOwners(i));
end


atlasSolverText = string(fileread(fullfile(modelRoot, 'solvers', ...
    'solveAcoustoelasticAtlasBranch.m')));
selectionPosition = strfind(atlasSolverText, 'aeSelectAtlasA0Branch');
refinementPosition = strfind(atlasSolverText, 'aeRefineSelectedAtlasBranch');
assert(isscalar(selectionPosition) && isscalar(refinementPosition) && ...
    refinementPosition > selectionPosition, ...
    'AE continuous refinement must remain after discrete atlasA0 selection.');

refinementText = string(fileread(fullfile(modelRoot, 'tracking', ...
    'aeRefineSelectedAtlasBranch.m')));
assert(contains(refinementText, 'fminbnd') && ...
    contains(refinementText, 'objectiveAcoustoelasticResidual'), ...
    'AE selected-branch refinement must use bounded minimization of the true SVD objective.');
assert(~contains(lower(refinementText), 'parabolic') && ...
    ~contains(lower(atlasSolverText), 'parabolic'), ...
    'AE production must not reintroduce three-point parabolic refinement.');

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
