function results = measureTestRuntime(entrypoints, varargin)
%MEASURETESTRUNTIME Measure repository test or runner entrypoints.
%   RESULTS = MEASURETESTRUNTIME(NAMES) measures each named entrypoint once.
%   RESULTS = MEASURETESTRUNTIME(NAMES, 'EntryType', "runner") requires each
%   entrypoint to resolve to a maintained runner under tests/runners/.
%
%   Name-value options:
%     EntryType          "auto" (default), "test", or "runner"
%     RepeatCount        positive integer (default 1)
%     ContinueOnFailure logical scalar (default true)
%     WriteCsv           logical scalar (default false)
%     OutputFile         repository-relative CSV path
%     TimeoutSeconds     descriptive advisory value (default NaN)
%
%   This utility executes entries in the current MATLAB process. It does not
%   provide a hard timeout and records HardTimeoutAvailable=false. Use one
%   entry per isolated `matlab -batch` process when OS-level termination is
%   required. Durations are descriptive and never determine pass/fail status.

parser = inputParser;
parser.addRequired('entrypoints', @(x) ischar(x) || isstring(x) || iscellstr(x));
parser.addParameter('EntryType', "auto", @(x) any(strcmpi(string(x), ["auto", "test", "runner"])));
parser.addParameter('RepeatCount', 1, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 1 && fix(x) == x);
parser.addParameter('ContinueOnFailure', true, @(x) islogical(x) && isscalar(x));
parser.addParameter('WriteCsv', false, @(x) islogical(x) && isscalar(x));
parser.addParameter('OutputFile', "Results/test_runtime/test_runtime_measurements.csv", ...
    @(x) ischar(x) || (isstring(x) && isscalar(x)));
parser.addParameter('TimeoutSeconds', NaN, ...
    @(x) isnumeric(x) && isscalar(x) && (isnan(x) || (isfinite(x) && x > 0)));
parser.parse(entrypoints, varargin{:});
options = parser.Results;

if ischar(entrypoints)
    names = string({entrypoints});
else
    names = string(entrypoints(:));
end
names = sort(unique(names));
if isempty(names) || any(strlength(names) == 0)
    error('testRuntime:InvalidEntrypoint', 'Entrypoint names must be nonempty.');
end

repoRoot = findRepositoryRoot(mfilename('fullpath'));
measuredCommit = gitHead(repoRoot);
originalFolder = pwd;
originalPath = path;
sessionCleanup = onCleanup(@() restoreSession(originalFolder, originalPath));

rowCount = numel(names);
Entrypoint = strings(rowCount, 1);
Path = strings(rowCount, 1);
EntryType = strings(rowCount, 1);
OwningArea = strings(rowCount, 1);
Category = strings(rowCount, 1);
RepeatCountRequested = repmat(options.RepeatCount, rowCount, 1);
RepeatCountCompleted = zeros(rowCount, 1);
Status = strings(rowCount, 1);
Passed = false(rowCount, 1);
ElapsedSecondsMedian = nan(rowCount, 1);
ElapsedSecondsMin = nan(rowCount, 1);
ElapsedSecondsMax = nan(rowCount, 1);
ErrorIdentifier = strings(rowCount, 1);
ErrorMessage = strings(rowCount, 1);
HardTimeoutAvailable = false(rowCount, 1);
TimeoutSeconds = repmat(options.TimeoutSeconds, rowCount, 1);
MeasuredAtCommit = repmat(measuredCommit, rowCount, 1);
MATLABRelease = repmat(string(version('-release')), rowCount, 1);
Platform = repmat(string(computer), rowCount, 1);
Notes = repmat("In-process measurement; no hard timeout enforcement.", rowCount, 1);

for i = 1:rowCount
    name = names(i);
    metadata = resolveMetadata(repoRoot, name, string(options.EntryType));
    Entrypoint(i) = name;
    Path(i) = metadata.Path;
    EntryType(i) = metadata.EntryType;
    OwningArea(i) = metadata.OwningArea;
    Category(i) = metadata.Category;

    durations = nan(options.RepeatCount, 1);
    firstError = [];
    for repeatIndex = 1:options.RepeatCount
        restoreEntryState(repoRoot, originalPath);
        started = tic;
        try
            executeEntry(repoRoot, metadata.Path, name, metadata.EntryType);
            durations(repeatIndex) = toc(started);
            RepeatCountCompleted(i) = repeatIndex;
        catch exception
            durations(repeatIndex) = toc(started);
            RepeatCountCompleted(i) = repeatIndex;
            firstError = exception;
            break
        end
        restoreEntryState(repoRoot, originalPath);
    end
    restoreEntryState(repoRoot, originalPath);

    completedDurations = durations(1:RepeatCountCompleted(i));
    if ~isempty(completedDurations)
        ElapsedSecondsMedian(i) = median(completedDurations);
        ElapsedSecondsMin(i) = min(completedDurations);
        ElapsedSecondsMax(i) = max(completedDurations);
    end

    if isempty(firstError)
        Status(i) = "passed";
        Passed(i) = true;
    else
        Status(i) = "failed";
        ErrorIdentifier(i) = string(firstError.identifier);
        ErrorMessage(i) = sanitizeMessage(firstError.message, repoRoot);
        if ~options.ContinueOnFailure
            rethrow(firstError)
        end
    end
