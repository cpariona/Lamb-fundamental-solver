function test_acoustoelastic_iop_hgo_short_entrypoints()
%TEST_ACOUSTOELASTIC_IOP_HGO_SHORT_ENTRYPOINTS Verify maintained AE entrypoints are on path.
%
% This is a path-level smoke test only. It does not execute heavy diagnostics.
% Optional historical diagnostics are checked only while they are still present;
% they are not part of the primary maintained surface.

maintainedNames = [ ...
    "aeOutputFolder", ...
    "aeResolveResultFile", ...
    "aeRunLegacyScript", ...
    "aeClassifyAmbiguityRegime", ...
    "run_atlas_branch", ...
    "sweep_iop", ...
    "sweep_mu", ...
    "sweep_mu_iop", ...
    "compare_atlasA0_vs_raw_branch1", ...
    "validate_atlas_raw_grid", ...
    "diagnose_raw_branch_corner", ...
    "diagnose_branch_families", ...
    "diagnose_sweep_reliability", ...
    "diagnose_atlas_truncation", ...
    "diagnose_idA0_plausibility", ...
    "diagnose_grid_start_sensitivity" ...
    ];

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
    "diagnose_modal_atlas_lowfreq", ...
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
    "diagnose_modal_atlas", ...
    "diagnose_modal_atlas_lowfreq" ...
    ]);
assertMaintainedDocsContain(maintainedNames);

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

function assertMaintainedDocsContain(maintainedNames)
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
docPaths = [ ...
    string(fullfile(repoRoot, 'docs', 'maintained_entrypoints.md')), ...
    string(fullfile(repoRoot, 'docs', 'acoustoelastic_iop_hgo', 'public_api.md')), ...
    string(fullfile(repoRoot, 'docs', 'acoustoelastic_iop_hgo', 'README.md')) ...
    ];
for iDoc = 1:numel(docPaths)
    text = fileread(docPaths(iDoc));
    for iName = 1:numel(maintainedNames)
        assert(contains(text, maintainedNames(iName)), ...
            'Maintained AE documentation %s is missing entrypoint/helper: %s', docPaths(iDoc), maintainedNames(iName));
    end
end
end
