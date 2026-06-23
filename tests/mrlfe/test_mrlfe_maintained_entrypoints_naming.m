clear; clc;
startup

%TEST_MRLFE_MAINTAINED_ENTRYPOINTS_NAMING Guard maintained mRLFE naming surface.
%
% Historical diagnostics may still contain author-dependent names, but the
% maintained mRLFE execution surface should expose physical/model names.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
docPath = fullfile(repoRoot, 'docs', 'maintained_entrypoints.md');
text = fileread(docPath);

sectionStart = strfind(text, '## mRLFE model');
sectionEnd = strfind(text, '## Smoke-test scope');
assert(~isempty(sectionStart) && ~isempty(sectionEnd), ...
    'maintained_entrypoints.md must contain mRLFE and smoke-test sections.');

mrlfeSection = text(sectionStart(1):sectionEnd(1)-1);
assert(contains(mrlfeSection, 'viscoelastic'), ...
    'Maintained mRLFE section should use physical viscoelastic naming.');
assert(~contains(lower(mrlfeSection), 'han'), ...
    'Maintained mRLFE section should not expose author-dependent Han labels.');
assert(contains(mrlfeSection, 'summarizeMRLFETrackingQuality'), ...
    'Maintained mRLFE section should list summarizeMRLFETrackingQuality.');
assert(contains(mrlfeSection, 'compareMRLFETrackingStrategies'), ...
    'Maintained mRLFE section should list compareMRLFETrackingStrategies.');

fprintf('test_mrlfe_maintained_entrypoints_naming passed. Maintained mRLFE docs use physical naming.\n');
