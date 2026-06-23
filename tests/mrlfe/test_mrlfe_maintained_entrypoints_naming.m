clear; clc;
startup

%TEST_MRLFE_MAINTAINED_ENTRYPOINTS_NAMING Guard maintained mRLFE naming surface.
%
% Historical diagnostics may still contain author-dependent names, but the
% maintained mRLFE execution surface should expose physical/model names.

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
assert(~contains(lower(mrlfeSection), 'han'), ...
    'Maintained mRLFE section should not expose author-dependent Han labels.');
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
assert(~contains(lower(readmeSection), 'han'), ...
    'README mRLFE workflow should not expose author-dependent Han labels.');
assert(contains(readmeSection, 'compare_mrlfe_elastic_vs_visco_cp'), ...
    'README should list the renamed elastic-vs-visco comparison example.');

renamedExample = fullfile(repoRoot, 'examples', 'mrlfe', 'basic', 'compare_mrlfe_elastic_vs_visco_cp.m');
oldExample = fullfile(repoRoot, 'examples', 'mrlfe', 'basic', 'compare_mrlfe_elastic_vs_han_visco_cp.m');
assert(isfile(renamedExample), 'Renamed mRLFE elastic-vs-visco example is missing.');
assert(~isfile(oldExample), 'Old author-labeled elastic-vs-Han example should not remain.');

renamedValidityDiagnostic = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'diagnose_mrlfe_visco_validity_breakdown.m');
oldValidityDiagnostic = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'diagnose_mrlfe_han_visco_validity_breakdown.m');
assert(isfile(renamedValidityDiagnostic), 'Renamed mRLFE visco validity diagnostic is missing.');
assert(~isfile(oldValidityDiagnostic), 'Old author-labeled visco validity diagnostic should not remain.');

renamedLandscapeDiagnostic = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'diagnose_mrlfe_visco_residual_landscape.m');
oldLandscapeDiagnostic = fullfile(repoRoot, 'examples', 'mrlfe', 'diagnostics', 'diagnose_mrlfe_han_visco_residual_landscape.m');
assert(isfile(renamedLandscapeDiagnostic), 'Renamed mRLFE visco residual landscape diagnostic is missing.');
assert(~isfile(oldLandscapeDiagnostic), 'Old author-labeled residual landscape diagnostic should not remain.');

fprintf('test_mrlfe_maintained_entrypoints_naming passed. Maintained mRLFE docs use physical naming.\n');
