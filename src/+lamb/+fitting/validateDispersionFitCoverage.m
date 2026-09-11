function [coverage, experimental] = validateDispersionFitCoverage(CpModel_mps, experimental)
%VALIDATEDISPERSIONFITCOVERAGE Require complete model coverage of fit points.
%
% The objective mask is fixed by experimental.validMask. Model evaluations may
% return nonfinite values outside that mask, but every selected experimental
% point must have a finite model prediction. This prevents an optimizer from
% improving its objective by silently dropping observations.

experimental = lamb.fitting.validateExperimentalDispersionData(experimental, 1);
CpModel_mps = CpModel_mps(:);

if numel(CpModel_mps) ~= experimental.numPoints
    error('CpModel_mps must match the number of experimental points.');
end

objectiveMask = logical(experimental.validMask(:));
modelFiniteMask = isfinite(CpModel_mps);
missingModelMask = objectiveMask & ~modelFiniteMask;

coverage = struct();
coverage.objectiveMask = objectiveMask;
coverage.modelFiniteMask = modelFiniteMask;
coverage.missingModelMask = missingModelMask;
coverage.expectedPointCount = nnz(objectiveMask);
coverage.evaluatedPointCount = nnz(objectiveMask & modelFiniteMask);
coverage.coverageAccepted = ~any(missingModelMask);
coverage.missingIndices = find(missingModelMask);
coverage.missingFrequency_Hz = experimental.frequency_Hz(missingModelMask);

if ~coverage.coverageAccepted
    firstMissingFrequency = coverage.missingFrequency_Hz(1);
    error('lamb:fitting:IncompleteModelCoverage', ...
        ['Model prediction is missing %d of %d required objective point(s); ' ...
         'first missing frequency %.9g Hz. Objective coverage is fixed by ' ...
         'experimental.validMask and cannot change during optimization.'], ...
        nnz(missingModelMask), coverage.expectedPointCount, firstMissingFrequency);
end
end
