function test_ae_study_layout_contract()
%TEST_AE_STUDY_LAYOUT_CONTRACT Guard the maintained AE study surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
studyRoot = fullfile(repoRoot, 'studies');
expected = [ ...
    "sensitivity/acoustoelastic_iop_hgo/aeStudyIOPAtlasA0.m"
    "sensitivity/acoustoelastic_iop_hgo/aeStudyMuIOPAtlasA0.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseAtlasTruncation.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseBranchFamilies.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseGridStartSensitivity.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseModalAtlas.m"
    "solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseSweepReliability.m"];

for i = 1:numel(expected)
    [~, name] = fileparts(expected(i));
    expectedPath = fullfile(studyRoot, expected(i));
    assert(isfile(expectedPath), 'Explicit AE study path is missing: %s.', name);
end

diagnosticPath = fullfile(studyRoot, 'solver_diagnostics', ...
    'acoustoelastic_iop_hgo', 'aeDiagnoseBranchFamilies.m');
diagnosticText = stripMatlabComments(fileread(diagnosticPath));
assert(~isempty(regexp(diagnosticText, ...
    'lamb\.models\.acoustoelastic_iop_hgo\.tracking\.aeFindAtlasLocalMinima\s*\(', 'once')), ...
    'Branch-family diagnostics must use canonical AE candidate discovery.');
assert(~isempty(regexp(diagnosticText, ...
    'lamb\.models\.acoustoelastic_iop_hgo\.tracking\.aeLinkAtlasBranches\s*\(', 'once')), ...
    'Branch-family diagnostics must use canonical AE branch linking.');
assert(isempty(regexp(diagnosticText, ...
    '(?mi)^\s*function[^\r\n]*(?:find\w*minim|link\w*branch)\s*\(', 'once')), ...
    'Branch-family diagnostics must not define candidate-discovery or branch-linking substitutes.');
assert(~contains(diagnosticText, 'lastLogY'), ...
    'Branch-family diagnostics must not reimplement the canonical linking state machine.');
assert(contains(diagnosticText, ...
    'minimaTable.BranchID(~ismember(minimaTable.BranchID, retainedIDs)) = nan'), ...
    'Study-local short-branch filtering must preserve historical diagnostic semantics.');

atlasHelperPath = fullfile(studyRoot, 'solver_diagnostics', ...
    'acoustoelastic_iop_hgo', 'aeComputeModalAtlasForCase.m');
atlasHelperText = stripMatlabComments(fileread(atlasHelperPath));
assert(contains(atlasHelperText, ...
    'minimaTable.BranchID(~ismember(minimaTable.BranchID, retainedIDs)) = nan'), ...
    'Modal-atlas diagnostics must clear IDs for branches excluded by the canonical linker.');

fprintf('AE study layout contract passed.\n');
end

function text = stripMatlabComments(text)
text = regexprep(text, '%\{[\s\S]*?%\}', ' ');
text = regexprep(text, '%[^\r\n]*', ' ');
end
