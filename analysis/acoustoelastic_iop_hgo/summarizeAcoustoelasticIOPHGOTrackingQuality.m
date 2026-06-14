function summaryTable = summarizeAcoustoelasticIOPHGOTrackingQuality(results, labels, varargin)
%SUMMARIZEACOUSTOELASTICIOPHGOTRACKINGQUALITY Summarize Acoustoelastic IOP/HGO tracking quality metrics.
%
% summaryTable = summarizeAcoustoelasticIOPHGOTrackingQuality(results, labels)
%
% Inputs:
%   results : cell array of Acoustoelastic IOP/HGO result structs. Supports real-Cp results
%             with field Cp and complex-C results with field CpReal.
%   labels  : string/cell array with one label per result.
%
% The metrics are diagnostic. They are not a substitute for physical
% validation, but they help compare tracking strategies consistently.

p = inputParser;
addParameter(p, 'Print', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'RoughnessWeight', 1.0, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'JumpWeight', 1.0, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'MACWeight', 0.5, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'ImagWeight', 1.0, @(x)isnumeric(x) && isscalar(x));
parse(p, varargin{:});

if ~iscell(results)
    results = num2cell(results);
end
labels = string(labels(:));

n = numel(results);
if numel(labels) ~= n
    error('labels must contain one entry per result.');
end

Strategy = labels;
TrackingMethod = strings(n, 1);
Direction = strings(n, 1);
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
MedianObjective = nan(n, 1);
MedianSigmaMin = nan(n, 1);
MedianMAC = nan(n, 1);
MinMAC = nan(n, 1);
MedianAbsImagOverReal = nan(n, 1);
QualityScore = nan(n, 1);

for i = 1:n
    r = results{i};
    [cp, f, valid, cpImag] = extractCurve(r);
    TotalPoints(i) = numel(cp);
    ValidPoints(i) = nnz(valid);
    ValidFraction(i) = ValidPoints(i) / max(TotalPoints(i), 1);

    if isfield(r, 'options')
        if isfield(r.options, 'trackingMethod')
            TrackingMethod(i) = string(r.options.trackingMethod);
        elseif isfield(r, 'CpComplex')
            TrackingMethod(i) = "complexDetContinuation";
        else
            TrackingMethod(i) = "unknown";
        end
        if isfield(r.options, 'trackingDirection')
            Direction(i) = string(r.options.trackingDirection);
        else
            Direction(i) = "unknown";
        end
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
            d2 = diff(cpv, 2);
            Roughness(i) = median(abs(d2), 'omitnan') / max(median(abs(cpv), 'omitnan'), eps);
        end

        if isfield(r, 'objective')
            MedianObjective(i) = median(r.objective(valid), 'omitnan');
        end
        if isfield(r, 'sigmaMin')
            MedianSigmaMin(i) = median(r.sigmaMin(valid), 'omitnan');
        end
        if isfield(r, 'modalMAC')
            MedianMAC(i) = median(r.modalMAC(valid), 'omitnan');
            MinMAC(i) = min(r.modalMAC(valid), [], 'omitnan');
        end
        if ~isempty(cpImag)
            MedianAbsImagOverReal(i) = median(abs(cpImag(valid)) ./ max(abs(cpv), eps), 'omitnan');
        end

        macPenalty = 0;
        if isfinite(MedianMAC(i))
            macPenalty = 1 - MedianMAC(i);
        end
        imagPenalty = 0;
        if isfinite(MedianAbsImagOverReal(i))
            imagPenalty = MedianAbsImagOverReal(i);
        end
        QualityScore(i) = p.Results.RoughnessWeight * fillMetric(Roughness(i)) + ...
            p.Results.JumpWeight * fillMetric(MaxRelJump(i)) + ...
            p.Results.MACWeight * macPenalty + ...
            p.Results.ImagWeight * imagPenalty;
    end
end

summaryTable = table(Strategy, TrackingMethod, Direction, ValidPoints, TotalPoints, ValidFraction, ...
    MinFrequency_kHz, MaxFrequency_kHz, MinCp, MaxCp, MedianCp, ...
    MaxRelJump, MedianRelJump, Roughness, MedianObjective, MedianSigmaMin, ...
    MedianMAC, MinMAC, MedianAbsImagOverReal, QualityScore);

summaryTable = sortrows(summaryTable, 'QualityScore', 'ascend');

if p.Results.Print
    disp(summaryTable);
end
end

function [cp, f, valid, cpImag] = extractCurve(r)
if isfield(r, 'Cp')
    cp = r.Cp(:);
elseif isfield(r, 'CpReal')
    cp = r.CpReal(:);
else
    error('Result struct must contain Cp or CpReal.');
end

if isfield(r, 'frequency')
    f = r.frequency(:);
else
    f = (1:numel(cp)).';
end

if isfield(r, 'validCp')
    valid = logical(r.validCp(:));
elseif isfield(r, 'valid')
    valid = logical(r.valid(:));
else
    valid = isfinite(cp);
end
valid = valid & isfinite(cp) & isfinite(f);

if isfield(r, 'CpImag')
    cpImag = r.CpImag(:);
else
    cpImag = [];
end
end

function y = fillMetric(x)
if isfinite(x)
    y = x;
else
    y = 10;
end
end
