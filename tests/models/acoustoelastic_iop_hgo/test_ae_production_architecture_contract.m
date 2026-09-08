function test_ae_production_architecture_contract()
%TEST_AE_PRODUCTION_ARCHITECTURE_CONTRACT Guard canonical AE ownership.

repoRoot = testRepositoryRoot();
modelRoot = fullfile(repoRoot, 'src', '+lamb', '+models', '+acoustoelastic_iop_hgo');

canonicalOwners = [ ...
    "aeSolveBranch.m"
    "aeDefaultOptions.m"
    "+configuration/aeValidateRequest.m"
    "+configuration/aeResolveConfiguration.m"
    "+configuration/aeGetNumericalPreset.m"
    "+configuration/aeBuildInternalTrackingGrid.m"
    "+configuration/aeDefaultDiagnosticOptions.m"
    "+configuration/aeNormalizeBranchPolicy.m"
    "+solvers/aeSolveAtlasBranch.m"
    "+solvers/aeBuildAtlas.m"
    "+tracking/aeFindAtlasLocalMinima.m"
    "+tracking/aeLinkAtlasBranches.m"
    "+tracking/aeSplitAtlasBranches.m"
    "+tracking/aeRefineSelectedAtlasBranch.m"
    "+policies/aeSelectAtlasA0Branch.m"
    "+policies/aeApplyAtlasA0FallbackPolicy.m"
    "+quality/aeEvaluateAtlasA0Quality.m"
    "+results/aeBuildResult.m"];
for i = 1:numel(canonicalOwners)
    assert(isfile(fullfile(modelRoot, canonicalOwners(i))), ...
        'Missing canonical AE owner: %s', canonicalOwners(i));
end
assert(~isfolder(fullfile(modelRoot, '+options')), ...
    'Generic AE options must be owned by configuration/.');
assert(~isfile(fullfile(modelRoot, '+solvers', ...
    'solveAcoustoelasticIOPHGOAtlasBranch.m')), ...
    'The obsolete AE forwarding API must remain removed.');

publicOwnerText = string(fileread(fullfile(modelRoot, 'aeSolveBranch.m')));
for productionCall = ["lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest"; "lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration"; ...
        "lamb.models.acoustoelastic_iop_hgo.constitutive.aeComputeABGFromIOPHGO"; "lamb.models.acoustoelastic_iop_hgo.solvers.aeSolveAtlasBranch"; ...
        "lamb.models.acoustoelastic_iop_hgo.policies.aeApplyAtlasA0FallbackPolicy"; "lamb.models.acoustoelastic_iop_hgo.results.aeBuildResult"]
    assert(contains(publicOwnerText, productionCall), ...
        'Public AE owner is missing responsibility %s.', productionCall);
end

atlasSolverText = string(fileread(fullfile(modelRoot, '+solvers', 'aeSolveAtlasBranch.m')));
selectionPosition = strfind(atlasSolverText, 'lamb.models.acoustoelastic_iop_hgo.policies.aeSelectAtlasA0Branch');
refinementPosition = strfind(atlasSolverText, 'lamb.models.acoustoelastic_iop_hgo.tracking.aeRefineSelectedAtlasBranch');
assert(isscalar(selectionPosition) && isscalar(refinementPosition) && ...
    refinementPosition > selectionPosition, ...
    'AE refinement must remain after discrete atlasA0 selection.');

refinementText = string(fileread(fullfile(modelRoot, '+tracking', ...
    'aeRefineSelectedAtlasBranch.m')));
assert(contains(refinementText, 'fminbnd') && ...
    contains(refinementText, 'lamb.models.acoustoelastic_iop_hgo.core.aeObjectiveResidual'), ...
    'AE refinement must minimize the true SVD objective with fminbnd.');
assert(~contains(lower(refinementText), 'parabolic') && ...
    ~contains(lower(atlasSolverText), 'parabolic'), ...
    'AE production must not reintroduce parabolic refinement.');

modelText = readMatlabTree(modelRoot);
assert(~contains(lower(modelText), "analysis/acoustoelastic_iop_hgo") && ...
    ~contains(lower(modelText), "analysis\acoustoelastic_iop_hgo"), ...
    'AE model code must not depend on analysis/.');
for surfaceToken = ["MainGUI", "FitTool"]
    assert(~contains(modelText, surfaceToken), ...
        'AE model code must not own app surface token %s.', surfaceToken);
end

internalSolvers = ["lamb.models.acoustoelastic_iop_hgo.solvers.aeSolveAtlasBranch"; ...
    "lamb.models.acoustoelastic_iop_hgo.solvers.aeSolveIOPHGODispersion"; "lamb.models.acoustoelastic_iop_hgo.solvers.aeSolveDispersion"; ...
    "lamb.models.acoustoelastic_iop_hgo.solvers.aeSolveComplexCDispersion"];
for i = 1:numel(internalSolvers)
    definitions = which(char(internalSolvers(i)), '-all');
    assert(numel(definitions) == 1, ...
        'Expected one definition for internal AE solver %s.', internalSolvers(i));
end

fprintf('AE production architecture contract passed.\n');
end

function text = readMatlabTree(root)
files = dir(fullfile(root, '**', '*.m'));
assert(~isempty(files), 'AE production architecture scan must include MATLAB files.');
text = "";
for i = 1:numel(files)
    text = text + newline + string(fileread(fullfile(files(i).folder, files(i).name)));
end
end
