function options = aeDefaultSweepOptions(robustness)
%AEDEFAULTSWEEPOPTIONS Default AE IOP/HGO options for sweep workflows.

if nargin < 1 || isempty(robustness)
    robustness = "Balanced";
end
if string(robustness) == "Fast"
    robustness = "Fast";
elseif string(robustness) == "Robust"
    robustness = "Robust";
else
    robustness = "Balanced";
end

options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(struct( ...
    'M54_variant', "corrected", 'normalizeRows', false, ...
    'atlasBranchPolicy', "atlasA0"), ...
    'NumericalPreset', robustness);
end
