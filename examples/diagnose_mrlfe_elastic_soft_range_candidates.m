% Diagnose branch switching in the soft elastic mRLFE real-k range.
%
% The elastic stability sweep showed discontinuous-looking jumps for low E
% cases even though valid solutions exist up to 16 kHz. This script finds the
% largest Cp jumps for soft materials, then scans local residual minima around
% those frequencies to identify competing candidate branches.
%
% Model:
%   mRLFE elastic real-k, etaS = 0
%   lambda real, mu real, k real
%
% Output files:
%   mRLFE_elastic_soft_jump_summary.csv
%   mRLFE_elastic_soft_local_candidate_minima.csv
%   mRLFE_elastic_soft_local_candidate_branches.csv
%   mRLFE_elastic_soft_local_candidate_branch_summary.csv

startup();

EValues = [50e3, 75e3, 100e3, 150e3, 225e3]; % [Pa]
branchesToInspect = ["A0Like", "S0Like"];

paramsBase = defaultParams();
paramsBase.fmin = 500;
paramsBase.fmax = 16000;
paramsBase.numFrequencyPoints = 160;
paramsBase.frequencySpacing = "hybrid";
paramsBase.thickness = 0.5e-3;
paramsBase.nu = 0.4999;
paramsBase.CL = 1500;

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEHanViscoRealK = false;
optionsBase.computeMRLFEComplexK = false;

% Local candidate scan controls.
localWindowHz = 1200;       % half-width around largest jump frequency
localFrequencyPoints = 241; % about 10 Hz spacing for a 2400 Hz window
CpScanPoints = 1800;
maxCandidates = 6;
edgeGuardPoints = 8;
maxRelJump = 0.12;
CpPadFactor = 1.80;
CpMinFloor = 0.8;
CpMaxCeilingFactor = 3.0;

jumpRows = [];
allCandidateRows = [];
allBranchRows = [];
allBranchSummaryRows = [];
resultsByE = cell(size(EValues));

fprintf('\nmRLFE elastic soft-range candidate diagnostic\n');
fprintf('--------------------------------------------\n');
fprintf('E range: %.3g to %.3g kPa\n', min(EValues)/1e3, max(EValues)/1e3);
fprintf('Base frequency range: %.0f to %.0f Hz\n', paramsBase.fmin, paramsBase.fmax);

for iE = 1:numel(EValues)
    params = paramsBase;
    params.E = EValues(iE);
    material = computeMaterial(params);

    fprintf('\nE = %.6g kPa, mu = %.6g kPa, CT = %.6g m/s\n', ...
        params.E/1e3, material.mu/1e3, material.CT);

    results = computeFundamentalLambModes(params, optionsBase);
    resultsByE{iE} = results;

    for iBranch = 1:numel(branchesToInspect)
        branchName = branchesToInspect(iBranch);
        branch = results.models.mRLFEElasticRealK.branches.(branchName);
        jumpInfo = findLargestValidJump(branch);
        jumpRows = [jumpRows; makeJumpRow(branchName, params, material, jumpInfo)]; %#ok<AGROW>

        if ~jumpInfo.hasJump
            fprintf('  %s: no valid jump found\n', branchName);
            continue;
        end

        fprintf('  %s largest valid jump: %.3g at %.6g Hz, Cp %.6g -> %.6g m/s\n', ...
            branchName, jumpInfo.maxRelativeJump, jumpInfo.frequencyAfter_Hz, ...
            jumpInfo.cpBefore, jumpInfo.cpAfter);

        [candidateRows, branchRows, branchSummaryRows] = diagnoseLocalCandidates( ...
            params, material, results.geometry, branchName, branch, jumpInfo, ...
            localWindowHz, localFrequencyPoints, CpScanPoints, maxCandidates, ...
            edgeGuardPoints, maxRelJump, CpPadFactor, CpMinFloor, CpMaxCeilingFactor);

        allCandidateRows = [allCandidateRows; candidateRows]; %#ok<AGROW>
        allBranchRows = [allBranchRows; branchRows]; %#ok<AGROW>
        allBranchSummaryRows = [allBranchSummaryRows; branchSummaryRows]; %#ok<AGROW>
    end
