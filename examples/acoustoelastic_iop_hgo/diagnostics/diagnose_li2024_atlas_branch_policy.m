clear; clc; close all;
startup

% Li 2024 atlas-branch policy diagnostic.
%
% Goal:
%   Compare branch policies with evidence before deciding the final high-frequency
%   behavior of the atlas-branch solver. This script is diagnostic only; it does
%   not change the default solver policy.
%
% Policies:
%   strict                  : no interpolation, split on 5% Cp jumps.
%   smallGapInterpolation   : allow interpolation only across small frequency gaps.
%   softJumpStrict          : no interpolation, split on 8% Cp jumps.
%   monotoneReconnectDiagnostic : start from strict, then try local reconnection
%                                using nearby minima with monotone/continuity tests.
%
% Output folder:
%   Results/Li2024_atlas_branch_policy

outputFolder = fullfile(pwd, 'Results', 'Li2024_atlas_branch_policy');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

baseParams = struct();
baseParams.R = 7.8e-3;
baseParams.thickness = 550e-6;
baseParams.mu = 50e3;
baseParams.k1 = 25e3;
baseParams.k2 = 100;
baseParams.rho = 1060;
baseParams.rhoF = 1000;
baseParams.fluidBulkModulus = 2.2e9;
baseParams.frequency = logspace(log10(100), log10(35e3), 180);

IOP_mmHg = [5 10 15 20 25];

baseOptions = defaultLi2024AcoustoelasticOptions();
baseOptions.M54_variant = "corrected";
baseOptions.normalizeRows = false;
baseOptions.usePhysicalCpWindow = false;
baseOptions.minDimensionlessFrequency = 0.0;
baseOptions.atlasYMin = 0.003;
baseOptions.atlasYMax = 2.0;
baseOptions.atlasNumYPoints = 1000;
baseOptions.atlasTopNMinima = 18;
baseOptions.atlasMaxLogYJump = 0.075;
baseOptions.atlasMinBranchPoints = 12;
baseOptions.atlasRequireLowStartY = true;
baseOptions.atlasMaxStartY = 0.50;
baseOptions.atlasRequireStartRank = true;
baseOptions.atlasMaxStartRank = 3;
baseOptions.atlasFallbackToUnfilteredSelection = true;

policyList = makePolicyList(baseOptions);

summaryRows = [];
curveRows = [];
breakRows = [];
policyResults = struct();

fprintf('\nLi 2024 atlas-branch policy diagnostic\n');
fprintf('IOP values: %s mmHg\n', mat2str(IOP_mmHg));
fprintf('Policies: %s\n\n', strjoin(string({policyList.name}), ', '));

for p = 1:numel(policyList)
    policy = policyList(p);
    fprintf('Policy %d/%d: %s\n', p, numel(policyList), policy.name);

    for i = 1:numel(IOP_mmHg)
        params = baseParams;
        params.IOP = IOP_mmHg(i) * 133.322;

        result = solveDispersionIOPHGOAtlasBranch_Li2024(params, policy.options);
        rawResult = result;

        if policy.enableReconnect
            result = applyMonotoneReconnect(result, policy.reconnect);
        end

        key = matlab.lang.makeValidName(sprintf('%s_IOP_%g', policy.name, IOP_mmHg(i)));
        policyResults.(key).result = result;
        policyResults.(key).rawResult = rawResult;
        policyResults.(key).policy = policy;

        summaryRows = [summaryRows; makeSummaryRow(result, policy, IOP_mmHg(i))]; %#ok<AGROW>
        curveRows = [curveRows; makeCurveRows(result, policy, IOP_mmHg(i))]; %#ok<AGROW>
        breakRows = [breakRows; makeBreakpointRows(result, policy, IOP_mmHg(i))]; %#ok<AGROW>

        fprintf('  IOP %.0f mmHg: valid %d/%d, last %.2f kHz, selected branch %g\n', ...
            IOP_mmHg(i), nnz(result.validCp), numel(result.Cp), lastValidFrequency(result)/1e3, result.selectedBranchID);
    end
end

summaryTable = struct2table(summaryRows);
curveTable = struct2table(curveRows);
if isempty(breakRows)
    breakpointTable = table();
else
    breakpointTable = struct2table(breakRows);
end
comparisonTable = makePolicyComparisonTable(summaryTable);

writetable(summaryTable, fullfile(outputFolder, 'Li2024_branch_policy_summary.csv'));
writetable(curveTable, fullfile(outputFolder, 'Li2024_branch_policy_curves.csv'));
writetable(breakpointTable, fullfile(outputFolder, 'Li2024_branch_policy_breakpoints.csv'));
writetable(comparisonTable, fullfile(outputFolder, 'Li2024_branch_policy_comparison.csv'));

