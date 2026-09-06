function options = aeDefaultFitOptions(executionProfile)
%AEDEFAULTFITOPTIONS Default model options for AE IOP/HGO fitting.

if nargin < 1 || isempty(executionProfile)
    executionProfile = "Fast";
end
if string(executionProfile) == "Fast"
    executionProfile = "Fast";
elseif string(executionProfile) == "Robust"
    executionProfile = "Robust";
else
    executionProfile = "Balanced";
end

options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(struct( ...
    'M54_variant', "corrected", 'normalizeRows', false, ...
    'atlasBranchPolicy', "atlasA0"), ...
    'NumericalPreset', executionProfile);
end
