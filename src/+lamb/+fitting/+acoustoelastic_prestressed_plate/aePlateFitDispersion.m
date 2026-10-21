function result = aePlateFitDispersion(experimental, physical, options)
%AEPLATEFITDISPERSION Original unweighted Li (2022) linear A0 inversion using SVD.
%   EXPERIMENTAL requires frequency_Hz, Cp_mps, logical validMask,
%   conditionId and directionId. Each ID is scalar text or one text value
%   per observation; selected observations must belong to ONE condition and
%   ONE signed propagation direction. Call separately for other groups.
%   PHYSICAL requires density_kgpm3 and CURRENT FULL thickness_m in SI.
%   The caller explicitly selects A0 observations within the Li assumptions.
%   No observation is sorted, averaged, removed or reweighted. Invalid
%   selected inputs throw an error; excluded inputs may be NaN.
%   OPTIONS.maximumConditionNumber (default 1e6) and minimumEtaSquaredSpan
%   (default 1e-3) are numerical qualification thresholds, not physical laws.
%   Fits rho*Cp^2 = alpha - gamma*eta^2, q=pi*f*thickness/Cp.
%   Residuals are fitted-minus-observed Pa, not speed residuals. Results keep
%   unconstrained candidates for diagnosis, but accepted is false for rank,
%   frequency-coverage, conditioning or physical-support failures. There is
%   no automatic stress/stretch interpretation of rejected candidates.

if nargin < 3
    options = struct();
end
validateattributes(experimental, {'struct'}, {'scalar'});
validateattributes(physical, {'struct'}, {'scalar'});
validateattributes(options, {'struct'}, {'scalar'});
defaults = struct('maximumConditionNumber', 1e6, 'minimumEtaSquaredSpan', 1e-3);
if any(~ismember(fieldnames(options), fieldnames(defaults)))
    error('lamb:aePlate:UnknownOption', 'Unknown linear inversion option.');
end
for name = string(fieldnames(defaults)).'
    if ~isfield(options, name)
        options.(name) = defaults.(name);
    end
    validateattributes(options.(name), {'double'}, {'real', 'scalar', 'finite', 'positive'});
end
if options.maximumConditionNumber <= 1 || options.minimumEtaSquaredSpan > 1
    error('lamb:aePlate:InvalidOption', 'Condition limit must exceed 1 and span must not exceed 1.');
end
for name = ["density_kgpm3", "thickness_m"]
    validateattributes(physical.(name), {'double'}, {'real', 'scalar', 'finite', 'positive'});
end
f = experimental.frequency_Hz;
cp = experimental.Cp_mps;
mask = experimental.validMask;
validateattributes(f, {'double'}, {'real', 'vector', 'nonempty'});
validateattributes(cp, {'double'}, {'real', 'vector', 'numel', numel(f)});
validateattributes(mask, {'logical'}, {'vector', 'numel', numel(f)});
f = f(:); cp = cp(:); mask = mask(:);
if ~any(mask) || any(~isfinite(f(mask)) | f(mask) <= 0 | ...
        ~isfinite(cp(mask)) | cp(mask) <= 0)
    error('lamb:aePlate:InvalidSelectedObservation', ...
        'Select at least one observation; all selected frequencies and speeds must be finite and positive.');
end
for name = ["conditionId", "directionId"]
    supplied = experimental.(name);
    if ~(isstring(supplied) || ischar(supplied) || iscellstr(supplied))
        error('lamb:aePlate:InvalidGrouping', 'IDs must be text.');
    end
    labels = string(supplied);
    if ~(isvector(labels) && (isscalar(labels) || numel(labels) == numel(f)))
        error('lamb:aePlate:InvalidGrouping', 'IDs must be scalar text or one value per observation.');
    end
    if ~isscalar(labels)
        labels = labels(mask);
    end
    if any(ismissing(labels) | strlength(strtrim(labels)) == 0) || numel(unique(labels)) ~= 1
        error('lamb:aePlate:MixedGrouping', 'Selected observations require one nonempty %s.', name);
    end
end
q = (pi*physical.thickness_m)*(f(mask)./cp(mask));
y = physical.density_kgpm3*cp(mask).^2;
if any(~isfinite(q) | q <= 0 | ~isfinite(y))
    error('lamb:aePlate:NumericalRange', 'Selected observations exceed numerical range.');
