function options = aeDefaultSweepOptions(robustness)
%AEDEFAULTSWEEPOPTIONS Default AE IOP/HGO options for sweep workflows.

if nargin < 1 || isempty(robustness)
    robustness = "Balanced";
end

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
[options.atlasNumYPoints, options.atlasTopNMinima] = localAtlasPreset(robustness);
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