end

mRLFEElasticSoftJumpSummary = rowsToTable(jumpRows);
mRLFEElasticSoftCandidateMinima = rowsToTable(allCandidateRows);
mRLFEElasticSoftCandidateBranches = rowsToTable(allBranchRows);
mRLFEElasticSoftCandidateBranchSummary = rowsToTable(allBranchSummaryRows);

writetable(mRLFEElasticSoftJumpSummary, 'mRLFE_elastic_soft_jump_summary.csv');
writetable(mRLFEElasticSoftCandidateMinima, 'mRLFE_elastic_soft_local_candidate_minima.csv');
writetable(mRLFEElasticSoftCandidateBranches, 'mRLFE_elastic_soft_local_candidate_branches.csv');
writetable(mRLFEElasticSoftCandidateBranchSummary, 'mRLFE_elastic_soft_local_candidate_branch_summary.csv');

assignin('base', 'mRLFEElasticSoftJumpSummary', mRLFEElasticSoftJumpSummary);
assignin('base', 'mRLFEElasticSoftCandidateMinima', mRLFEElasticSoftCandidateMinima);
assignin('base', 'mRLFEElasticSoftCandidateBranches', mRLFEElasticSoftCandidateBranches);
assignin('base', 'mRLFEElasticSoftCandidateBranchSummary', mRLFEElasticSoftCandidateBranchSummary);
assignin('base', 'mRLFEElasticSoftCandidateResultsByE', resultsByE);

fprintf('\nSoft elastic jump summary\n');
fprintf('-------------------------\n');
disp(mRLFEElasticSoftJumpSummary(:, {'Branch','E_kPa','MaxRelativeJump','FrequencyAfter_Hz','CpBefore','CpAfter','ResidualBefore','ResidualAfter'}));

fprintf('\nLocal candidate branch summary\n');
fprintf('------------------------------\n');
disp(mRLFEElasticSoftCandidateBranchSummary(:, {'Branch','E_kPa','CandidateBranch','Points','Fmin_Hz','Fmax_Hz','CpMin','CpMax','MinResidual','MaxResidual'}));

fprintf('\nWrote:\n');
fprintf('  mRLFE_elastic_soft_jump_summary.csv\n');
fprintf('  mRLFE_elastic_soft_local_candidate_minima.csv\n');
fprintf('  mRLFE_elastic_soft_local_candidate_branches.csv\n');
fprintf('  mRLFE_elastic_soft_local_candidate_branch_summary.csv\n');

function [candidateRows, branchRows, branchSummaryRows] = diagnoseLocalCandidates(params, material, geometry, branchName, trackedBranch, jumpInfo, localWindowHz, localFrequencyPoints, CpScanPoints, maxCandidates, edgeGuardPoints, maxRelJump, CpPadFactor, CpMinFloor, CpMaxCeilingFactor)
fminLocal = max(params.fmin, jumpInfo.frequencyAfter_Hz - localWindowHz);
fmaxLocal = min(params.fmax, jumpInfo.frequencyAfter_Hz + localWindowHz);
fLocal = linspace(fminLocal, fmaxLocal, localFrequencyPoints);

cpValid = trackedBranch.Cp(getValidCp(trackedBranch));
cpMin = max(CpMinFloor, min(cpValid) / CpPadFactor);
cpMax = min(max(cpValid) * CpPadFactor, CpMaxCeilingFactor * max(cpValid));
if cpMax <= cpMin
    cpMax = cpMin + 10;
end
CpScan = linspace(cpMin, cpMax, CpScanPoints);

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;

candidateCp = nan(maxCandidates, numel(fLocal));
candidateResidual = nan(maxCandidates, numel(fLocal));
Rmap = nan(numel(CpScan), numel(fLocal));
candidateRows = [];