save(fullfile(outputFolder, 'Li2024_branch_policy_workspace.mat'), ...
    'policyResults', 'summaryTable', 'curveTable', 'breakpointTable', 'comparisonTable', ...
    'baseParams', 'baseOptions', 'policyList', 'IOP_mmHg', '-v7.3');

fprintf('\nPolicy summary\n');
disp(summaryTable);

fprintf('\nPolicy comparison\n');
disp(comparisonTable);

fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'Li2024BranchPolicySummary', summaryTable);
assignin('base', 'Li2024BranchPolicyCurves', curveTable);
assignin('base', 'Li2024BranchPolicyBreakpoints', breakpointTable);
assignin('base', 'Li2024BranchPolicyComparison', comparisonTable);
assignin('base', 'Li2024BranchPolicyResults', policyResults);

function policyList = makePolicyList(baseOptions)
policyList = struct([]);

opt = baseOptions;
opt.atlasSplitOnLargeCpJump = true;
opt.atlasMaxRelativeCpJump = 0.05;
opt.atlasAllowInterpolationAcrossGaps = false;
policyList(1).name = 'strict';
policyList(1).description = 'No interpolation; split branches on 5% Cp jumps';
policyList(1).options = opt;
policyList(1).enableReconnect = false;
policyList(1).reconnect = struct();

opt = baseOptions;
opt.atlasSplitOnLargeCpJump = true;
opt.atlasMaxRelativeCpJump = 0.05;
opt.atlasAllowInterpolationAcrossGaps = true;
opt.atlasMaxInterpolationFrequencyRatio = 1.08;
policyList(2).name = 'smallGapInterpolation';
policyList(2).description = 'Allow linear interpolation only across small frequency gaps';
policyList(2).options = opt;
policyList(2).enableReconnect = false;
policyList(2).reconnect = struct();

opt = baseOptions;
opt.atlasSplitOnLargeCpJump = true;
opt.atlasMaxRelativeCpJump = 0.08;
opt.atlasAllowInterpolationAcrossGaps = false;
policyList(3).name = 'softJumpStrict';
policyList(3).description = 'No interpolation; split branches on 8% Cp jumps';
policyList(3).options = opt;
policyList(3).enableReconnect = false;
policyList(3).reconnect = struct();

opt = baseOptions;
opt.atlasSplitOnLargeCpJump = true;
opt.atlasMaxRelativeCpJump = 0.05;
opt.atlasAllowInterpolationAcrossGaps = false;
policyList(4).name = 'monotoneReconnectDiagnostic';
policyList(4).description = 'Strict solution plus local reconnection by Cp/Y proximity and monotonicity';
policyList(4).options = opt;
policyList(4).enableReconnect = true;
r = struct();
r.maxRelCpJump = 0.055;
r.maxRelCpDrop = 0.015;
r.maxFrequencyRatio = 1.10;
r.maxCandidateRank = 5;
r.maxCandidateY = 1.20;
r.maxReconnectRun = 4;
policyList(4).reconnect = r;
end

