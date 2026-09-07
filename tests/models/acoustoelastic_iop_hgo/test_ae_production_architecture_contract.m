function test_ae_production_architecture_contract()
%TEST_AE_PRODUCTION_ARCHITECTURE_CONTRACT Guard canonical AE ownership.

repoRoot = testRepositoryRoot();
modelRoot = fullfile(repoRoot, 'src', '+lamb', '+models', '+acoustoelastic_iop_hgo');

canonicalOwners = [ ...
    "solveAcoustoelasticIOPHGOBranch.m"
    "defaultAcoustoelasticIOPHGOOptions.m"
    "+configuration/aeValidateRequest.m"
    "+configuration/aeResolveConfiguration.m"
    "+configuration/aeGetNumericalPreset.m"
    "+configuration/aeBuildInternalTrackingGrid.m"
    "+configuration/aeDefaultDiagnosticOptions.m"
    "+configuration/aeNormalizeBranchPolicy.m"
    "+solvers/solveAcoustoelasticAtlasBranch.m"
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

publicOwnerText = string(fileread(fullfile(modelRoot, ...
    'solveAcoustoelasticIOPHGOBranch.m')));
for productionCall = ["lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest"; "lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration"; ...
        "lamb.models.acoustoelastic_iop_hgo.constitutive.computeAcoustoelasticABGFromIOPHGO"; "lamb.models.acoustoelastic_iop_hgo.solvers.solveAcoustoelasticAtlasBranch"; ...
        "lamb.models.acoustoelastic_iop_hgo.policies.aeApplyAtlasA0FallbackPolicy"; "lamb.models.acoustoelastic_iop_hgo.results.aeBuildResult"]
    assert(contains(publicOwnerText, productionCall), ...
        'Public AE owner is missing responsibility %s.', productionCall);
end

atlasSolverText = string(fileread(fullfile(modelRoot, '+solvers', ...
    'solveAcoustoelasticAtlasBranch.m')));
selectionPosition = strfind(atlasSolverText, 'lamb.models.acoustoelastic_iop_hgo.policies.aeSelectAtlasA0Branch');
refinementPosition = strfind(atlasSolverText, 'lamb.models.acoustoelastic_iop_hgo.tracking.aeRefineSelectedAtlasBranch');
assert(isscalar(selectionPosition) && isscalar(refinementPosition) && ...
    refinementPosition > selectionPosition, ...
    'AE refinement must remain after discrete atlasA0 selection.');

refinementText = string(fileread(fullfile(modelRoot, '+tracking', ...
    'aeRefineSelectedAtlasBranch.m')));
assert(contains(refinementText, 'fminbnd') && ...
    contains(refinementText, 'lamb.models.acoustoelastic_iop_hgo.core.objectiveAcoustoelasticResidual'), ...
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

internalSolvers = ["lamb.models.acoustoelastic_iop_hgo.solvers.solveAcoustoelasticAtlasBranch"; ...
    "lamb.models.acoustoelastic_iop_hgo.solvers.solveAcoustoelasticIOPHGODispersion"; "lamb.models.acoustoelastic_iop_hgo.solvers.solveAcoustoelasticDispersion"; ...
    "lamb.models.acoustoelastic_iop_hgo.solvers.solveAcoustoelasticComplexCDispersion"];
for i = 1:numel(internalSolvers)
    definitions = which(char(internalSolvers(i)), '-all');
    assert(numel(definitions) == 1, ...
        'Expected one definition for internal AE solver %s.', internalSolvers(i));
end

architecturePath = fullfile(repoRoot, 'docs', 'models', ...
    'acoustoelastic_iop_hgo', 'architecture.md');
assert(isfile(architecturePath), 'Missing maintained AE architecture contract.');
architectureText = string(fileread(architecturePath));
documentedOwners = ["lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch"; internalSolvers];
for i = 1:numel(documentedOwners)
    identifier = documentedOwners(i);
    assert(contains(architectureText, identifier), ...
        'Architecture contract does not classify %s.', identifier);
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