for j = 1:numel(fLocal)
    omega = 2*pi*fLocal(j);
    residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams);
    Rmap(:,j) = residual(:);
    candidates = findResidualCandidates(CpScan, residual, maxCandidates, edgeGuardPoints);
    n = numel(candidates.cp);
    candidateCp(1:n,j) = candidates.cp(:);
    candidateResidual(1:n,j) = candidates.residual(:);
    for c = 1:n
        candidateRows = [candidateRows; makeCandidateRow(branchName, params, material, fLocal(j), c, candidates.cp(c), candidates.residual(c))]; %#ok<AGROW>
    end
end

tracked = trackCandidateBranches(candidateCp, candidateResidual, maxRelJump);
branchRows = [];
branchSummaryRows = [];
for b = 1:size(tracked.cp,1)
    mask = isfinite(tracked.cp(b,:));
    if ~any(mask)
        continue;
    end
    for j = find(mask)
        branchRows = [branchRows; makeBranchRow(branchName, params, material, b, fLocal(j), tracked.cp(b,j), tracked.residual(b,j))]; %#ok<AGROW>
    end
    branchSummaryRows = [branchSummaryRows; makeBranchSummaryRow(branchName, params, material, b, fLocal(mask), tracked.cp(b,mask), tracked.residual(b,mask))]; %#ok<AGROW>
end

figure;
imagesc(fLocal, CpScan, log10(Rmap));
set(gca, 'YDir', 'normal');
colorbar;
xlabel('frequency [Hz]');
ylabel('Trial Cp [m/s]');
title(sprintf('Elastic local candidates: %s, E = %.0f kPa', branchName, params.E/1e3));
hold on;
for b = 1:size(tracked.cp,1)
    plot(fLocal, tracked.cp(b,:), '-', 'LineWidth', 1.2, 'DisplayName', sprintf('candidate %d', b));
end
validTracked = getValidCp(trackedBranch);
plot(trackedBranch.frequency(validTracked), trackedBranch.Cp(validTracked), 'k-', 'LineWidth', 1.4, 'DisplayName', 'solver tracked');
xline(jumpInfo.frequencyAfter_Hz, 'w--', 'LineWidth', 1.2, 'DisplayName', 'largest jump');
legend('Location', 'best');
hold off;
end

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    k = omega / CpScan(i);
    residual(i) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
end
end

function candidates = findResidualCandidates(CpScan, residual, maxCandidates, edgeGuardPoints)
idx = [];
firstAllowed = 1 + edgeGuardPoints;
lastAllowed = numel(residual) - edgeGuardPoints;
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
idx = unique(round(idx(isfinite(idx) & idx >= 1 & idx <= numel(residual))));
if isempty(idx)
    candidates.cp = [];
    candidates.residual = [];
    return;
end
[~, order] = sort(residual(idx), 'ascend');
idx = idx(order);
idx = idx(1:min(maxCandidates, numel(idx)));
candidates.cp = CpScan(idx);
candidates.residual = residual(idx);
end

function tracked = trackCandidateBranches(candidateCp, candidateResidual, maxRelJump)
numBranches = size(candidateCp,1);
numFreq = size(candidateCp,2);
tracked.cp = nan(numBranches, numFreq);
tracked.residual = nan(numBranches, numFreq);
for j = 1:numFreq
    available = find(isfinite(candidateCp(:,j)));
    if isempty(available)
        continue;
    end
    if j == 1 || ~any(isfinite(tracked.cp(:,1:j-1)), 'all')
        n = min(numBranches, numel(available));
        tracked.cp(1:n,j) = candidateCp(available(1:n),j);
        tracked.residual(1:n,j) = candidateResidual(available(1:n),j);
        continue;
    end
    used = false(size(available));
    for b = 1:numBranches
        prevIdx = find(isfinite(tracked.cp(b,1:j-1)), 1, 'last');
        if isempty(prevIdx)
            continue;
        end
        prevCp = tracked.cp(b,prevIdx);
        relDist = abs(candidateCp(available,j) - prevCp) ./ max(abs(prevCp), eps);
        relDist(used) = inf;
        [bestDist,bestLocal] = min(relDist);
        if isfinite(bestDist) && bestDist <= maxRelJump
            chosen = available(bestLocal);
            tracked.cp(b,j) = candidateCp(chosen,j);
            tracked.residual(b,j) = candidateResidual(chosen,j);
            used(bestLocal) = true;
        end
    end
