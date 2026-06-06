% Diagnose local residual candidates around the etaS = 1 Pa*s transition.
%
% This script checks whether the apparent jumps near 7.5-8.5 kHz are caused
% by branch switching. It extracts multiple real-k local residual minima for
% A0-like and S0-like branches in a narrow frequency window and tracks the
% candidate branches by continuity.
%
% Model:
%   lambda real
%   muStar = mu + 1i*omega*etaS
%   k real
%
% Residual:
%   sigma_min(M) / sigma_max(M)

startup();

params = defaultParams();
params.fmin = 7000;
params.fmax = 8500;
params.numFrequencyPoints = 301;    % fine spacing: 5 Hz
params.frequencySpacing = "linspace";

etaS = 1.0;                         % [Pa*s]
CpScan = linspace(4, 26, 1600);     % [m/s]
maxCandidates = 5;
edgeGuardPoints = 8;
maxRelJump = 0.08;                  % narrow window; require smooth candidate tracking
branchesToInspect = ["A0Like", "S0Like"];

material = computeMaterial(params);
geometryFull = computeGeometry(params);
geometry = rmfield(geometryFull, 'halfThickness');
frequency = buildFrequencyVector(params);

options = defaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFERealK = true;
options.computeMRLFEHanViscoRealK = true;

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = etaS;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
options.mrlfeParams = mrlfeParams;

fprintf('\nmRLFE etaS = %.3g Pa*s local candidate diagnostic\n', etaS);
fprintf('----------------------------------------------------\n');
fprintf('Frequency range %.0f to %.0f Hz, N = %d, df = %.3g Hz\n', ...
    min(frequency), max(frequency), numel(frequency), frequency(2)-frequency(1));
fprintf('Cp scan %.3g to %.3g m/s, N = %d\n', min(CpScan), max(CpScan), numel(CpScan));
fprintf('Local candidates only; max branch jump = %.3g\n', maxRelJump);

results = computeFundamentalLambModes(params, options);

allCandidateRows = [];
allBranchRows = [];

for iBranch = 1:numel(branchesToInspect)
    branchName = branchesToInspect(iBranch);
    candidateCp = nan(maxCandidates, numel(frequency));
    candidateResidual = nan(maxCandidates, numel(frequency));
    Rmap = nan(numel(CpScan), numel(frequency));

    for j = 1:numel(frequency)
        omega = 2*pi*frequency(j);
        residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams);
        Rmap(:,j) = residual(:);
        candidates = findResidualCandidates(CpScan, residual, maxCandidates, edgeGuardPoints);
        n = numel(candidates.cp);
        candidateCp(1:n,j) = candidates.cp(:);
        candidateResidual(1:n,j) = candidates.residual(:);
        for c = 1:n
            allCandidateRows = [allCandidateRows; makeCandidateRow(branchName, etaS, frequency(j), c, candidates.cp(c), candidates.residual(c))]; %#ok<AGROW>
        end
    end

    tracked = trackCandidateBranches(candidateCp, candidateResidual, maxRelJump);
    for b = 1:size(tracked.cp,1)
        for j = 1:numel(frequency)
            if isfinite(tracked.cp(b,j))
                allBranchRows = [allBranchRows; makeBranchRow(branchName, etaS, b, frequency(j), tracked.cp(b,j), tracked.residual(b,j))]; %#ok<AGROW>
            end
        end
    end

    fprintf('\n%s\n', branchName);
    fprintf('  raw local candidates: %d\n', sum(isfinite(candidateCp(:))));
    for b = 1:size(tracked.cp,1)
        mask = isfinite(tracked.cp(b,:));
        if any(mask)
            fprintf('  candidate branch %d: %d points, f %.0f-%.0f Hz, Cp %.6g-%.6g m/s\n', ...
                b, sum(mask), min(frequency(mask)), max(frequency(mask)), ...
                min(tracked.cp(b,mask)), max(tracked.cp(b,mask)));
        end
    end

    figure;
    imagesc(frequency, CpScan, log10(Rmap));
    set(gca, 'YDir', 'normal');
    colorbar;
    xlabel('frequency [Hz]');
    ylabel('Trial Cp [m/s]');
    title(sprintf('etaS = %.3g Pa*s local candidates: %s', etaS, branchName));
    hold on;

    for b = 1:size(tracked.cp,1)
        plot(frequency, tracked.cp(b,:), '-', 'LineWidth', 1.4, ...
            'DisplayName', sprintf('candidate branch %d', b));
    end

    if isfield(results.models.mRLFEElasticRealK.branches, branchName)
        bElastic = results.models.mRLFEElasticRealK.branches.(branchName);
        plot(bElastic.frequency, bElastic.Cp, 'w-', 'LineWidth', 1.2, 'DisplayName', 'elastic real-k');
    end
    if isfield(results.models.mRLFEHanViscoRealK.branches, branchName)
        bHan = results.models.mRLFEHanViscoRealK.branches.(branchName);
        valid = getValidCp(bHan);
        cpPlot = bHan.Cp(:);
        cpPlot(~valid) = nan;
        plot(bHan.frequency(:), cpPlot, 'k-', 'LineWidth', 1.2, 'DisplayName', 'Han tracked real-k');
    end
    legend('Location', 'best');
    hold off;
