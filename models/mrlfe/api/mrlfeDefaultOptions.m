function options = mrlfeDefaultOptions()
%MRLFEDEFAULTOPTIONS Public default numerical and policy options for mRLFE.

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
