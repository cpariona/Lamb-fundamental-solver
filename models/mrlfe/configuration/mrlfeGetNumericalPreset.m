function preset = mrlfeGetNumericalPreset(name)
%MRLFEGETNUMERICALPRESET Resolve a public mRLFE numerical preset.

if nargin < 1 || isempty(name)
    name = "fast";
end

name = lower(string(name));
switch name
    case "fast"
        preset = basePreset();
        preset.name = "fast";
        preset.description = "Reduced adaptive preset with coarse Cp scanning and dense rescue.";
        preset.frequencyStep_Hz = 50;
        preset.scanPoints = 100;
        preset.rescueScanPoints = 260;
        preset.candidateCount = 5;
        preset.adaptiveWindows = [0.20 0.40 0.80];
        preset.internalFitAtlasPreset = "fast";
        preset.useFitAtlasPreset = true;

    case "balanced"
        preset = basePreset();
        preset.name = "balanced";
        preset.description = "Balanced production preset with intermediate frequency-grid resolution.";
        preset.frequencyStep_Hz = 25;
        preset.scanPoints = 420;
        preset.rescueScanPoints = 420;
        preset.candidateCount = 6;
        preset.adaptiveWindows = [0.20 0.35 0.50 0.80];
        preset.internalFitAtlasPreset = "fast";
        preset.useFitAtlasPreset = true;

    case "robust"
        preset = basePreset();
        preset.name = "robust";
        preset.description = "Robust production preset with fine frequency-grid resolution.";
        preset.frequencyStep_Hz = 20;
        preset.scanPoints = 620;
        preset.rescueScanPoints = 620;
        preset.candidateCount = 8;
        preset.adaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
        preset.internalFitAtlasPreset = "dense";
        preset.useFitAtlasPreset = false;

    case "dense"
        preset = basePreset();
        preset.name = "dense";
        preset.description = "Maintained dense/reference atlas configuration.";
        preset.frequencyStep_Hz = 10;
        preset.scanPoints = 900;
        preset.rescueScanPoints = 900;
        preset.candidateCount = 8;
        preset.adaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
        preset.internalFitAtlasPreset = "dense";
        preset.useFitAtlasPreset = false;

    otherwise
        error('mrlfe:InvalidNumericalPreset', ...
            ['Unsupported mRLFE numerical preset "%s". Use "fast", ' ...
             '"balanced", "robust", or "dense".'], name);
end
end

function preset = basePreset()
preset = struct();
preset.frequencyGridPolicy = "fixedLowAnchorsConstantHighStep";
preset.transitionFrequency_Hz = 500;
preset.lowFrequencyAnchors_Hz = [ ...
    10:10:100, ...
    125:25:250, ...
    300:50:500].';
end
