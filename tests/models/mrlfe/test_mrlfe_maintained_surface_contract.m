function test_mrlfe_maintained_surface_contract()
%TEST_MRLFE_MAINTAINED_SURFACE_CONTRACT Guard the maintained mRLFE surface.

repoRoot = testRepositoryRoot(mfilename('fullpath'));
entrypointsText = string(fileread(fullfile(repoRoot, 'README.md')));
for name = ["lamb.models.mrlfe.mrlfeSolve", "lamb.models.mrlfe.mrlfeDefaultParameters", "lamb.models.mrlfe.mrlfeDefaultOptions"]
    assert(contains(entrypointsText, name), ...
        'Maintained entrypoint documentation is missing %s.', name);
end

fprintf('mRLFE maintained surface contract passed.\n');
end
