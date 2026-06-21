function [sweepResults, sweepSummary] = mrlfeRunSweepExample(sweepName, branchName, varargin)
%MRLFERUNSWEEPEXAMPLE Run a maintained mRLFE sweep example.
%
% This helper centralizes the shared setup used by the public mRLFE sweep
% entrypoints. Public scripts should define only the sweep and branch.
%
% Example:
%   [S, T] = mrlfeRunSweepExample("viscosity", "A0Like", "AssignToBase", true);

p = inputParser;
addRequired(p, 'sweepName', @(x)ischar(x) || isstring(x));
addRequired(p, 'branchName', @(x)ischar(x) || isstring(x));
addParameter(p, 'AssignToBase', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'NewFigure', true, @(x)islogical(x) || isnumeric(x));
parse(p, sweepName, branchName, varargin{:});

sweepName = lower(string(p.Results.sweepName));
branchName = string(p.Results.branchName);

[sweepSpec, caseInfo] = mrlfeMakeSweepSpec(sweepName);
params = mrlfeDefaultSweepParams();
options = mrlfeDefaultSweepOptions(branchName, 'EtaS', caseInfo.fixedEtaS);

sweepResults = runParametricSweep(params, options, sweepSpec);

plotTitle = sprintf('Viscoelastic %s Cp sensitivity to %s', ...
    branchName, caseInfo.titleParameter);

plotParametricSweepCp(sweepResults, caseInfo.modelName, branchName, ...
    'Title', plotTitle, ...
    'NewFigure', logical(p.Results.NewFigure), ...
    'ShowLastValidPoint', caseInfo.showLastValidPoint);

sweepSummary = summarizeParametricSweepBranch(sweepResults, ...
    caseInfo.modelName, branchName);

if logical(p.Results.AssignToBase)
    [resultName, summaryName] = mrlfeSweepWorkspaceNames(sweepName, branchName);
    assignin('base', resultName, sweepResults);
    assignin('base', summaryName, sweepSummary);
end
end

function [resultName, summaryName] = mrlfeSweepWorkspaceNames(sweepName, branchName)
sweepName = lower(string(sweepName));
branchName = string(branchName);

switch sweepName
    case "viscosity"
        prefix = "ViscositySweep";
    case "stiffness"
        prefix = "StiffnessSweep";
    case "thickness"
        prefix = "ThicknessSweep";
    otherwise
        error('Unsupported mRLFE sweepName "%s".', sweepName);
end

if branchName == "A0Like" && sweepName == "viscosity"
    resultName = "ViscositySweepResults";
    summaryName = "ViscositySweepSummary";
    return;
end

resultName = sprintf('%s%sResults', prefix, branchName);
summaryName = sprintf('%s%sSummary', prefix, branchName);
end
