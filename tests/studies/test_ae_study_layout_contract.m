function test_ae_study_layout_contract()
%TEST_AE_STUDY_LAYOUT_CONTRACT Guard the maintained AE study surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
studyRoot = fullfile(repoRoot, 'studies');
diagnosticPath = fullfile(studyRoot, 'solver_diagnostics', ...
    'acoustoelastic_iop_hgo', 'aeDiagnoseBranchFamilies.m');
atlasHelperPath = fullfile(studyRoot, 'solver_diagnostics', ...
    'acoustoelastic_iop_hgo', 'aeComputeModalAtlasForCase.m');
assertCanonicalDiagnosticOwners([string(diagnosticPath), string(atlasHelperPath)]);

params = diagnosticParams();
options = diagnosticOptions();
yGrid = logspace(log10(0.01), log10(1.5), 100);
timerStart = tic;
retained = aeComputeModalAtlasForCase(params, options, yGrid, 6, 0.10, 2, "standard");
assert(~isempty(retained.branchTable), ...
    'The retained-branch fixture must exercise diagnostic branch identities.');
finiteIDs = retained.minimaTable.BranchID(isfinite(retained.minimaTable.BranchID));
assert(all(ismember(finiteIDs, retained.branchTable.BranchID)), ...
    'Every finite diagnostic BranchID must belong to the canonical branch table.');
assertDiagnosticOnly(retained);

discarded = aeComputeModalAtlasForCase(params, options, yGrid, 6, 0.10, ...
    numel(params.frequency) + 1, "standard");
assert(isempty(discarded.branchTable), ...
    'The discarded-branch fixture must reject all short diagnostic branches.');
assert(all(isnan(discarded.minimaTable.BranchID)), ...
    'Discarded diagnostic evidence must not acquire an official branch identity.');
assertDiagnosticOnly(discarded);

fprintf('AE diagnostic filtering behavior passed in %.3f s.\n', toc(timerStart));
end

function assertCanonicalDiagnosticOwners(paths)
for path = paths(:).'
    text = executableMatlabText(fileread(path));
    assert(~isempty(regexp(text, ...
        'lamb\.models\.acoustoelastic_iop_hgo\.tracking\.aeFindAtlasLocalMinima\s*\(', 'once')), ...
        'AE diagnostics must use canonical candidate discovery: %s', path);
    assert(~isempty(regexp(text, ...
        'lamb\.models\.acoustoelastic_iop_hgo\.tracking\.aeLinkAtlasBranches\s*\(', 'once')), ...
        'AE diagnostics must use canonical branch linking: %s', path);
    assert(isempty(regexp(text, ...
        '(?mi)^\s*function[^\r\n]*(?:find\w*minim|link\w*branch)\s*\(', 'once')), ...
        'AE diagnostics must not define a parallel tracker or linker: %s', path);
end
end

function text = executableMatlabText(text)
text = regexprep(text, '%\{[\s\S]*?%\}', ' ');
text = regexprep(text, '%[^\r\n]*', ' ');
end

function params = diagnosticParams()
[alpha, beta, gamma] = ...
    lamb.models.acoustoelastic_iop_hgo.constitutive.aeComputeABGFromIOPHGO( ...
    15 * 133.322, 7.8e-3, 550e-6, 50e3, 25e3, 100);
params = struct('alpha', alpha, 'beta', beta, 'gamma', gamma, ...
    'thickness', 550e-6, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9, ...
    'frequency', logspace(log10(1000), log10(5000), 5));
end

function options = diagnosticOptions()
options = lamb.models.acoustoelastic_iop_hgo.aeDefaultOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
end

function assertDiagnosticOnly(atlas)
assert(~any(isfield(atlas, {'phaseVelocity_mps', 'validMask', 'branch'})), ...
    'Diagnostic atlas evidence must not construct or replace the official production curve.');
end
