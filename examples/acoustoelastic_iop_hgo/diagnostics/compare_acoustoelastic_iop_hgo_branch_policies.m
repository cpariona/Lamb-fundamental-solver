clear; clc; close all;
launchFolder = pwd;
startup

%COMPARE_ACOUSTOELASTIC_IOP_HGO_BRANCH_POLICIES Compare current atlas policy against legacy tracking.
% Legacy descriptive implementation. Prefer the short entrypoint:
%   compare_branch_policies
%
% New outputs are written to:
%   Results/ae_iop_hgo/branch_policy_compare

baseParams = struct();
baseParams.R = 7.8e-3;                  % m
baseParams.thickness = 550e-6;          % m
baseParams.mu = 50e3;                   % Pa
baseParams.k1 = 25e3;                   % Pa
baseParams.k2 = 100;                    % dimensionless
baseParams.rho = 1060;                  % kg/m^3
baseParams.rhoF = 1000;                 % kg/m^3
baseParams.fluidBulkModulus = 2.2e9;    % Pa
baseParams.frequency = logspace(log10(100), log10(35e3), 100); % Hz
baseParams.IOP = 15 * 133.322;          % Pa

policyList = makePolicyList();
comparisonRows = [];
resultByPolicy = struct();

fprintf('\nAcoustoelastic IOP/HGO branch-policy diagnostic\n');
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Fixed IOP: %.1f mmHg\n\n', baseParams.IOP/133.322);

for i = 1:numel(policyList)
    policy = policyList(i);
    fprintf('Running policy %d/%d: %s\n', i, numel(policyList), policy.name);

    result = policy.runner(baseParams, policy.options);
    resultByPolicy.(matlab.lang.makeValidName(policy.name)) = result;

    row = makeComparisonRow(policy.name, policy.description, result);
    comparisonRows = [comparisonRows; row]; %#ok<AGROW>
end

if isempty(comparisonRows)
    comparisonTable = table();
else
    comparisonTable = struct2table(comparisonRows);
end

disp(comparisonTable);

outputFolder = aeOutputFolder(launchFolder, 'branch_policy_compare');

writetable(comparisonTable, fullfile(outputFolder, 'branch_policy_compare_summary.csv'));
save(fullfile(outputFolder, 'branch_policy_compare_workspace.mat'), ...
    'baseParams', 'policyList', 'resultByPolicy', 'comparisonTable', 'launchFolder', '-v7.3');

plotPolicyComparison(baseParams.frequency, resultByPolicy, policyList, outputFolder);

fprintf('\nData files written to:\n%s\n', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOBranchPolicyComparison', resultByPolicy);
assignin('base', 'AcoustoelasticIOPHGOBranchPolicyComparisonTable', comparisonTable);

function policyList = makePolicyList()
policyList = struct([]);

opt = defaultAcoustoelasticIOPHGOOptions();
opt.M54_variant = "corrected";
opt.normalizeRows = false;
opt.usePhysicalCpWindow = false;
opt.atlasBranchPolicy = "atlasA0";
opt.atlasNumYPoints = 1000;
opt.atlasTopNMinima = 18;
policyList(1).name = "atlas_a0_policy";
policyList(1).description = "Maintained atlas-based A0 policy";
policyList(1).options = opt;
policyList(1).runner = @(params, options) solveAcoustoelasticIOPHGOBranch(params, options);

opt = defaultAcoustoelasticIOPHGOOptions();
opt.M54_variant = "corrected";
opt.normalizeRows = false;
opt.usePhysicalCpWindow = true;
opt.branch = "A0";
opt.trackingDirection = "backward";
opt.trackingMethod = "globalScan";
policyList(2).name = "legacy_backward_global_scan";
policyList(2).description = "Earlier corrected + A0 + backward globalScan diagnostic";
policyList(2).options = opt;
policyList(2).runner = @(params, options) solveAcoustoelasticIOPHGODispersion(params, options);
end

function row = makeComparisonRow(policyName, description, result)
row = struct();
row.PolicyName = string(policyName);
row.Description = string(description);
if isfield(result, 'reliability')
    rel = result.reliability;
    row.ValidFraction = getStructField(rel, 'ValidFraction', nan);
    row.ValidPoints = getStructField(rel, 'ValidPoints', nan);
    row.TotalPoints = getStructField(rel, 'TotalPoints', nan);
    row.LastValidFrequency_kHz = getStructField(rel, 'LastValidFrequency_kHz', nan);
    row.FirstMissingFrequency_kHz = getStructField(rel, 'FirstMissingFrequency_kHz', nan);
    row.A0StartFilterPassed = getStructField(rel, 'A0StartFilterPassed', false);
    row.SelectionFallbackUsed = getStructField(rel, 'SelectionFallbackUsed', false);
    row.YStart = getStructField(rel, 'YStart', nan);
    row.StartRank = getStructField(rel, 'StartRank', nan);
else
    Cp = getStructField(result, 'Cp', []);
    validCp = isfinite(Cp);
    row.ValidFraction = nnz(validCp) / max(numel(Cp), 1);
    row.ValidPoints = nnz(validCp);
    row.TotalPoints = numel(Cp);
    row.LastValidFrequency_kHz = estimateLastValidFrequency(result, validCp);
    row.FirstMissingFrequency_kHz = estimateFirstMissingFrequency(result, validCp);
    row.A0StartFilterPassed = false;
    row.SelectionFallbackUsed = false;
    row.YStart = nan;
    row.StartRank = nan;
end
end

function value = estimateLastValidFrequency(result, validCp)
frequency = getStructField(result, 'frequency', []);
if isempty(frequency) || ~any(validCp)
    value = nan;
else
    f = frequency(:);
    value = f(find(validCp(:), 1, 'last')) / 1e3;
end
end

function value = estimateFirstMissingFrequency(result, validCp)
frequency = getStructField(result, 'frequency', []);
if isempty(frequency) || all(validCp)
    value = nan;
else
    f = frequency(:);
    idx = find(~validCp(:), 1, 'first');
    value = f(idx) / 1e3;
end
end

function plotPolicyComparison(frequency, resultByPolicy, policyList, outputFolder)
figure('Color', 'w', 'Name', 'Acoustoelastic IOP/HGO branch policy comparison');
hold on; grid on;
for i = 1:numel(policyList)
    key = matlab.lang.makeValidName(policyList(i).name);
    result = resultByPolicy.(key);
    if ~isfield(result, 'Cp')
        continue;
    end
    Cp = result.Cp;
    if isfield(result, 'validCp')
        Cp(~result.validCp) = nan;
    end
    plot(frequency/1e3, Cp, 'LineWidth', 1.5, 'DisplayName', strrep(policyList(i).name, '_', ' '));
end
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title('Acoustoelastic IOP/HGO branch-policy diagnostic');
legend('Location', 'best');
hold off;
saveas(gcf, fullfile(outputFolder, 'branch_policy_compare.png'));
saveas(gcf, fullfile(outputFolder, 'branch_policy_compare.fig'));
end

function value = getStructField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end
