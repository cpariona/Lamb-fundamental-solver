function sweepResults = runParametricSweep(baseParams, baseOptions, sweepSpec)
% Run a one-parameter sweep using the current Lamb solver backend.
%
% Required sweepSpec fields:
%   parameter - Parameter name: "E", "thickness", "etaS", etc.
%   values    - Numeric vector of values in solver units.
%
% Optional sweepSpec fields:
%   label     - Human-readable parameter label.
%   units     - Display units for the legend.
%   scale     - Display scale. Example: 1e3 for Pa -> kPa.
%   verbose   - Print progress. Default: true.

arguments
    baseParams struct
    baseOptions struct
    sweepSpec struct
end

validateSweepSpec