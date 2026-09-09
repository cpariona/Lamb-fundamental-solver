function options = mrlfeDefaultOptions()
%MRLFEDEFAULTOPTIONS Public default numerical and policy options for mRLFE.
%   Production presets are fast, balanced, robust, and dense. A0Like uses
%   physicalTail termination, S0Like uses none, and production fallback is
%   disabled. Presets control numerical effort, not physical meaning.

options = struct();
options.numerics = struct('preset', "fast");
options.selection = struct('strategy', "adaptive");
options.termination = struct( ...
    'A0Like', "physicalTail", ...
    'S0Like', "none");
options.fallback = struct('policy', "none");
options.quality = struct( ...
    'minValidFraction', 0.50, ...
    'maxRelativeJump', 0.25);
end
