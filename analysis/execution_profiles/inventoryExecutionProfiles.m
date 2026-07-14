function inventory = inventoryExecutionProfiles(varargin)
%INVENTORYEXECUTIONPROFILES Build a repository inventory for execution profiles.
%
% inventory = inventoryExecutionProfiles writes a table with occurrences of
% profile, atlas, route, and optimizer tokens. The helper is intentionally
% read-only and does not infer contracts from archived documents.

p = inputParser;
addParameter(p, 'WriteCsv', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'OutputFile', fullfile('analysis', 'execution_profiles', 'execution_profile_inventory.csv'), ...
    @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

root = testRepositoryRoot();
tokens = [ ...
    "Fast", "Balanced", "Robust", "robustness", "executionProfile", ...
    "solverPreset", "atlasPreset", "fitAtlasPreset", ...
    "atlasNumYPoints", "atlasTopNMinima", "atlasInitializationNumFrequencyPoints", ...
    "mrlfeFitAtlasCpScanPoints", "mrlfeAdaptiveCpScanPoints", ...
    "mrlfeViscoAtlasCpScanPoints", "mrlfeA0DPCpScanPoints", ...
    "MaxIter", "MaxFunEvals", "TolX"];

files = collectTextFiles(root);
rows = {};
for iFile = 1:numel(files)
    relFile = erase(string(files{iFile}), string(root) + filesep);
    text = fileread(files{iFile});
    lines = splitlines(string(text));
    for iToken = 1:numel(tokens)
        token = tokens(iToken);
        hitLines = find(contains(lines, token));
        for iHit = 1:numel(hitLines)
            lineNumber = hitLines(iHit);
            lineText = strtrim(lines(lineNumber));
            rows(end+1, :) = {relFile, lineNumber, token, lineText, ...
                classifyModel(relFile), classifySurface(relFile), classifyOrigin(relFile), ...
                classifyRisk(relFile, token), initialRecommendation(relFile, token)}; %#ok<AGROW>
        end
    end
end

inventory = cell2table(rows, 'VariableNames', ...
    {'File', 'Line', 'Token', 'LineText', 'Model', 'Surface', 'Origin', ...
    'RiskOfChange', 'InitialRecommendation'});

if logical(p.Results.WriteCsv)
    outputFile = fullfile(root, char(p.Results.OutputFile));
    writetable(inventory, outputFile);
    fprintf('Wrote %d inventory rows to %s\n', height(inventory), outputFile);
end
end

function files = collectTextFiles(root)
patterns = {'*.m', '*.md', '*.txt'};
files = {};
for i = 1:numel(patterns)
    listing = dir(fullfile(root, '**', patterns{i}));
    for j = 1:numel(listing)
        if listing(j).isdir
            continue;
        end
        path = fullfile(listing(j).folder, listing(j).name);
        if contains(path, [filesep '.git' filesep])
            continue;
        end
        files{end+1} = path; %#ok<AGROW>
    end
end
end

function model = classifyModel(file)
file = lower(string(file));
if contains(file, "mrlfe")
    model = "mRLFE";
elseif contains(file, "acoustoelastic") || contains(file, "ae_iop") || contains(file, "iop_hgo")
    model = "AE";
elseif contains(file, "rayleigh_lamb") || contains(file, "rl")
    model = "RL";
else
    model = "shared";
end
end

function surface = classifySurface(file)
file = lower(string(file));
if contains(file, "fittool") || contains(file, [filesep "fitting" filesep]) || contains(file, "fit_")
    surface = "Fit";
elseif contains(file, "sweeptool") || contains(file, [filesep "sweeps" filesep]) || contains(file, "sweep")
    surface = "Sweep";
elseif contains(file, "lambfundamental_gui") || contains(file, [filesep "gui" filesep])
    surface = "Main";
elseif contains(file, [filesep "tests" filesep])
    surface = "test";
elseif contains(file, [filesep "examples" filesep])
    surface = "example";
elseif contains(file, [filesep "docs" filesep])
    surface = "doc";
else
    surface = "API";
end
end

function origin = classifyOrigin(file)
file = lower(string(file));
if contains(file, "default")
    origin = "Default";
elseif contains(file, "adapter") || contains(file, "gui")
    origin = "GUI/adapter";
elseif contains(file, "test")
    origin = "test";
elseif contains(file, "diagnos")
    origin = "diagnostic";
else
    origin = "solver/API";
end
end

function risk = classifyRisk(file, token)
file = lower(string(file));
token = string(token);
if contains(file, [filesep "archive" filesep]) || contains(file, [filesep "docs" filesep])
    risk = "low";
elseif contains(token, ["MaxIter", "MaxFunEvals", "TolX", "atlasNumYPoints", "atlasTopNMinima"])
    risk = "high";
elseif contains(file, [filesep "tests" filesep])
    risk = "medium";
else
    risk = "high";
end
end

function rec = initialRecommendation(file, token)
file = lower(string(file));
token = string(token);
if contains(file, [filesep "archive" filesep])
    rec = "preserve as historical context";
elseif contains(token, ["executionProfile", "solverPreset", "atlasPreset"])
    rec = "investigate centralization";
elseif contains(token, ["MaxIter", "MaxFunEvals", "TolX"])
    rec = "separate optimizer profile";
else
    rec = "document effective behavior";
end
end
