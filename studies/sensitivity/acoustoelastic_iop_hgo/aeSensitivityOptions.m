function options = aeSensitivityOptions(numericalPreset)
%AESENSITIVITYOPTIONS Build reference AE IOP/HGO options for sensitivity studies.

if nargin < 1 || isempty(numericalPreset)
    numericalPreset = "Balanced";
end
if string(numericalPreset) == "Fast"
    numericalPreset = "Fast";
elseif string(numericalPreset) == "Robust"
    numericalPreset = "Robust";
else
    numericalPreset = "Balanced";
end

options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(struct( ...
    'M54_variant', "corrected", 'normalizeRows', false, ...
    'atlasBranchPolicy', "atlasA0"), ...
    'NumericalPreset', numericalPreset);
end
