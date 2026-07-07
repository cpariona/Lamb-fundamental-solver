function preset = mrlfeGetNumericalPreset(name)
%MRLFEGETNUMERICALPRESET Resolve a public mRLFE numerical preset.

if nargin < 1 || isempty(name)
    name = "fast";
end

name = lower(string(name));
switch name
    case "fast"
        preset = struct();
        preset.name = "fast";
        preset.description = "Reduced atlas preset matching the maintained FitTool fast-atlas route.";
        preset.scanPoints = 260;
        preset.candidateCount = 5;
        preset.refineCandidates = false;
        preset.adaptiveWindows = [0.20 0.40 0.80];
        preset.internalFitAtlasPreset = "fast_fit_atlas";
        preset.useFitAtlasPreset = true;

    case "dense"
        preset = struct();
        preset.name = "dense";
        preset.description = "Maintained dense/reference atlas configuration.";
        preset.scanPoints = 900;
        preset.candidateCount = 8;
        preset.refineCandidates = true;
        preset.adaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
        preset.internalFitAtlasPreset = "off";
        preset.useFitAtlasPreset = false;

    otherwise
        error('mrlfe:InvalidNumericalPreset', ...
            'Unsupported mRLFE numerical preset "%s". Use "fast" or "dense".', name);
end
end