end

results = table(Entrypoint, Path, EntryType, OwningArea, Category, ...
    RepeatCountRequested, RepeatCountCompleted, Status, Passed, ...
    ElapsedSecondsMedian, ElapsedSecondsMin, ElapsedSecondsMax, ...
    ErrorIdentifier, ErrorMessage, HardTimeoutAvailable, TimeoutSeconds, ...
    MeasuredAtCommit, MATLABRelease, Platform, Notes);
maybeWrite(results, options, repoRoot);
end

function metadata = resolveMetadata(repoRoot, name, requestedType)
absolutePath = string(which(name));
if absolutePath == ""
    error('testRuntime:EntrypointNotFound', ...
        'Entrypoint does not resolve on the maintained MATLAB path: %s', name);
end

normalizedRoot = replace(string(repoRoot), "\", "/") + "/";
normalizedPath = replace(absolutePath, "\", "/");
relativePath = erase(normalizedPath, normalizedRoot);
if relativePath == normalizedPath || ~startsWith(relativePath, "tests/")
    error('testRuntime:EntrypointOutsideTests', ...
        'Entrypoint must resolve under tests/: %s', absolutePath);
end

if startsWith(name, "test_")
    resolvedType = "test";
elseif startsWith(name, "run_")
    resolvedType = "runner";
else
    error('testRuntime:UnsupportedEntrypoint', ...
        'Entrypoint must use a test_ or run_ name: %s', name);
end
if requestedType ~= "auto" && requestedType ~= resolvedType
    error('testRuntime:EntryTypeMismatch', ...
        'Entrypoint %s resolves as %s, not %s.', name, resolvedType, requestedType);
end

parts = split(relativePath, "/");
owningArea = parts(2);
metadata = struct('Path', relativePath, 'EntryType', resolvedType, ...
    'OwningArea', owningArea, 'Category', resolvedType);
end

function executeEntry(repoRoot, relativePath, entrypoint, entryType)
absolutePath = fullfile(repoRoot, strrep(char(relativePath), '/', filesep));
source = fileread(absolutePath);
isFunctionTestSuite = entryType == "test" && ...
    ~isempty(regexp(source, '(?m)^\s*function\s+tests\s*=', 'once'));
isFunctionFile = ~isempty(regexp(source, '(?m)^\s*function\b', 'once'));

if isFunctionTestSuite
    unitResults = runtests(absolutePath);
    assertSuccess(unitResults);
elseif isFunctionFile
    feval(char(entrypoint));
else
    executeScriptFile(absolutePath);
end
end

function executeScriptFile(absolutePath)
% A separate function workspace contains script-side clear/variable effects.
run(absolutePath);
end

function restoreEntryState(repoRoot, originalPath)
try
    close all force;
catch
end
path(originalPath);
cd(repoRoot);
end

function restoreSession(originalFolder, originalPath)
try
    close all force;
catch
end
path(originalPath);
cd(originalFolder);
end

function maybeWrite(results, options, repoRoot)
if ~options.WriteCsv
    return
end
outputFile = string(options.OutputFile);
if isAbsolutePath(outputFile)
    error('testRuntime:AbsoluteOutputPath', ...
        'OutputFile must be repository-relative to keep evidence portable.');
end
absoluteOutput = fullfile(repoRoot, strrep(char(outputFile), '/', filesep));
outputFolder = fileparts(absoluteOutput);
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
writetable(sortrows(results, 'Entrypoint'), absoluteOutput);
fprintf('Wrote %s\n', outputFile);
end

function tf = isAbsolutePath(pathValue)
pathValue = char(pathValue);
tf = startsWith(pathValue, '/') || startsWith(pathValue, '\') || ...
    ~isempty(regexp(pathValue, '^[A-Za-z]:[\\/]', 'once'));
end

function message = sanitizeMessage(rawMessage, repoRoot)
message = string(rawMessage);
message = replace(message, string(repoRoot), "<repo>");
message = replace(message, [newline, char(13)], " ");
message = regexprep(message, '\s+', ' ');
message = strip(message);
end

function root = findRepositoryRoot(anchorFile)
folder = fileparts(anchorFile);
while true
    if isfolder(fullfile(folder, '.git')) && isfile(fullfile(folder, 'startup.m'))
        root = folder;
        return
    end
    parent = fileparts(folder);
    if strcmp(parent, folder)
        error('testRuntime:RepositoryRootNotFound', ...
            'Could not locate repository root from %s.', anchorFile);
    end
    folder = parent;
end
end

function sha = gitHead(repoRoot)
command = sprintf('git -C "%s" rev-parse HEAD', repoRoot);
[status, output] = system(command);
if status ~= 0
    sha = "unknown";
else
    sha = strip(string(output));
end
end
