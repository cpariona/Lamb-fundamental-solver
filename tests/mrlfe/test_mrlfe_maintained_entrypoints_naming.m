clear; clc;
startup

%TEST_MRLFE_MAINTAINED_ENTRYPOINTS_NAMING Guard maintained mRLFE naming surface.
%
% The maintained mRLFE execution surface should expose physical/model names.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));

entrypointsPath = fullfile(repoRoot, 'docs', 'maintained_entrypoints.md');
entrypointsText = fileread(entrypointsPath);
sectionStart = strfind(entrypointsText, '## mRLFE model');
sectionEnd = strfind(entrypointsText, '## Smoke-test scope');
assert(~isempty(sectionStart) && ~isempty(sectionEnd), ...
    'maintained_entrypoints.md must contain mRLFE and smoke-test sections.');

mrlfeSection = entrypointsText(sectionStart(1):sectionEnd(1)-1);
assert(contains(mrlfeSection, 'viscoelastic'), ...
    'Maintained mRLFE section should use physical viscoelastic naming.');
assert(contains(mrlfeSection, 'summarizeMRLFETrackingQuality'), ...
    'Maintained mRLFE section should list summarizeMRLFETrackingQuality.');
assert(contains(mrlfeSection, 'compareMRLFETrackingStrategies'), ...
    'Maintained mRLFE section should list compareMRLFETrackingStrategies.');

readmePath = fullfile(repoRoot, 'README.md');
readmeText = fileread(readmePath);
readmeStart = strfind(readmeText, '## mRLFE solver workflow');
assert(~isempty(readmeStart), 'README.md must contain the mRLFE solver workflow section.');
readmeSection = readmeText(readmeStart(1):end);
assert(contains(readmeSection, 'viscoelastic'), ...
    'README mRLFE workflow should use physical viscoelastic naming.');
assert(contains(readmeSection, 'compare_mrlfe_elastic_vs_visco_cp'), ...
    'README should list the renamed elastic-vs-visco comparison example.');

renamedExample = fullfile(repoRoot, 'examples', 'mrlfe', 'basic', 'compare_mrlfe_elastic_vs_visco_cp.m');
assert(isfile(renamedExample), 'Renamed mRLFE elastic-vs-visco example is missing.');

renamedValidityDiagnostic = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'diagnose_mrlfe_visco_validity_breakdown.m');
assert(isfile(renamedValidityDiagnostic), 'Renamed mRLFE visco validity diagnostic is missing.');

renamedLandscapeDiagnostic = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'diagnose_mrlfe_visco_residual_landscape.m');
assert(isfile(renamedLandscapeDiagnostic), 'Renamed mRLFE visco residual landscape diagnostic is missing.');

renamedStressTest = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'stress_test_mrlfe_visco_range.m');
assert(isfile(renamedStressTest), 'Renamed mRLFE visco range stress test is missing.');

analysisFiles = { ...
    fullfile(repoRoot, 'analysis', 'plotParametricSweepCp.m'), ...
    fullfile(repoRoot, 'analysis', 'summarizeParametricSweepBranch.m')};
for i = 1:numel(analysisFiles)
    fileText = fileread(analysisFiles{i});
    assert(contains(fileText, 'mRLFEViscoRealK'), ...
        'Maintained analysis helper should document mRLFEViscoRealK: %s', analysisFiles{i});
end

trackerDiagnostic = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'compare_mrlfe_tracker_vs_condition_peaks.m');
trackerText = fileread(trackerDiagnostic);
assert(contains(trackerText, 'mRLFEViscoRealK'), ...
    'Tracker diagnostic should use mRLFEViscoRealK as the selectable viscoelastic model.');

fprintf('test_mrlfe_maintained_entrypoints_naming passed. Maintained mRLFE docs use physical naming.\n');
