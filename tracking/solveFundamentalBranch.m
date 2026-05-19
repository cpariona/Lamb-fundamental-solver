function [Cp, residual] = solveFundamentalBranch(frequency, residualFcn, options)
% Continuation solver for a single fundamental branch.

CpMinAbs = 1e-4;
CpMin = max(CpMinAbs, 0.001 * options.CT);
CpGlobalMin = CpMin;
CpGlobalMax = max(20 * options.CT, 1.0);

Cp = nan(size(frequency));
residual = nan(size(frequency));

% Initial broad scan
f0 = frequency(1);
CpGrid = linspace(CpGlobalMin, CpGlobalMax, options.gridPointsInitial);
RGrid = arrayfun(@(x) residualFcn(x, f0), CpGrid);

valid = isfinite(RGrid) & CpGrid > CpMinAbs;
CpGridValid = CpGrid(valid);
RGridValid = RGrid(valid);

if numel(CpGridValid) < 5
    error('Not enough valid points in initial scan.');
end

candidateIdx = findLocalMinima(RGridValid);
bestCp = nan;
bestR = inf;
scoreBest = inf;

for idx = candidateIdx(:).'
    CpLeft = CpGridValid(max(idx - 2, 1));
    CpRight = CpGridValid(min(idx + 2, numel(CpGridValid)));
    if CpRight <= CpLeft, continue; end

    obj = @(x) residualFcn(x, f0);
    try
        CpCandidate = fminbnd(obj, CpLeft, CpRight);
        RCandidate = obj(CpCandidate);
        if CpCandidate > CpMinAbs
            score = localScore(CpCandidate, RCandidate, options);
            if score < scoreBest
                bestCp = CpCandidate;
                bestR = RCandidate;
                scoreBest = score;
            end
        end
    catch
    end
end

if isnan(bestCp)
    error('Could not refine initial root.');
end

Cp(1) = bestCp;
residual(1) = bestR;

for i = 2:numel(frequency)
    fi = frequency(i);
    CpPrev = Cp(i - 1);
    if isnan(CpPrev), break; end

    searchFactors = [0.75, 1.25; 0.50, 1.60; 0.30, 2.20; 0.10, 4.00];
    bestCp = nan;
    bestR = inf;
    scoreBest = inf;

    for s = 1:size(searchFactors, 1)
        CpLow = max(CpGlobalMin, searchFactors(s, 1) * CpPrev);
        CpHigh = min(CpGlobalMax, searchFactors(s, 2) * CpPrev);
        if CpHigh <= CpLow, continue; end

        CpGrid = linspace(CpLow, CpHigh, options.gridPointsTracking);
        RGrid = arrayfun(@(x) residualFcn(x, fi), CpGrid);

        valid = isfinite(RGrid) & CpGrid > CpMinAbs;
        CpGridValid = CpGrid(valid);
        RGridValid = RGrid(valid);
        if numel(CpGridValid) < 5, continue; end

        candidateIdx = findLocalMinima(RGridValid);
        for idx = candidateIdx(:).'
            CpLeft = CpGridValid(max(idx - 2, 1));
            CpRight = CpGridValid(min(idx + 2, numel(CpGridValid)));
            if CpRight <= CpLeft, continue; end

            obj = @(x) residualFcn(x, fi);
            try
                CpCandidate = fminbnd(obj, CpLeft, CpRight);
                RCandidate = obj(CpCandidate);
                relJump = abs(CpCandidate - CpPrev) / max(CpPrev, eps);
                if CpCandidate > CpMinAbs && relJump < options.jumpTol
                    score = localScore(CpCandidate, RCandidate, options);
                    if score < scoreBest
                        bestCp = CpCandidate;
                        bestR = RCandidate;
                        scoreBest = score;
                    end
                end
            catch
            end
        end

        if ~isnan(bestCp) && bestR < options.residualTolerance
            break;
        end
    end

    Cp(i) = bestCp;
    residual(i) = bestR;
end
end

function score = localScore(CpCandidate, RCandidate, options)
score = RCandidate;
if isfield(options, 'initialCpGuess') && isfinite(options.initialCpGuess) && options.initialCpGuess > 0
    rel = abs(CpCandidate - options.initialCpGuess) / options.initialCpGuess;
    score = RCandidate * (1 + 0.2 * rel);
end
end

function idx = findLocalMinima(y)
idx = [];
if numel(y) < 3, return; end
for i = 2:numel(y)-1
    if isfinite(y(i)) && y(i) < y(i-1) && y(i) < y(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    [~, minIdx] = min(y);
    idx = minIdx;
end
end
