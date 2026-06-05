% Diagnose A0-like mRLFE Han real-k residual under shear viscosity.
% This script plots the real-k residual landscape versus trial Cp for selected
% frequencies and etaS values. It extracts multiple local minima and tracks
% them across frequency to distinguish possible continuous candidate branches
% from edge artifacts or isolated branch-switching events.
%
% Model used here:
%   lambda real
%   muStar = mu + 1i*omega*etaS
%   k real
%
% The plotted residual is sigma_min(M)/sigma_max(M).

startup();

params = defaultParams();
params.fmin = 500;
params.fmax = 30000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "hybrid";

% Frequencies selected to inspect the A0-like residual landscape.
frequenciesToInspect = [8000, 16000, 24000, 30000]; % [Hz]

% Reduced diagnostic set. Add intermediate etaS values only when needed.
etaSValues = [0, 0.5, 1.0]; % [Pa*s]

% Cp scan range for A0-like. The candidate filter below ignores minima too
% close to scan edges and Cp values below minCandidateCp.
CpScan = linspace(0.5, 30, 3500); % [m/s]
maxCandidatesToReport = 4;
minCandidateCp = 1.5;             % [m/s], rejects low-Cp edge artifacts
edgeGuardPoints = 6;              % reject minima within this many samples of an edge
maxCandidateBranchJump = 0.35;    % relative Cp jump allowed during candidate-branch tracking

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFEHanViscoRealK = true;

material = computeMaterial(params);
geometryFull = computeGeometry(params);
geometry = rmfield(geometryFull, 'halfThickness');

resultsByEtaS = cell(size(etaSValues));
candidateRows = [];
candidateBranchRows = [];

fprintf('\nA0-like mRLFE Han real-k residual diagnostic\n');
fprintf('--------------------------------------------\n');
fprintf('Cp scan range: %.3g to %.3g m/s (%d samples)\n', min(CpScan), max(CpScan), numel(CpScan));
fprintf('Candidate minima reported per curve: %d\n', maxCandidatesToReport);
fprintf('Candidate filter: Cp >= %.3g m/s, edge guard = %d samples\n', minCandidateCp, edgeGuardPoints);

for iEta = 1:numel(etaSValues)
    options = optionsBase;
    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = etaSValues(iEta);
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    options.mrlfeParams = mrlfeParams;

    resultsByEtaS{iEta} = computeFundamentalLambModes(params, options);

    fprintf('\netaS = %.4g Pa*s\n', etaSValues(iEta));
    branch = resultsByEtaS{iEta}.models.mRLFEHanViscoRealK.branches.A0Like;
    valid = getValidCp(branch);
    fprintf('  tracked A0Like valid Cp points: %d / %d\n', sum(valid), numel(valid));
    if any(valid)
        fprintf('  tracked A0Like Cp range: %.6g to %.6g m/s\n', min(branch.Cp(valid)), max(branch.Cp(valid)));
    end
end

% One figure per frequency. Each figure overlays residual curves for etaS and
% marks the tracked point plus the strongest local minima candidates.
for iFreq = 1:numel(frequenciesToInspect)
    f = frequenciesToInspect(iFreq);
    omega = 2*pi*f;

    figure;
    hold on;
    minTable = zeros(numel(etaSValues), 4); % etaS, global interior CpMin, min residual, trackedCp

    for iEta = 1:numel(etaSValues)
        etaS = etaSValues(iEta);
        mrlfeParams = defaultMRLFEParams();
        mrlfeParams.fluidDensity = 1000;
        mrlfeParams.fluidSoundSpeed = 1500;
        mrlfeParams.etaS = etaS;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;

        residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams);
        semilogy(CpScan, residual, 'LineWidth', 1.3, ...
            'DisplayName', sprintf('etaS = %.3g Pa*s', etaS));

        candidates = findResidualCandidates(CpScan, residual, maxCandidatesToReport, minCandidateCp, edgeGuardPoints);
        for c = 1:numel(candidates.cp)
            candidateRows = [candidateRows; makeCandidateRow(f, etaS, c, candidates.cp(c), candidates.residual(c))]; %#ok<AGROW>
            semilogy(candidates.cp(c), candidates.residual(c), 'x', 'MarkerSize', 7, ...
                'HandleVisibility', 'off');
        end

        [resMin, cpMin] = findInteriorMinimum(CpScan, residual, minCandidateCp, edgeGuardPoints);
        trackedCp = interpolateTrackedCp(resultsByEtaS{iEta}, f);
        minTable(iEta,:) = [etaS, cpMin, resMin, trackedCp];

        if isfinite(trackedCp)
            trackedResidual = interp1(CpScan, residual, trackedCp, 'linear', nan);
            semilogy(trackedCp, trackedResidual, 'o', 'MarkerSize', 6, ...
                'HandleVisibility', 'off');
        end
    end

    grid on;
    xlabel('Trial phase velocity Cp [m/s]');
    ylabel('mRLFE residual sigma_{min}(M)/sigma_{max}(M)');
    title(sprintf('A0-like residual candidates at f = %.0f Hz', f));
    legend('Location', 'best');
    hold off;

    fprintf('\nFrequency %.0f Hz\n', f);
    fprintf('  etaS [Pa*s] | interior-min Cp [m/s] | min residual | tracked Cp [m/s]\n');
    for iEta = 1:size(minTable,1)
        fprintf('  %10.4g | %19.6g | %12.3e | %16.6g\n', ...
            minTable(iEta,1), minTable(iEta,2), minTable(iEta,3), minTable(iEta,4));
    end