end
end

function jump = findLargestValidJump(branch)
valid = getValidCp(branch);
idx = find(valid(:));
jump = struct('hasJump', false, 'maxRelativeJump', nan, 'frequencyBefore_Hz', nan, 'frequencyAfter_Hz', nan, ...
    'cpBefore', nan, 'cpAfter', nan, 'residualBefore', nan, 'residualAfter', nan, 'indexBefore', nan, 'indexAfter', nan);
if numel(idx) < 2
    return;
end
cp = branch.Cp(:);
f = branch.frequency(:);
r = branch.residual(:);
relJump = abs(diff(cp(idx))) ./ max(abs(cp(idx(1:end-1))), eps);
[maxJump, localIdx] = max(relJump);
iBefore = idx(localIdx);
iAfter = idx(localIdx+1);
jump.hasJump = isfinite(maxJump);
jump.maxRelativeJump = maxJump;
jump.frequencyBefore_Hz = f(iBefore);
jump.frequencyAfter_Hz = f(iAfter);
jump.cpBefore = cp(iBefore);
jump.cpAfter = cp(iAfter);
jump.residualBefore = getElementOrNaN(r, iBefore);
jump.residualAfter = getElementOrNaN(r, iAfter);
jump.indexBefore = iBefore;
jump.indexAfter = iAfter;
end

function value = getElementOrNaN(x, idx)
if idx <= numel(x)
    value = x(idx);
else
    value = nan;
end
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid(:) & isfinite(branch.Cp(:));
end

function row = makeJumpRow(branchName, params, material, jumpInfo)
row = struct();
row.Branch = string(branchName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.HasJump = logical(jumpInfo.hasJump);
row.MaxRelativeJump = jumpInfo.maxRelativeJump;
row.FrequencyBefore_Hz = jumpInfo.frequencyBefore_Hz;
row.FrequencyAfter_Hz = jumpInfo.frequencyAfter_Hz;
row.CpBefore = jumpInfo.cpBefore;
row.CpAfter = jumpInfo.cpAfter;
row.ResidualBefore = jumpInfo.residualBefore;
row.ResidualAfter = jumpInfo.residualAfter;
row.IndexBefore = jumpInfo.indexBefore;
row.IndexAfter = jumpInfo.indexAfter;
end

function row = makeCandidateRow(branchName, params, material, frequency, rank, cp, residual)
row = struct();
row.Branch = string(branchName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.Frequency_Hz = frequency;
row.CandidateRank = rank;
row.Cp = cp;
row.Residual = residual;
end

function row = makeBranchRow(branchName, params, material, branchIndex, frequency, cp, residual)
row = struct();
row.Branch = string(branchName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CandidateBranch = branchIndex;
row.Frequency_Hz = frequency;
row.Cp = cp;
row.Residual = residual;
end

function row = makeBranchSummaryRow(branchName, params, material, branchIndex, frequency, cp, residual)
row = struct();
row.Branch = string(branchName);
row.E_kPa = params.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CandidateBranch = branchIndex;
row.Points = numel(frequency);
row.Fmin_Hz = min(frequency);
row.Fmax_Hz = max(frequency);
row.CpMin = min(cp);
row.CpMax = max(cp);
row.MinResidual = min(residual);
row.MaxResidual = max(residual);
end

function T = rowsToTable(rows)
if isempty(rows)
    T = table();
else
    T = struct2table(rows);
end
end