end
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
x = curve.etaSquared;
design = [ones(size(x)), -x];
[u, s, v] = svd(design, 'econ');
singularValues = diag(s);
rankTolerance = max(size(design))*eps(singularValues(1));
designRank = nnz(singularValues > rankTolerance);
conditionNumber = Inf;
candidate = [NaN; NaN];
residual = nan(size(y));
if designRank == 2
    conditionNumber = singularValues(1)/singularValues(2);
    candidate = v*((u.'*y)./singularValues);
    residual = design*candidate-y;
end

% Replicate scatter must not manufacture independent frequency coverage.
% Frequencies use exact supplied Hz identity; grouping/rounding is upstream.
[uniqueFrequency_Hz, ~, frequencyGroup] = unique(f(mask));
frequencyEtaSquared = accumarray(frequencyGroup, x, [], @mean);
independentDesign = [ones(size(frequencyEtaSquared)), -frequencyEtaSquared];
frequencySingularValues = svd(independentDesign, 'econ');
frequencyRank = nnz(frequencySingularValues > ...
    max(size(independentDesign))*eps(frequencySingularValues(1)));
frequencyCondition = Inf;
if frequencyRank == 2
    frequencyCondition = frequencySingularValues(1)/frequencySingularValues(2);
end
span = max(frequencyEtaSquared)-min(frequencyEtaSquared);
reasons = strings(0, 1);
if numel(uniqueFrequency_Hz) < 2
    reasons(end+1) = "insufficient_independent_frequencies";
end
if designRank < 2 || frequencyRank < 2
    reasons(end+1) = "rank_deficient";
end
if max(conditionNumber, frequencyCondition) > options.maximumConditionNumber
    reasons(end+1) = "poor_conditioning";
end
if span < options.minimumEtaSquaredSpan
    reasons(end+1) = "insufficient_dispersion_coverage";
end
physicalCandidate = all(isfinite(candidate)) && candidate(2) > 0 && candidate(1) >= candidate(2);
% A tiny negative stress difference may be unresolved at floating-point
% precision. Distinguish it from a resolved violation, without clipping or
% accepting a negative long-wave squared speed. This is not a noise bound.
stressRoundoffBound_Pa = NaN;
if designRank == 2 && ~physicalCandidate
    stressRoundoffBound_Pa = 32*eps(max(abs(candidate)))*conditionNumber;
    if all(candidate > 0) && candidate(1)-candidate(2) >= -stressRoundoffBound_Pa
        reasons(end+1) = "tensile_boundary_unresolved";
    else
        reasons(end+1) = "outside_tensile_model_support";
    end
end
fullQ = nan(size(f)); fullQ(mask) = q;
fullX = nan(size(f)); fullX(mask) = x;
fullResidual = nan(size(f)); fullResidual(mask) = residual;
result = struct('model', "acoustoelastic_prestressed_plate", 'experimental', experimental, ...
    'physical', physical, 'options', options, 'validMask', mask, ...
    'alpha_Pa', candidate(1), 'gamma_Pa', candidate(2), ...
    'accepted', isempty(reasons), 'reasons', reasons, ...
    'wavenumberThickness', fullQ, 'etaSquared', fullX, ...
    'regressionResidual_Pa', fullResidual, 'regressionRMSE_Pa', sqrt(mean(residual.^2)), ...
    'sumSquaredResidual_Pa2', sum(residual.^2), ...
    'diagnostics', struct('observationCount', nnz(mask), 'designRank', designRank, ...
    'singularValues', singularValues, 'rankTolerance', rankTolerance, ...
    'conditionNumber', conditionNumber, 'independentFrequencyCount', numel(uniqueFrequency_Hz), ...
    'uniqueFrequency_Hz', uniqueFrequency_Hz, 'frequencyGroup', frequencyGroup, ...
    'frequencyObservationCount', accumarray(frequencyGroup, 1), ...
    'frequencyEtaSquared', frequencyEtaSquared, 'frequencyDesignRank', frequencyRank, ...
    'frequencyConditionNumber', frequencyCondition, 'etaSquaredSpan', span, ...
    'physicalCandidate', physicalCandidate, 'stressDifferenceRoundoffBound_Pa', stressRoundoffBound_Pa));
end
