function summaryTable = summarizeMRLFETrackingQuality(results, labels, varargin)
%SUMMARIZEMRLFETRACKINGQUALITY Summarize mRLFE tracking quality metrics.
%
% summaryTable = summarizeMRLFETrackingQuality(results, labels) accepts either
% mRLFE result structs with a branches field or individual branch structs. The
% metrics are diagnostic and intended for comparing maintained tracking
% strategies, such as direct tracking versus the internal-grid policy.

p = inputParser;
addParameter(p, 'BranchName', "A0Like", @(x)ischar(x) || isstring(x));
addParameter(p, 'Print', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'RoughnessWeight', 1.0, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'JumpWeight', 1.0, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'InvalidWeight', 1.0, @(x)isnumeric(x) && isscalar(x));
parse(p, varargin{:});

if ~iscell(results)
    results = num2cell(results);
end
labels = string(labels(:));

n = numel(results);
if numel(labels) ~= n
    error('summarizeMRLFETrackingQuality:LabelCountMismatch', ...
        'labels must contain one entry per result.');
end

branchName = string(p.Results.BranchName);
Strategy = labels;
Branch = repmat(branchName, n, 1);
UsedInternalGrid = false(n, 1);
RequestedPoints = nan(n, 1);
TrackingPoints = nan(n, 1);
ValidPoints = zeros(n, 1);
TotalPoints = zeros(n, 1);
ValidFraction = nan(n, 1);
MinFrequency_kHz = nan(n, 1);
MaxFrequency_kHz = nan(n, 1);
MinCp = nan(n, 1);
MaxCp = nan(n, 1);
MedianCp = nan(n, 1);
MaxRelJump = nan(n, 1);
MedianRelJump = nan(n, 1);
Roughness = nan(n, 1);
MedianResidual = nan(n, 1);
MaxResidual = nan(n, 1);
MedianScore = nan(n, 1);
FirstMissingFrequency_kHz = nan(n, 1);
QualityScore = nan(n, 1);

for i = 1:n
    branch = extractBranch(results{i}, branchName);
    f = branch.frequency(:);
    cp = branch.Cp(:);
    valid = extractValidMask(branch, cp, f);
    residual = extractNumericVector(branch, 'residual', numel(cp));
    score = extractNumericVector(branch, 'score', numel(cp));

    TotalPoints(i) = numel(cp);
    ValidPoints(i) = nnz(valid);
    ValidFraction(i) = ValidPoints(i) / max(TotalPoints(i), 1);

    if isfield(branch, 'internalTracking') && isstruct(branch.internalTracking)
        if isfield(branch.internalTracking, 'used')
            UsedInternalGrid(i) = logical(branch.internalTracking.used);
        end
        if isfield(branch.internalTracking, 'trackingFrequency')
            TrackingPoints(i) = numel(branch.internalTracking.trackingFrequency);
        end
    end
    RequestedPoints(i) = numel(f);
    if ~isfinite(TrackingPoints(i))
        TrackingPoints(i) = RequestedPoints(i);
    end

    if isfield(branch, 'firstMissingModalMinimumFrequency') && isfinite(branch.firstMissingModalMinimumFrequency)
        FirstMissingFrequency_kHz(i) = branch.firstMissingModalMinimumFrequency / 1e3;
    end

    if any(valid)
        cpv = cp(valid);
        fv = f(valid);
        MinFrequency_kHz(i) = min(fv) / 1e3;
        MaxFrequency_kHz(i) = max(fv) / 1e3;
        MinCp(i) = min(cpv);
        MaxCp(i) = max(cpv);
        MedianCp(i) = median(cpv, 'omitnan');

        if numel(cpv) >= 2
            relJump = abs(diff(cpv)) ./ max(abs(cpv(1:end-1)), eps);
            MaxRelJump(i) = max(relJump, [], 'omitnan');
            MedianRelJump(i) = median(relJump, 'omitnan');
        end
        if numel(cpv) >= 3
            Roughness(i) = median(abs(diff(cpv, 2)), 'omitnan') / max(median(abs(cpv), 'omitnan'), eps);
        end
        MedianResidual(i) = median(residual(valid), 'omitnan');
        MaxResidual(i) = max(residual(valid), [], 'omitnan');
        MedianScore(i) = median(score(valid), 'omitnan');
    end

    invalidPenalty = 1 - ValidFraction(i);
    QualityScore(i) = p.Results.RoughnessWeight * fillMetric(Roughness(i)) + ...
        p.Results.JumpWeight * fillMetric(MaxRelJump(i)) + ...
        p.Results.InvalidWeight * invalidPenalty;
end

summaryTable = table(Strategy, Branch, UsedInternalGrid, RequestedPoints, TrackingPoints, ...
    ValidPoints, TotalPoints, ValidFraction, MinFrequency_kHz, MaxFrequency_kHz, ...
    MinCp, MaxCp, MedianCp, MaxRelJump, MedianRelJump, Roughness, ...
    MedianResidual, MaxResidual, MedianScore, FirstMissingFrequency_kHz, QualityScore);
summaryTable = sortrows(summaryTable, 'QualityScore', 'ascend');

if p.Results.Print
    disp(summaryTable);
end
end

function branch = extractBranch(result, branchName)
branch = result;
if isstruct(result) && isfield(result, 'model') && string(result.model) == "mrlfe"
    if string(result.branch) ~= branchName
        error('summarizeMRLFETrackingQuality:MissingBranch', ...
            'mRLFE public result is for branch %s, not %s.', result.branch, branchName);
    end
    branch = result.debug.rawInternalResult.branch;
end
if isstruct(result) && isfield(result, 'branches')
    if ~isfield(result.branches, char(branchName))
        error('summarizeMRLFETrackingQuality:MissingBranch', ...
            'mRLFE result does not contain branch %s.', branchName);
    end
    branch = result.branches.(char(branchName));
end
if ~isstruct(branch) || ~isfield(branch, 'Cp') || ~isfield(branch, 'frequency')
    error('summarizeMRLFETrackingQuality:InvalidBranch', ...
        'Each input must be an mRLFE result with branches or a branch with Cp and frequency.');
end
end

function valid = extractValidMask(branch, cp, f)
if isfield(branch, 'validCp')
    valid = logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = logical(branch.valid(:));
else
    valid = isfinite(cp);
end
valid = valid & isfinite(cp) & isfinite(f);
end

function values = extractNumericVector(branch, fieldName, n)
if isfield(branch, fieldName) && numel(branch.(fieldName)) == n
    values = branch.(fieldName)(:);
else
    values = nan(n, 1);
end
end

function y = fillMetric(x)
if isfinite(x)
    y = x;
else
    y = 10;
end
end
