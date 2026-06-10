function summaryTable = summarizeParametricSweepBranch(sweepResults, modelName, branchName, varargin)
%SUMMARIZEPARAMETRICSWEEPBRANCH Summarize valid Cp range for a sweep branch.
%
%   summaryTable = summarizeParametricSweepBranch(sweepResults, modelName, branchName)
%
% The function reads the output of runParametricSweep and extracts one
% model/branch pair from every sweep case. It reports the number of valid Cp
% points, the frequency range reached by the branch, Cp range, and elapsed
% solver time.
%
% Examples:
%   T = summarizeParametricSweepBranch(S, "mRLFEHanViscoRealK", "A0Like");
%   T = summarizeParametricSweepBranch(S, "mRLFEElasticRealK", "S0Like");
%   T = summarizeParametricSweepBranch(S, "RayleighLamb", "A0");
%
% Optional name-value arguments:
%   'Print'              true/false, display table in command window.
%   'ReachedToleranceHz' tolerance used to decide whether fmax was reached.

p = inputParser;
addParameter(p, 'Print', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'ReachedToleranceHz', 1e-9, @(x)isnumeric(x) && isscalar(x));
parse(p, varargin{:});

modelName = string(modelName);
branchName = string(branchName);

n = numel(sweepResults.results);
caseIndex = (1:n).';

parameterValue = nan(n, 1);
displayValue = nan(n, 1);
validCpPoints = zeros(n, 1);
totalPoints = zeros(n, 1);
firstValidFrequency_Hz = nan(n, 1);
lastValidFrequency_Hz = nan(n, 1);
maxValidFrequency_Hz = nan(n, 1);
branchFmax_Hz = nan(n, 1);
reachedFmax = false(n, 1);
minCp_mps = nan(n, 1);
maxCp_mps = nan(n, 1);
firstValidCp_mps = nan(n, 1);
lastValidCp_mps = nan(n, 1);
elapsedSeconds = nan(n, 1);

if isfield(sweepResults, 'values')
    parameterValue = sweepResults.values(:);
end
if isfield(sweepResults, 'displayValues')
    displayValue = sweepResults.displayValues(:);
else
    displayValue = parameterValue;
end
if isfield(sweepResults, 'elapsedSeconds')
    elapsedSeconds = sweepResults.elapsedSeconds(:);
end

for i = 1:n
    result = sweepResults.results{i};
    branch = extractSweepBranch(result, modelName, branchName);

    if isempty(branch) || ~isfield(branch, 'frequency') || ~isfield(branch, 'Cp')
        continue;
    end

    freq = branch.frequency(:);
    cp = branch.Cp(:);
    finiteFreq = isfinite(freq);
    finiteCp = isfinite(cp);
    valid = getBranchValidityMask(branch) & finiteFreq & finiteCp;

    totalPoints(i) = numel(cp);

    if any(finiteFreq)
        branchFmax_Hz(i) = max(freq(finiteFreq));
    end

    if any(valid)
        validCpPoints(i) = nnz(valid);
        validFreq = freq(valid);
        validCp = cp(valid);

        firstValidFrequency_Hz(i) = validFreq(1);
        lastValidFrequency_Hz(i) = validFreq(end);
        maxValidFrequency_Hz(i) = max(validFreq);
        minCp_mps(i) = min(validCp);
        maxCp_mps(i) = max(validCp);
        firstValidCp_mps(i) = validCp(1);
        lastValidCp_mps(i) = validCp(end);

        if isfinite(branchFmax_Hz(i))
            reachedFmax(i) = maxValidFrequency_Hz(i) >= ...
                branchFmax_Hz(i) - p.Results.ReachedToleranceHz;
        end
    end
end

summaryTable = table(caseIndex, parameterValue, displayValue, ...
    validCpPoints, totalPoints, firstValidFrequency_Hz, ...
    lastValidFrequency_Hz, maxValidFrequency_Hz, branchFmax_Hz, ...
    reachedFmax, minCp_mps, maxCp_mps, firstValidCp_mps, ...
    lastValidCp_mps, elapsedSeconds, ...
    'VariableNames', {'CaseIndex', 'ParameterValue', 'DisplayValue', ...
    'ValidCpPoints', 'TotalPoints', 'FirstValidFrequency_Hz', ...
    'LastValidFrequency_Hz', 'MaxValidFrequency_Hz', 'BranchFmax_Hz', ...
    'ReachedFmax', 'MinCp_mps', 'MaxCp_mps', 'FirstValidCp_mps', ...
    'LastValidCp_mps', 'ElapsedSeconds'});

summaryTable.Properties.Description = sprintf('%s / %s parametric sweep summary', ...
    modelName, branchName);

summaryTable.Properties.UserData = struct( ...
    'modelName', modelName, ...
    'branchName', branchName, ...
    'parameter', getSweepFieldAsString(sweepResults, 'parameter'), ...
    'label', getSweepSpecFieldAsString(sweepResults, 'label'), ...
    'units', getSweepSpecFieldAsString(sweepResults, 'units'));

if p.Results.Print
    fprintf('\nParametric sweep branch summary: %s / %s\n', modelName, branchName);
    printSweepDescriptor(sweepResults);
    disp(summaryTable);
end
end

function branch = extractSweepBranch(result, modelName, branchName)
branch = [];
modelName = string(modelName);
branchName = string(branchName);

if modelName == "RayleighLamb"
    if isfield(result, 'modes') && isfield(result.modes, char(branchName))
        branch = result.modes.(char(branchName));
    end
    return;
end

if isfield(result, 'models') && isfield(result.models, char(modelName)) && ...
        isfield(result.models.(char(modelName)), 'branches') && ...
        isfield(result.models.(char(modelName)).branches, char(branchName))
    branch = result.models.(char(modelName)).branches.(char(branchName));
end
end

function valid = getBranchValidityMask(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp(:) & isfinite(branch.Cp(:));
elseif isfield(branch, 'valid')
    valid = branch.valid(:) & isfinite(branch.Cp(:));
else
    valid = isfinite(branch.Cp(:));
end
end

function txt = getSweepFieldAsString(sweepResults, fieldName)
if isfield(sweepResults, fieldName)
    txt = string(sweepResults.(fieldName));
else
    txt = "";
end
end

function txt = getSweepSpecFieldAsString(sweepResults, fieldName)
if isfield(sweepResults, 'spec') && isfield(sweepResults.spec, fieldName)
    txt = string(sweepResults.spec.(fieldName));
else
    txt = "";
end
end

function printSweepDescriptor(sweepResults)
label = getSweepSpecFieldAsString(sweepResults, 'label');
units = getSweepSpecFieldAsString(sweepResults, 'units');
parameter = getSweepFieldAsString(sweepResults, 'parameter');

if strlength(label) == 0
    label = parameter;
end

if strlength(units) > 0
    fprintf('Sweep parameter: %s [%s]\n', label, units);
else
    fprintf('Sweep parameter: %s\n', label);
end
end
