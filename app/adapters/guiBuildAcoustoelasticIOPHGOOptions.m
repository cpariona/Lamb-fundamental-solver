function aeOptions = guiBuildAcoustoelasticIOPHGOOptions(robustness)
aeOptions = defaultAcoustoelasticIOPHGOOptions();
aeOptions.M54_variant = "corrected";
aeOptions.normalizeRows = false;
aeOptions.usePhysicalCpWindow = false;
aeOptions.atlasBranchPolicy = "atlasA0";
[aeOptions.atlasNumYPoints, aeOptions.atlasTopNMinima] = localAtlasPreset(robustness);
end

function [atlasNumYPoints, atlasTopNMinima] = localAtlasPreset(robustness)
switch string(robustness)
    case "Fast"
        atlasNumYPoints = 300;
        atlasTopNMinima = 12;
    case "Robust"
        atlasNumYPoints = 900;
        atlasTopNMinima = 20;
    otherwise
        atlasNumYPoints = 600;
        atlasTopNMinima = 16;
end
end
