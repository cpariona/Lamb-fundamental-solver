function assertOceInversionProducerPath(oceRepositoryRoot)
%ASSERTOCEINVERSIONPRODUCERPATH Require the configured OCE checkout on path.
% Adding a checkout at the end of the MATLAB path must not select an earlier
% +oce package from another checkout for recovery or acquisition metadata.
srcRoot = fullfile(string(oceRepositoryRoot), "src");
srcFile = java.io.File(char(srcRoot));
if ~srcFile.isAbsolute()
    srcFile = java.io.File(char(fullfile(pwd, srcRoot)));
end
srcRoot = string(srcFile.getCanonicalPath());
apis = ["oce.results.recoverSummaryObservations"; "oce.io.loadAcquisitionTable"];
relativeFiles = [fullfile("+oce", "+results", "recoverSummaryObservations.m"); ...
    fullfile("+oce", "+io", "loadAcquisitionTable.m")];
for k = 1:numel(apis)
    expected = string(fullfile(srcRoot, relativeFiles(k)));
    actual = string(which(char(apis(k))));
    assert(isfile(expected), 'lamb:workflow:OceRepository', ...
        'Configured OCE checkout is missing %s: %s', apis(k), expected);
    expected = string(java.io.File(char(expected)).getCanonicalPath());
    if strlength(actual)>0
        actual = string(java.io.File(char(actual)).getCanonicalPath());
    end
    if ispc
        matches = strcmpi(actual, expected);
    else
        matches = strcmp(actual, expected);
    end
    assert(matches, 'lamb:workflow:OceRepositoryMismatch', ...
        'Configured OCE checkout does not own %s on the MATLAB path: %s', ...
        apis(k), actual);
end
end
