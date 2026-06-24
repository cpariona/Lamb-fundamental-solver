function summary = assessFitIdentifiability(S, freeParams)
%ASSESSFITIDENTIFIABILITY Assess local identifiability from a sensitivity matrix.
%
% S has one row per valid experimental point and one column per free
% parameter. The helper reports rank, condition number, sensitivity-column
% correlations, and a coarse classification.

if nargin < 1 || ~isnumeric(S) || isempty(S)
    error('S must be a nonempty numeric sensitivity matrix.');
end
if nargin < 2 || isempty(freeParams)
    freeParams = "theta" + string(1:size(S, 2));
end

freeParams = string(freeParams(:));
if numel(freeParams) ~= size(S, 2)
    error('freeParams must have one name per sensitivity column.');
end

finiteRows = all(isfinite(S), 2);
Sfinite = S(finiteRows, :);

summary = struct();
summary.freeParams = freeParams;
summary.numValidRows = size(Sfinite, 1);
summary.numParameters = size(S, 2);
summary.numFiniteRows = nnz(finiteRows);
summary.rank = rank(Sfinite);

if isempty(Sfinite) || size(Sfinite, 1) < 1
    summary.conditionNumber = Inf;
    summary.correlationMatrix = NaN(size(S, 2));
    summary.maxAbsOffDiagonalCorrelation = NaN;
    summary.classification = "insufficient_data";
    summary.message = "No finite sensitivity rows are available.";
    return;
end

normalMatrix = Sfinite.' * Sfinite;
summary.conditionNumber = cond(normalMatrix);
summary.correlationMatrix = localColumnCorrelation(Sfinite);
summary.maxAbsOffDiagonalCorrelation = localMaxAbsOffDiagonal(summary.correlationMatrix);

if summary.numValidRows < summary.numParameters
    summary.classification = "underdetermined";
    summary.message = "Fewer valid data points than free parameters.";
elseif summary.rank < summary.numParameters
    summary.classification = "rank_deficient";
    summary.message = "Sensitivity matrix is rank deficient.";
elseif summary.conditionNumber > 1e6
    summary.classification = "ill_conditioned";
    summary.message = "Sensitivity normal matrix is ill-conditioned.";
elseif summary.conditionNumber > 1e4 || summary.maxAbsOffDiagonalCorrelation > 0.95
    summary.classification = "weakly_identifiable";
    summary.message = "Fit is potentially weakly identifiable.";
else
    summary.classification = "locally_identifiable";
    summary.message = "Local sensitivity suggests the selected parameters are identifiable.";
end
end

function C = localColumnCorrelation(S)
numParameters = size(S, 2);
C = eye(numParameters);
if numParameters == 1
    return;
end

for i = 1:numParameters
    for j = i+1:numParameters
        si = S(:, i);
        sj = S(:, j);
        si = si - mean(si);
        sj = sj - mean(sj);
        denom = sqrt(sum(si.^2) * sum(sj.^2));
        if denom > 0
            value = sum(si .* sj) / denom;
        else
            value = NaN;
        end
        C(i, j) = value;
        C(j, i) = value;
    end
end
end

function value = localMaxAbsOffDiagonal(C)
if size(C, 1) <= 1
    value = 0;
    return;
end
mask = ~eye(size(C));
values = abs(C(mask));
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end