end

% Residual heatmaps for selected etaS values. Candidate-minimum curves and
% continuity-tracked candidate branches are overlaid. This reveals whether a
% lower A0-like candidate is continuous or only a set of isolated minima.
etaSMapValues = etaSValues;
fMap = linspace(500, 30000, 85);
CpMap = linspace(0.5, 30, 800);

for iEta = 1:numel(etaSMapValues)
    etaS = etaSMapValues(iEta);
    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = etaS;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    Rmap = nan(numel(CpMap), numel(fMap));
    candidateCp = nan(maxCandidatesToReport, numel(fMap));
    candidateResidual = nan(maxCandidatesToReport, numel(fMap));
    for j = 1:numel(fMap)
        Rmap(:,j) = computeResidualVsCp(CpMap, 2*pi*fMap(j), material, geometry, mrlfeParams).';
        candidates = findResidualCandidates(CpMap, Rmap(:,j).', maxCandidatesToReport, minCandidateCp, edgeGuardPoints);
        candidateCp(1:numel(candidates.cp), j) = candidates.cp(:);
        candidateResidual(1:numel(candidates.residual), j) = candidates.residual(:);
    end

    trackedCandidates = trackCandidateBranches(candidateCp, candidateResidual, maxCandidateBranchJump);
    for b = 1:size(trackedCandidates.cp, 1)
        for j = 1:numel(fMap)
            if isfinite(trackedCandidates.cp(b,j))
                candidateBranchRows = [candidateBranchRows; makeCandidateBranchRow(etaS, b, fMap(j), trackedCandidates.cp(b,j), trackedCandidates.residual(b,j), trackedCandidates.valid(b,j))]; %#ok<AGROW>
            end
        end
    end

    figure;
    imagesc(fMap, CpMap, log10(Rmap));
    set(gca, 'YDir', 'normal');
    colorbar;
    xlabel('frequency [Hz]');
    ylabel('Trial phase velocity Cp [m/s]');
    title(sprintf('log10 residual map: A0-like candidate branches, etaS = %.3g Pa*s', etaS));
    hold on;
    for c = 1:size(candidateCp,1)
        plot(fMap, candidateCp(c,:), '.', 'MarkerSize', 4, 'Color', [0.15 0.15 0.15], ...
            'DisplayName', sprintf('raw candidate %d', c));
    end
    for b = 1:size(trackedCandidates.cp,1)
        plot(fMap, trackedCandidates.cp(b,:), '-', 'LineWidth', 1.4, ...
            'DisplayName', sprintf('tracked candidate branch %d', b));
    end
    idx = find(abs(etaSValues - etaS) < 1e-12, 1);
    if ~isempty(idx)
        branch = resultsByEtaS{idx}.models.mRLFEHanViscoRealK.branches.A0Like;
        valid = getValidCp(branch);
        cpPlot = branch.Cp;
        cpPlot(~valid) = nan;
        plot(branch.frequency, cpPlot, 'w.', 'MarkerSize', 8, 'DisplayName', 'solver tracked valid Cp');
    end
    hold off;
end

if isempty(candidateRows)
    A0CandidateMinimaTable = table();
else
    A0CandidateMinimaTable = struct2table(candidateRows);
end

if isempty(candidateBranchRows)
    A0CandidateBranchTable = table();
else
    A0CandidateBranchTable = struct2table(candidateBranchRows);
end

assignin('base', 'mRLFEA0ResidualDiagnosticResults', resultsByEtaS);
assignin('base', 'mRLFEA0ResidualDiagnosticEtaS', etaSValues);
assignin('base', 'mRLFEA0ResidualDiagnosticCpScan', CpScan);
assignin('base', 'mRLFEA0CandidateMinimaTable', A0CandidateMinimaTable);
assignin('base', 'mRLFEA0CandidateBranchTable', A0CandidateBranchTable);
writetable(A0CandidateMinimaTable, 'mRLFE_A0_candidate_minima_table.csv');
writetable(A0CandidateBranchTable, 'mRLFE_A0_candidate_branch_table.csv');
fprintf('\nExported A0 diagnostic variables, mRLFE_A0_candidate_minima_table.csv, and mRLFE_A0_candidate_branch_table.csv.\n');

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    Cp = CpScan(i);
    if Cp <= 0 || ~isfinite(Cp)
        continue;
    end
    k = omega / Cp;
    residual(i) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
end
end

function trackedCp = interpolateTrackedCp(results, frequency)
trackedCp = nan;
if ~isfield(results.models, 'mRLFEHanViscoRealK')
    return;
end
branches = results.models.mRLFEHanViscoRealK.branches;
if ~isfield(branches, 'A0Like')
    return;
end
branch = branches.A0Like;
valid = getValidCp(branch);
if sum(valid) < 2
    return;
end
trackedCp = interp1(branch.frequency(valid), branch.Cp(valid), frequency, 'linear', nan);
end

function candidates = findResidualCandidates(CpScan, residual, maxCandidates, minCandidateCp, edgeGuardPoints)
localIdx = [];
firstAllowed = 1 + edgeGuardPoints;
lastAllowed = numel(residual) - edgeGuardPoints;
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if CpScan(i) < minCandidateCp
        continue;
    end
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        localIdx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(localIdx)
    [~, idx] = findInteriorMinimum(CpScan, residual, minCandidateCp, edgeGuardPoints);
    if isfinite(idx)
        localIdx = idx;
    end
end
if isempty(localIdx)
    candidates.cp = [];
    candidates.residual = [];
    return;
end
[~, order] = sort(residual(localIdx), 'ascend');
localIdx = localIdx(order);
localIdx = localIdx(1:min(maxCandidates, numel(localIdx)));
candidates.cp = CpScan(localIdx);
candidates.residual = residual(localIdx);
end

function [resMin, cpMinOrIdx] = findInteriorMinimum(CpScan, residual, minCandidateCp, edgeGuardPoints)
valid = isfinite(residual) & CpScan >= minCandidateCp;
if edgeGuardPoints > 0 && numel(valid) > 2*edgeGuardPoints
    valid(1:edgeGuardPoints) = false;
    valid(end-edgeGuardPoints+1:end) = false;
end
if ~any(valid)
    resMin = nan;
    cpMinOrIdx = nan;
    return;
end
idxAll = find(valid);
[resMin, local] = min(residual(valid));
idx = idxAll(local);
if nargout > 1
    cpMinOrIdx = CpScan(idx);
end
end

function tracked = trackCandidateBranches(candidateCp, candidateResidual, maxRelJump)
numBranches = size(candidateCp, 1);
numFreq = size(candidateCp, 2);
tracked.cp = nan(numBranches, numFreq);
tracked.residual = nan(numBranches, numFreq);
tracked.valid = false(numBranches, numFreq);

for j = 1:numFreq
    availableCp = candidateCp(:,j);
    availableResidual = candidateResidual(:,j);
    available = find(isfinite(availableCp));
    if isempty(available)
        continue;
    end

    if j == 1 || all(~isfinite(tracked.cp(:,j-1)))
        n = min(numBranches, numel(available));
        tracked.cp(1:n,j) = availableCp(available(1:n));
        tracked.residual(1:n,j) = availableResidual(available(1:n));
        tracked.valid(1:n,j) = true;
        continue;
    end

    used = false(size(available));
    for b = 1:numBranches
        prevIdx = find(isfinite(tracked.cp(b,1:j-1)), 1, 'last');
        if isempty(prevIdx)
            continue;
        end
        prevCp = tracked.cp(b, prevIdx);
        relDist = abs(availableCp(available) - prevCp) ./ max(abs(prevCp), eps);
        relDist(used) = inf;
        [bestDist, bestLocal] = min(relDist);
        if isfinite(bestDist) && bestDist <= maxRelJump
            chosen = available(bestLocal);
            tracked.cp(b,j) = availableCp(chosen);
            tracked.residual(b,j) = availableResidual(chosen);
            tracked.valid(b,j) = true;
            used(bestLocal) = true;
        end
    end

    % Start new branches with unassigned candidates if free branch slots exist.
    freeBranches = find(~isfinite(tracked.cp(:,j)) & all(~isfinite(tracked.cp(:,1:j-1)), 2));
    remaining = available(~used);
    n = min(numel(freeBranches), numel(remaining));
    for ii = 1:n
        b = freeBranches(ii);
        chosen = remaining(ii);
        tracked.cp(b,j) = availableCp(chosen);
        tracked.residual(b,j) = availableResidual(chosen);
        tracked.valid(b,j) = true;
    end
end
end

function row = makeCandidateRow(frequency, etaS, rank, cp, residual)
row = struct();
row.Frequency_Hz = frequency;
row.EtaS_Pa_s = etaS;
row.CandidateRank = rank;
row.Cp = cp;
row.Residual = residual;
end

function row = makeCandidateBranchRow(etaS, branchIndex, frequency, cp, residual, isValid)
row = struct();
row.EtaS_Pa_s = etaS;
row.CandidateBranch = branchIndex;
row.Frequency_Hz = frequency;
row.Cp = cp;
row.Residual = residual;
row.IsValid = logical(isValid);
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid & isfinite(branch.Cp);
end
