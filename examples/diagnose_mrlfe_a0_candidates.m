% Compact A0-like candidate-branch diagnostic for mRLFE Han real-k.
% Use this script when checking whether lower A0-like residual minima form
% continuous candidate branches.
%
% Important diagnostic choice:
%   Only true local minima are accepted as candidates.
%   No fallback to the global/interior minimum is used, because that can
%   incorrectly create artificial branches at the lower Cp boundary.

startup();

params = defaultParams();
params.fmin = 500;
params.fmax = 30000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "hybrid";

etaSValues = [0, 0.5, 1.0];
CpScan = linspace(0.5, 30, 2500);
fMap = linspace(500, 30000, 70);
maxCandidates = 4;
minCandidateCp = 2.0;
edgeGuardPoints = 10;
maxRelJump = 0.60;

material = computeMaterial(params);
geometryFull = computeGeometry(params);
geometry = rmfield(geometryFull, 'halfThickness');

allRows = [];
branchRows = [];

fprintf('\nCompact A0-like candidate branch diagnostic\n');
fprintf('------------------------------------------\n');
fprintf('Cp scan %.3g to %.3g m/s, %d points\n', min(CpScan), max(CpScan), numel(CpScan));
fprintf('Candidate filter: local minima only, Cp >= %.3g m/s, edge guard = %d samples, max branch jump = %.2f\n', ...
    minCandidateCp, edgeGuardPoints, maxRelJump);

for iEta = 1:numel(etaSValues)
    etaS = etaSValues(iEta);
    mrlfeParams = makeMrlfeParams(etaS);
    candidateCp = nan(maxCandidates, numel(fMap));
    candidateResidual = nan(maxCandidates, numel(fMap));
    Rmap = nan(numel(CpScan), numel(fMap));

    for j = 1:numel(fMap)
        residual = computeResidualVsCp(CpScan, 2*pi*fMap(j), material, geometry, mrlfeParams);
        Rmap(:,j) = residual(:);
        candidates = findResidualCandidates(CpScan, residual, maxCandidates, minCandidateCp, edgeGuardPoints);
        n = numel(candidates.cp);
        candidateCp(1:n,j) = candidates.cp(:);
        candidateResidual(1:n,j) = candidates.residual(:);
        for c = 1:n
            allRows = [allRows; makeCandidateRow(etaS, fMap(j), c, candidates.cp(c), candidates.residual(c))]; %#ok<AGROW>
        end
    end

    tracked = trackCandidateBranches(candidateCp, candidateResidual, maxRelJump);
    for b = 1:size(tracked.cp,1)
        for j = 1:numel(fMap)
            if isfinite(tracked.cp(b,j))
                branchRows = [branchRows; makeBranchRow(etaS, b, fMap(j), tracked.cp(b,j), tracked.residual(b,j))]; %#ok<AGROW>
            end
        end
    end

    figure;
    imagesc(fMap, CpScan, log10(Rmap));
    set(gca, 'YDir', 'normal');
    colorbar;
    xlabel('frequency [Hz]');
    ylabel('Trial phase velocity Cp [m/s]');
    title(sprintf('A0-like candidate branches, etaS = %.3g Pa*s', etaS));
    hold on;
    for b = 1:size(tracked.cp,1)
        plot(fMap, tracked.cp(b,:), '-', 'LineWidth', 1.3);
    end
    hold off;

    fprintf('etaS = %.3g Pa*s: extracted %d local-minimum candidates\n', etaS, sum(isfinite(candidateCp(:))));
end

if isempty(allRows)
    mRLFEA0CandidateMinimaTable = table();
else
    mRLFEA0CandidateMinimaTable = struct2table(allRows);
end

if isempty(branchRows)
    mRLFEA0CandidateBranchTable = table();
else
    mRLFEA0CandidateBranchTable = struct2table(branchRows);
end

assignin('base', 'mRLFEA0CandidateMinimaTable', mRLFEA0CandidateMinimaTable);
assignin('base', 'mRLFEA0CandidateBranchTable', mRLFEA0CandidateBranchTable);
writetable(mRLFEA0CandidateMinimaTable, 'mRLFE_A0_candidate_minima_table.csv');
writetable(mRLFEA0CandidateBranchTable, 'mRLFE_A0_candidate_branch_table.csv');
fprintf('\nWrote mRLFE_A0_candidate_minima_table.csv and mRLFE_A0_candidate_branch_table.csv\n');

function mrlfeParams = makeMrlfeParams(etaS)
mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = etaS;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
end

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    residual(i) = mrlfeResidual(omega/CpScan(i), omega, material, geometry, mrlfeParams);
end
end

function candidates = findResidualCandidates(CpScan, residual, maxCandidates, minCandidateCp, edgeGuardPoints)
idx = [];
firstAllowed = 1 + edgeGuardPoints;
lastAllowed = numel(residual) - edgeGuardPoints;
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if CpScan(i) >= minCandidateCp && isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
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
    if isempty(available), continue; end
    if j == 1 || ~any(isfinite(tracked.cp(:,1:j-1)), 'all')
        n = min(numBranches, numel(available));
        tracked.cp(1:n,j) = candidateCp(available(1:n),j);
        tracked.residual(1:n,j) = candidateResidual(available(1:n),j);
        continue;
    end
    used = false(size(available));
    for b = 1:numBranches
        prevIdx = find(isfinite(tracked.cp(b,1:j-1)), 1, 'last');
        if isempty(prevIdx), continue; end
        prevCp = tracked.cp(b,prevIdx);
        relDist = abs(candidateCp(available,j)-prevCp)./max(abs(prevCp),eps);
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

function row = makeCandidateRow(etaS, frequency, rank, cp, residual)
row = struct('EtaS_Pa_s', etaS, 'Frequency_Hz', frequency, 'CandidateRank', rank, 'Cp', cp, 'Residual', residual);
end

function row = makeBranchRow(etaS, branchIndex, frequency, cp, residual)
row = struct('EtaS_Pa_s', etaS, 'CandidateBranch', branchIndex, 'Frequency_Hz', frequency, 'Cp', cp, 'Residual', residual);
end
