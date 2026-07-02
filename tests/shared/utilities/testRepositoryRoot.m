function repoRoot = testRepositoryRoot(anchorFile)
%TESTREPOSITORYROOT Resolve the repository root from a test file path.
%
%   repoRoot = testRepositoryRoot(anchorFile) walks upward from anchorFile
%   until it finds the repository root marker files used by the test suite.

if nargin < 1 || isempty(anchorFile)
    anchorFile = mfilename('fullpath');
end

currentFolder = fileparts(char(string(anchorFile)));

while true
    if isfile(fullfile(currentFolder, 'startup.m')) && isfolder(fullfile(currentFolder, 'tests'))
        repoRoot = currentFolder;
        return;
    end

    parentFolder = fileparts(currentFolder);
    if strcmp(parentFolder, currentFolder)
        error('testRepositoryRoot:NotFound', ...
            'Could not resolve the repository root from "%s".', anchorFile);
    end

    currentFolder = parentFolder;
end
end
