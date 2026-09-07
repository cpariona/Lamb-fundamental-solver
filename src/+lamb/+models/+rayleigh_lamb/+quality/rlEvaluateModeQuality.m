function quality = rlEvaluateModeQuality(modes)
%RLEVALUATEMODEQUALITY Assess canonical Rayleigh-Lamb branch quality.

quality = struct();
names = fieldnames(modes);
for i = 1:numel(names)
    branch = modes.(names{i});
    valid = logical(branch.validMask(:)) & isfinite(branch.phaseVelocity_mps(:));
    pointCount = numel(valid);
    validCount = nnz(valid);
    accepted = all(valid);
    if accepted
        reason = "accepted";
    elseif validCount == 0
        reason = "no_valid_points";
    else
        reason = "incomplete_branch";
    end
    quality.(names{i}) = struct( ...
        'pointCount', pointCount, ...
        'validCount', validCount, ...
        'validFraction', validCount / max(pointCount, 1), ...
        'accepted', accepted, ...
        'reason', reason);
end
end