end

if isempty(allCandidateRows)
    mRLFE_EtaS1LocalCandidateMinimaTable = table();
else
    mRLFE_EtaS1LocalCandidateMinimaTable = struct2table(allCandidateRows);
end

if isempty(allBranchRows)
    mRLFE_EtaS1LocalCandidateBranchTable = table();
else
    mRLFE_EtaS1LocalCandidateBranchTable = struct2table(allBranchRows);
end

summaryTable = summarizeBranchTable(mRLFE_EtaS1LocalCandidateBranchTable);

writetable(mRLFE_EtaS1LocalCandidateMinimaTable, 'mRLFE_etaS1_local_candidate_minima_table.csv');
writetable(mRLFE_EtaS1LocalCandidateBranchTable, 'mRLFE_etaS1_local_candidate_branch_table.csv');
writetable(summaryTable, 'mRLFE_etaS1_local_candidate_summary.csv');

assignin('base', 'mRLFE_EtaS1LocalCandidateMinimaTable', mRLFE_EtaS1LocalCandidateMinimaTable);
assignin('base', 'mRLFE_EtaS1LocalCandidateBranchTable', mRLFE_EtaS1LocalCandidateBranchTable);
assignin('base', 'mRLFE_EtaS1LocalCandidateSummary', summaryTable);
assignin('base', 'mRLFE_EtaS1LocalCandidateResults', results);

fprintf('\nLocal candidate summary\n');
fprintf('-----------------------\n');
disp(summaryTable);
fprintf('\nWrote:\n');
fprintf('  mRLFE_etaS1_local_candidate_minima_table.csv\n');
fprintf('  mRLFE_etaS1_local_candidate_branch_table.csv\n');
fprintf('  mRLFE_etaS1_local_candidate_summary.csv\n');

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

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid(:) & isfinite(branch.Cp(:));
end

function row = makeCandidateRow(branchName, etaS, frequency, rank, cp, residual)
row = struct();
row.Branch = string(branchName);
row.EtaS_Pa_s = etaS;
row.Frequency_Hz = frequency;
row.CandidateRank = rank;
row.Cp = cp;
row.Residual = residual;
end

function row = makeBranchRow(branchName, etaS, branchIndex, frequency, cp, residual)
row = struct();
row.Branch = string(branchName);
row.EtaS_Pa_s = etaS;
row.CandidateBranch = branchIndex;
row.Frequency_Hz = frequency;
row.Cp = cp;
row.Residual = residual;
end

function summary = summarizeBranchTable(T)
if isempty(T)
    summary = table();
    return;
end
keys = unique(T(:, {'Branch', 'CandidateBranch'}), 'rows', 'stable');
rows = [];
for i = 1:height(keys)
    mask = T.Branch == keys.Branch(i) & T.CandidateBranch == keys.CandidateBranch(i);
    Ti = T(mask,:);
    row = struct();
    row.Branch = keys.Branch(i);
    row.CandidateBranch = keys.CandidateBranch(i);
    row.Points = height(Ti);
    row.Fmin_Hz = min(Ti.Frequency_Hz);
    row.Fmax_Hz = max(Ti.Frequency_Hz);
    row.CpMin = min(Ti.Cp);
    row.CpMax = max(Ti.Cp);
    row.MinResidual = min(Ti.Residual);
    row.MaxResidual = max(Ti.Residual);
    rows = [rows; row]; %#ok<AGROW>
end
summary = struct2table(rows);
end
