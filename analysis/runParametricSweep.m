function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec)
% Run a one-parameter sweep using the current Lamb solver backend.
%
% Inputs:
%   baseParams  - Parameter struct accepted by computeFundamentalLambModes.
%   baseOptions - Options struct accepted by computeFundamentalLambModes.
%   sweepSpec   - Struct with fields:
%       parameter : parameter name, e.g. "etaS", "E", "thickness".
%       values    : numeric vector of values