function [overrides, canonicalName] = aeGetNumericalPreset(presetName)
%AEGETNUMERICALPRESET Return maintained AE numerical preset values.

name = lower(strtrim(string(presetName)));
if numel(name) ~= 1 || strlength(name) == 0
    error('lamb.models.acoustoelastic_iop_hgo.configuration.aeGetNumericalPreset:InvalidPreset', ...
        'AE numerical preset must be Fast, Balanced, or Robust.');
end

switch name
    case "fast"
        canonicalName = "Fast";
        overrides = struct('atlasNumYPoints', 300, 'atlasTopNMinima', 12);
    case "balanced"
        canonicalName = "Balanced";
        overrides = struct('atlasNumYPoints', 600, 'atlasTopNMinima', 16);
    case "robust"
        canonicalName = "Robust";
        overrides = struct('atlasNumYPoints', 900, 'atlasTopNMinima', 20);
    otherwise
        error('lamb.models.acoustoelastic_iop_hgo.configuration.aeGetNumericalPreset:InvalidPreset', ...
            'Unknown AE numerical preset "%s".', string(presetName));
end
end
