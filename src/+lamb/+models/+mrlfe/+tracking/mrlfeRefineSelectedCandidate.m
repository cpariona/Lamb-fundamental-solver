function best = mrlfeRefineSelectedCandidate(best, CpScan, center, omega, material, geometry, mrlfeParams, tracker)
%MRLFEREFINESELECTEDCANDIDATE Refine one selected local minimum on the true residual.
%
% Candidate discovery and branch selection remain on the discrete Cp scan.
% Only the already selected local-minimum candidate is refined, so continuous
% minimization cannot change branch identity or candidate ranking.

if ~best.valid || best.type ~= "localMinimum" || ~isfinite(best.cp) || best.cp <= 0
    return;
end

CpScan = CpScan(:);
[~, scanIndex] = min(abs(CpScan - best.cp));
if scanIndex <= 1 || scanIndex >= numel(CpScan)
    return;
end

lower = CpScan(scanIndex - 1);
upper = CpScan(scanIndex + 1);
if ~isfinite(lower) || ~isfinite(upper) || upper <= lower
    return;
end

objective = @(cp) lamb.models.mrlfe.core.mrlfeResidual(omega / cp, omega, material, geometry, mrlfeParams);
opt = optimset('Display', 'off', ...
    'TolX', tracker.refineTolX, ...
    'MaxIter', tracker.refineMaxIter, ...
    'MaxFunEvals', tracker.refineMaxFunEvals);

try
    % Squaring the nonnegative residual preserves its minimum and removes
    % the elastic-root cusp. Score the selected root with the original residual.
    cpRefined = fminbnd(@(cp)objective(cp).^2, lower, upper, opt);
    residualRefined = objective(cpRefined);
catch
    return;
end

if ~isfinite(cpRefined) || cpRefined <= 0 || ~isfinite(residualRefined)
    return;
end

best.cp = cpRefined;
best.residual = residualRefined;
predTerm = abs(cpRefined - center) / max(abs(center), eps);
resTerm = log10(max(residualRefined, tracker.residualFloor));
best.score = tracker.residualWeight * resTerm + tracker.predictionWeight * predTerm.^2;
end