function result = applyMonotoneReconnect(result, reconnect)
f = result.frequency(:).';
cp = result.Cp(:).';
valid = result.validCp(:).';
status = string(result.pointStatus(:).');
rank = result.nearestRank(:).';
branchID = result.nearestBranchID(:).';
objective = result.objective(:).';
reconnected = false(size(cp));

missingIdx = find(~valid);
for idx = missingIdx
    left = find(valid & f < f(idx), 1, 'last');
    right = find(valid & f > f(idx), 1, 'first');
    if isempty(left) || isempty(right)
        continue;
    end
    if f(right) / max(f(left), eps) > reconnect.maxFrequencyRatio
        continue;
    end
    runIdx = idx;
    while runIdx(1) > 1 && ~valid(runIdx(1)-1)
        runIdx = [runIdx(1)-1, runIdx]; %#ok<AGROW>
    end
    while runIdx(end) < numel(valid) && ~valid(runIdx(end)+1)
        runIdx = [runIdx, runIdx(end)+1]; %#ok<AGROW>
    end
    if numel(runIdx) > reconnect.maxReconnectRun
        continue;
    end

    candidates = result.minimaTable(result.minimaTable.Frequency_Hz == f(idx), :);
    if isempty(candidates)
        continue;
    end
    candidates = candidates(candidates.MinRank <= reconnect.maxCandidateRank & candidates.y <= reconnect.maxCandidateY, :);
    if isempty(candidates)
        continue;
    end

    predictedCp = interp1([f(left), f(right)], [cp(left), cp(right)], f(idx), 'linear');
    relToPred = abs(candidates.Cp_mps - predictedCp) ./ max(abs(predictedCp), eps);
    relToLeft = abs(candidates.Cp_mps - cp(left)) ./ max(abs(cp(left)), eps);
    relDropFromLeft = (cp(left) - candidates.Cp_mps) ./ max(abs(cp(left)), eps);
    relToRight = abs(cp(right) - candidates.Cp_mps) ./ max(abs(candidates.Cp_mps), eps);

    ok = relToPred <= reconnect.maxRelCpJump & relToLeft <= reconnect.maxRelCpJump & ...
        relToRight <= reconnect.maxRelCpJump & relDropFromLeft <= reconnect.maxRelCpDrop;
    if ~any(ok)
        continue;
    end
    candidates = candidates(ok, :);
    relToPred = relToPred(ok);
    [~, best] = min(relToPred + 0.02*candidates.MinRank);

    cp(idx) = candidates.Cp_mps(best);
    valid(idx) = true;
    reconnected(idx) = true;
    status(idx) = "reconnectedByPolicy";
    rank(idx) = candidates.MinRank(best);
    branchID(idx) = candidates.BranchID(best);
    objective(idx) = candidates.Objective(best);
end

result.Cp = cp;
result.validCp = valid;
result.pointStatus = status;
result.reconnectedByPolicy = reconnected;
result.nearestRank = rank;
result.nearestBranchID = branchID;
result.objective = objective;
result.diagnostics = summarizePolicyResult(result);
end

function row = makeSummaryRow(result, policy, iop)
valid = result.validCp & isfinite(result.Cp);
f = result.frequency;
cp = result.Cp;
row = struct();
row.Policy = string(policy.name);
row.PolicyDescription = string(policy.description);
row.IOP_mmHg = iop;
row.SelectedBranchID = result.selectedBranchID;
row.ValidPoints = nnz(valid);
row.TotalPoints = numel(cp);
row.ValidFraction = nnz(valid) / numel(cp);
row.FirstValidFrequency_kHz = firstValidFrequency(result)/1e3;
row.LastValidFrequency_kHz = lastValidFrequency(result)/1e3;
row.MissingPoints = nnz(~valid);
row.InterpolatedPoints = nnz(isfieldOrFalse(result, 'interpolatedCp'));
row.ReconnectedPoints = nnz(isfieldOrFalse(result, 'reconnectedByPolicy'));
row.MaxRelativeCpJump = maxRelativeJump(cp, valid);
row.MaxRelativeCpDrop = maxRelativeDrop(cp, valid);
row.MonotonicFrequencyScore = monotonicFrequencyScore(cp, valid);
row.CpAt1kHz_mps = interpValid(f, cp, valid, 1e3);
row.CpAt5kHz_mps = interpValid(f, cp, valid, 5e3);
row.CpAt10kHz_mps = interpValid(f, cp, valid, 10e3);
row.CpAt20kHz_mps = interpValid(f, cp, valid, 20e3);
row.CpAt30kHz_mps = interpValid(f, cp, valid, 30e3);
if ~isempty(result.selectedBranch)
    row.YStart = result.selectedBranch.YStart;
    row.StartRank = result.selectedBranch.StartRank;
    row.CpStart_mps = result.selectedBranch.CpStart_mps;
    row.MaxBranchRelativeCpDrop = result.selectedBranch.MaxRelativeCpDrop;
    row.A0StartFilterPassed = logical(result.selectedBranch.A0StartFilterPassed);
    row.SelectionFallbackUsed = logical(result.selectedBranch.SelectionFallbackUsed);
else
    row.YStart = nan; row.StartRank = nan; row.CpStart_mps = nan;
    row.MaxBranchRelativeCpDrop = nan; row.A0StartFilterPassed = false; row.SelectionFallbackUsed = false;
end
end

function rows = makeCurveRows(result, policy, iop)
rows = [];
recon = isfieldOrFalse(result, 'reconnectedByPolicy');
for k = 1:numel(result.frequency)
    row = struct();
    row.Policy = string(policy.name);
    row.IOP_mmHg = iop;
    row.Frequency_Hz = result.frequency(k);
    row.Frequency_kHz = result.frequency(k)/1e3;
    row.Cp_mps = result.Cp(k);
    row.ValidCp = logical(result.validCp(k));
    row.PointStatus = string(result.pointStatus(k));
    row.InterpolatedCp = logical(result.interpolatedCp(k));
    row.ReconnectedByPolicy = logical(recon(k));
    row.NearestRank = result.nearestRank(k);
    row.NearestBranchID = result.nearestBranchID(k);
    rows = [rows; row]; %#ok<AGROW>
end
end

function rows = makeBreakpointRows(result, policy, iop)
rows = [];
valid = result.validCp & isfinite(result.Cp);
transitions = find(diff(double(valid)) ~= 0);
for n = 1:numel(transitions)
    k = transitions(n);
    row = struct();
    row.Policy = string(policy.name);
    row.IOP_mmHg = iop;
    row.BeforeFrequency_kHz = result.frequency(k)/1e3;
    row.AfterFrequency_kHz = result.frequency(k+1)/1e3;
    row.BeforeValid = valid(k);
    row.AfterValid = valid(k+1);
    row.BeforeCp_mps = result.Cp(k);
    row.AfterCp_mps = result.Cp(k+1);
    rows = [rows; row]; %#ok<AGROW>
end
end

function T = makePolicyComparisonTable(S)
[G, policy] = findgroups(S.Policy);
T = table();
T.Policy = policy;
T.MedianValidFraction = splitapply(@(x) median(x,'omitnan'), S.ValidFraction, G);
T.MinLastValidFrequency_kHz = splitapply(@(x) min(x,[],'omitnan'), S.LastValidFrequency_kHz, G);
T.MedianMaxRelativeCpDrop = splitapply(@(x) median(x,'omitnan'), S.MaxRelativeCpDrop, G);
T.MaxMaxRelativeCpDrop = splitapply(@(x) max(x,[],'omitnan'), S.MaxRelativeCpDrop, G);
T.MedianMonotonicFrequencyScore = splitapply(@(x) median(x,'omitnan'), S.MonotonicFrequencyScore, G);
T.TotalReconnectedPoints = splitapply(@(x) sum(x,'omitnan'), S.ReconnectedPoints, G);
T.TotalInterpolatedPoints = splitapply(@(x) sum(x,'omitnan'), S.InterpolatedPoints, G);
end

function x = isfieldOrFalse(S, field)
if isfield(S, field)
    x = S.(field);
else
    x = false(size(S.Cp));
end
end

function f0 = firstValidFrequency(result)
idx = find(result.validCp & isfinite(result.Cp), 1, 'first');
if isempty(idx), f0 = nan; else, f0 = result.frequency(idx); end
end

function f0 = lastValidFrequency(result)
idx = find(result.validCp & isfinite(result.Cp), 1, 'last');
if isempty(idx), f0 = nan; else, f0 = result.frequency(idx); end
end

function c = interpValid(f, cp, valid, f0)
if nnz(valid) < 2 || f0 < min(f(valid)) || f0 > max(f(valid))
    c = nan;
else
    c = interp1(f(valid), cp(valid), f0, 'linear', nan);
end
end

function m = maxRelativeJump(cp, valid)
idx = find(valid & isfinite(cp));
if numel(idx) < 2, m = nan; return; end
c = cp(idx);
m = max(abs(diff(c)) ./ max(abs(c(1:end-1)), eps), [], 'omitnan');
end

function m = maxRelativeDrop(cp, valid)
idx = find(valid & isfinite(cp));
if numel(idx) < 2, m = nan; return; end
c = cp(idx);
d = -diff(c) ./ max(abs(c(1:end-1)), eps);
m = max([0; d(:)], [], 'omitnan');
end

function s = monotonicFrequencyScore(cp, valid)
idx = find(valid & isfinite(cp));
if numel(idx) < 2, s = nan; return; end
d = diff(cp(idx));
s = mean(d >= 0, 'omitnan');
end

function diagnostics = summarizePolicyResult(result)
diagnostics = struct();
diagnostics.validCpPoints = nnz(result.validCp);
diagnostics.totalPoints = numel(result.Cp);
diagnostics.explicitBranchPoints = nnz(result.branchExistsAtFrequency);
diagnostics.interpolatedPoints = nnz(result.interpolatedCp);
diagnostics.reconnectedPoints = nnz(isfieldOrFalse(result, 'reconnectedByPolicy'));
diagnostics.missingBranchPoints = nnz(~result.validCp);
diagnostics.selectedBranchID = result.selectedBranchID;
if any(result.validCp)
    diagnostics.minCp = min(result.Cp(result.validCp));
    diagnostics.maxCp = max(result.Cp(result.validCp));
    diagnostics.medianCp = median(result.Cp(result.validCp), 'omitnan');
else
    diagnostics.minCp = nan; diagnostics.maxCp = nan; diagnostics.medianCp = nan;
end
end
