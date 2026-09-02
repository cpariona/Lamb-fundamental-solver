function [sweepSpec, caseInfo] = rlMakeSweepSpec(sweepName)
%RLMAKESWEEPSPEC Build maintained one-parameter Rayleigh-Lamb sweep specs.
%
% Supported sweepName values:
%   "thickness" -> full-thickness 2h sweep, displayed in mm

sweepName = lower(string(sweepName));

sweepSpec = struct();
caseInfo = struct();
caseInfo.sweepName = sweepName;
caseInfo.modelName = "RayleighLamb";

switch sweepName
    case "thickness"
        thickness_mm = [0.3, 0.4, 0.5, 0.6, 0.7];
        sweepSpec.parameter = "thickness";
        sweepSpec.parameterPath = "params.thickness";
        sweepSpec.values = thickness_mm * 1e-3;
        sweepSpec.displayValues = thickness_mm;
        sweepSpec.label = "Full thickness 2h";
        sweepSpec.units = "mm";
        sweepSpec.displayScale = 1e-3;
        caseInfo.titleParameter = "full thickness";
        caseInfo.taskName = "thickness_sweep";
        caseInfo.filePrefix = "thickness_sweep_cp";

    otherwise
        error('Unsupported Rayleigh-Lamb sweepName "%s". Use "thickness".', char(sweepName));
end
end
