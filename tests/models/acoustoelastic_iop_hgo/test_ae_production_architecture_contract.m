function test_ae_production_architecture_contract()
%TEST_AE_PRODUCTION_ARCHITECTURE_CONTRACT Guard canonical AE ownership.

repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
modelRoot = fullfile(repoRoot, 'models', 'acoustoelastic_iop_hgo');

canonicalOwners = [ ...
    "configuration/aeValidateRequest.m"
    "configuration/aeResolveConfiguration.m"
    "configuration/aeGetNumericalPreset.m"
    "configuration/aeBuildInternalTrackingGrid.m"
    "options/defaultAcoustoelasticIOPHGOOptions.m"
    "options/aeDefaultDiagnosticOptions.m"
    "solvers/solveAcoustoelasticIOPHGOBranch.m"
    "solvers/solveAcoustoelasticAtlasBranch.m"
    "solvers/aeBuildAtlas.m"
    "tracking/aeFindAtlasLocalMinima.m"
    "tracking/aeLinkAtlasBranches.m"
    "tracking/aeSplitAtlasBranches.m"
    "tracking/aeRefineSelectedAtlasBranch.m"
    "policies/aeSelectAtlasA0Branch.m"
    "policies/aeApplyAtlasA0FallbackPolicy.m"
    "quality/aeEvaluateAtlasA0Quality.m"
    "results/aeBuildResult.m"];
for i = 1:numel(canonicalOwners)
    assert(isfile(fullfile(modelRoot, canonicalOwners(i))), ...
        'Missing canonical AE owner: %s', canonicalOwners(i));
end
assert(~isfile(fullfile(modelRoot, 'solvers', ...
    'solveAcoustoelasticIOPHGOAtlasBranch.m')), ...
    'The obsolete AE forwarding API must remain removed.');

publicOwnerText = string(fileread(fullfile(modelRoot, 'solvers', ...
    'solveAcoustoelasticIOPHGOBranch.m')));
for productionCall = ["aeValidateRequest"; "aeResolveConfiguration"; ...
        "computeAcoustoelasticABGFromIOPHGO"; "solveAcoustoelasticAtlasBranch"; ...
        "aeApplyAtlasA0FallbackPolicy"; "aeBuildResult"]
    assert(contains(publicOwnerText, productionCall), ...
        'Public AE owner is missing responsibility %s.', productionCall);
end

atlasSolverText = string(fileread(fullfile(modelRoot, 'solvers', ...
    'solveAcoustoelasticAtlasBranch.m')));
selectionPosition = strfind(atlasSolverText, 'aeSelectAtlasA0Branch');
refinementPosition = strfind(atlasSolverText, 'aeRefineSelectedAtlasBranch');
assert(isscalar(selectionPosition) && isscalar(refinementPosition) && ...
    refinementPosition > selectionPosition, ...
    'AE refinement must remain after discrete atlasA0 selection.');

refinementText = string(fileread(fullfile(modelRoot, 'tracking', ...
    'aeRefineSelectedAtlasBranch.m')));
assert(contains(refinementText, 'fminbnd') && ...
    contains(refinementText, 'objectiveAcoustoelasticResidual'), ...
    'AE refinement must minimize the true SVD objective with fminbnd.');
assert(~contains(lower(refinementText), 'parabolic') && ...
    ~contains(lower(atlasSolverText), 'parabolic'), ...
    'AE production must not reintroduce parabolic refinement.');

modelText = readMatlabTree(modelRoot);
assert(~contains(lower(modelText), "analysis/acoustoelastic_iop_hgo") && ...
    ~contains(lower(modelText), "analysis\acoustoelastic_iop_hgo"), ...
    'AE model code must not depend on analysis/.');
for surfaceToken = ["MainGUI", "FitTool", "SweepTool", "physicalSweep"]
    assert(~contains(modelText, surfaceToken), ...
        'AE model code must not own app surface token %s.', surfaceToken);
end

internalSolvers = ["solveAcoustoelasticAtlasBranch"; ...
    "solveAcoustoelasticIOPHGODispersion"; "solveAcoustoelasticDispersion"; ...
    "solveAcoustoelasticComplexCDispersion"];
for i = 1:numel(internalSolvers)
    definitions = dir(fullfile(repoRoot, '**', internalSolvers(i) + ".m"));
    assert(isscalar(definitions), ...
        'Expected one definition for internal AE solver %s.', internalSolvers(i));
end

architecturePath = fullfile(repoRoot, 'docs', 'models', ...
    'acoustoelastic_iop_hgo', 'active', 'architecture.md');
assert(isfile(architecturePath), 'Missing maintained AE architecture contract.');
architectureText = string(fileread(architecturePath));
for identifier = ["solveAcoustoelasticIOPHGOBranch"; internalSolvers]
    assert(contains(architectureText, identifier), ...
        'Architecture contract does not classify %s.', identifier);
end

fprintf('AE production architecture contract passed.\n');
end

function text = readMatlabTree(root)
files = dir(fullfile(root, '**', '*.m'));
text = "";
for i = 1:numel(files)
    text = text + newline + string(fileread(fullfile(files(i).folder, files(i).name)));
end
end
