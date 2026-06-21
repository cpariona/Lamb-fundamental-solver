function [sweepSpec, caseInfo] = mrlfeMakeSweepSpec(sweepName)
%MRLFEMAKESWEEPSPEC Build maintained one-parameter mRLFE sweep specs.
%
% Supported sweepName values:
%   "viscosity"  -> etaS sweep, displayed in Pa*s
%   "stiffness"  -> E sweep, displayed in kPa
%   "thickness"  -> thickness sweep, displayed in mm

sweepName = lower(string(sweepName));

sweepSpec = struct();
caseInfo = struct();
caseInfo.sweepName = sweepName;
caseInfo.modelName = "mRLFEHanViscoRealK";
caseInfo.fixedEtaS = 0.05;
caseInfo.showLastValidPoint = false;

switch sweepName
    case "viscosity"
        sweepSpec.parameter = "etaS";
        sweepSpec.values = [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50];
        sweepSpec.label = "etaS";
        sweepSpec.units = "Pa*s";
        sweepSpec.displayScale = 1;
        caseInfo.fixedEtaS = 0;
        caseInfo.titleParameter = "etaS";
        caseInfo.titleNoun = "shear viscosity etaS";

    case "stiffness"
        sweepSpec.parameter = "E";
        sweepSpec.values = [50, 100, 300, 500, 1000, 1500] * 1e3;
        sweepSpec.label = "E";
        sweepSpec.units = "kPa";
        sweepSpec.displayScale = 1e3;
        caseInfo.fixedEtaS = 0.05;
        caseInfo.titleParameter = "stiffness E";
        caseInfo.titleNoun = "stiffness E";

    case "thickness"
        sweepSpec.parameter = "thickness";
        sweepSpec.values = [0.3, 0.5, 0.7, 1.0] * 1e-3;
        sweepSpec.label = "thickness";
        sweepSpec.units = "mm";
        sweepSpec.displayScale = 1e-3;
        caseInfo.fixedEtaS = 0.05;
        caseInfo.titleParameter = "thickness";
        caseInfo.titleNoun = "thickness";
        caseInfo.showLastValidPoint = true;

    otherwise
        error('Unsupported mRLFE sweepName "%s". Use "viscosity", "stiffness", or "thickness".', sweepName);
end
end
