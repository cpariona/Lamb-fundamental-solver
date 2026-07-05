function test_acoustoelastic_iop_hgo_short_entrypoints()
%TEST_ACOUSTOELASTIC_IOP_HGO_SHORT_ENTRYPOINTS Verify maintained AE entrypoints are on path.
%
% This is a path-level smoke test only. It does not execute heavy diagnostics.
% Optional historical diagnostics are checked only while they are still present;
% they are not part of the primary maintained surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));

maintainedHelpers = [ ...
    "aeOutputFolder", ...
    "aeResolveResultFile", ...
    "aeRunLegacyScript", ...
    "aeClassifyAmbiguityRegime" ...
    ];
maintainedWorkflows = [ ...
    "run_atlas_branch", ...
    "sweep_iop", ...
    "sweep_mu", ...
    "sweep_thickness", ...
    "sweep_k1", ...
    "sweep_k2", ...
    "sweep_radius", ...
    "sweep_mu_iop" ...
    ];
maintainedDiagnostics = [ ...
    "compare_atlasA0_vs_raw_branch1", ...
    "validate_atlas_raw_grid", ...
    "diagnose_raw_branch_corner", ...
    "diagnose_branch_families", ...
    "diagnose_sweep_reliability", ...
    "diagnose_atlas_truncation", ...
    "diagnose_idA0_plausibility" ...
    ];

maintainedNames = [maintainedHelpers, maintainedWorkflows, maintainedDiagnostics];

for i = 1:numel(maintainedNames)
    entryPath = which(maintainedNames(i));
    assert(~isempty(entryPath), 'Missing maintained AE entrypoint/helper on MATLAB path: %s', maintainedNames(i));
    validateLegacyTargetIfExampleWrapper(maintainedNames(i), entryPath);
end

optionalNames = [ ...
    "validate_idA0_score_grid", ...
    "validate_idA0_grid", ...
    "diagnose_idA0_score", ...
    "diagnose_modal_atlas", ...
    "diagnose_grid_start_sensitivity", ...
    "track_raw_branch1" ...
    ];

for i = 1:numel(optionalNames)
    entryPath = which(optionalNames(i));
    if isempty(entryPath)
        continue;
    end
    validateLegacyTargetIfExampleWrapper(optionalNames(i), entryPath);
end

assertExpectedWrappersUseLegacyRunner([ ...
    "validate_idA0_grid", ...
    "validate_idA0_score_grid", ...
    "diagnose_modal_atlas" ...
    ]);
assertObsoleteModalAtlasLowFrequencyEntrypointsAreAbsent(repoRoot);
assertMaintainedDocsContain(maintainedHelpers, maintainedWorkflows, maintainedDiagnostics);

fprintf('Maintained acoustoelastic IOP/HGO entrypoint path test passed. Optional wrapper targets verified when present.\n');
end

function validateLegacyTargetIfExampleWrapper(entryName, entryPath)
%VALIDATELEGACYTARGETIFEXAMPLEWRAPPER Check simple static legacy targets.

[~, ~, ext] = fileparts(entryPath);
if ext ~= ".m"
    return;
end

pathForCheck = strrep(entryPath, '\\', '/');
if ~contains(pathForCheck, '/examples/acoustoelastic_iop_hgo/')
    return;
end

text = fileread(entryPath);
if ~contains(text, 'aeRunLegacyScript')
    return;
end

marker = "fullfile(thisFolder, '";
markerStart = strfind(text, marker);
assert(~isempty(markerStart), 'Short example entrypoint %s calls aeRunLegacyScript but no static legacy target was parsed.', entryName);

entryFolder = fileparts(entryPath);
for j = 1:numel(markerStart)
    nameStart = markerStart(j) + strlength(marker);
    tail = extractAfter(text, nameStart - 1);
    nameEnd = strfind(tail, "')");
    assert(~isempty(nameEnd), 'Short example entrypoint %s has an incomplete legacy target expression.', entryName);
    targetName = extractBefore(tail, nameEnd(1));
    if ~endsWith(targetName, ".m")
        continue;
    end
    targetPath = fullfile(entryFolder, char(targetName));
    assert(exist(targetPath, 'file') == 2, ...
        'Short example entrypoint %s points to missing legacy target: %s', entryName, targetPath);
end
end

function assertExpectedWrappersUseLegacyRunner(wrapperNames)
for i = 1:numel(wrapperNames)
    entryPath = which(wrapperNames(i));
    assert(~isempty(entryPath), 'Expected AE wrapper is missing from path: %s', wrapperNames(i));
    text = fileread(entryPath);
    assert(contains(text, 'aeRunLegacyScript'), ...
        'Expected AE wrapper should delegate through aeRunLegacyScript: %s', wrapperNames(i));
end
end

function assertObsoleteModalAtlasLowFrequencyEntrypointsAreAbsent(repoRoot)
obsoletePaths = { ...
    fullfile(repoRoot, 'examples', 'acoustoelastic_iop_hgo', 'diagnostics', 'diagnose_modal_atlas_lowfreq.m'), ...
    fullfile(repoRoot, 'examples', 'acoustoelastic_iop_hgo', 'diagnostics', 'diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m')};
for i = 1:numel(obsoletePaths)
    assert(~isfile(obsoletePaths{i}), 'Obsolete low-frequency modal-atlas entrypoint should not exist: %s', obsoletePaths{i});
end
assert(isempty(which('diagnose_modal_atlas_lowfreq')), ...
    'Obsolete diagnose_modal_atlas_lowfreq entrypoint should not be on the MATLAB path.');
end

function assertMaintainedDocsContain(maintainedHelpers, maintainedWorkflows, maintainedDiagnostics)
repoRoot = testRepositoryRoot(mfilename('fullpath'));
entrypointsText = fileread(fullfile(repoRoot, 'docs', 'repository', 'maintained_entrypoints.md'));
publicApiText = fileread(fullfile(repoRoot, 'docs', 'models', 'acoustoelastic_iop_hgo', 'active', 'public_api.md'));
readmeText = fileread(fullfile(repoRoot, 'docs', 'models', 'acoustoelastic_iop_hgo', 'README.md'));

for iName = 1:numel([maintainedHelpers, maintainedWorkflows, maintainedDiagnostics])
    entryName = [maintainedHelpers, maintainedWorkflows, maintainedDiagnostics];
    assert(contains(publicApiText, entryName(iName)), ...
        'public_api.md is missing maintained AE entrypoint/helper: %s', entryName(iName));
end

for iName = 1:numel([maintainedWorkflows, maintainedDiagnostics])
    entryName = [maintainedWorkflows, maintainedDiagnostics];
    assert(contains(entrypointsText, entryName(iName)), ...
        'maintained_entrypoints.md is missing maintained AE workflow/diagnostic: %s', entryName(iName));
    assert(contains(readmeText, entryName(iName)), ...
        'README.md is missing maintained AE workflow/diagnostic: %s', entryName(iName));
end
end
