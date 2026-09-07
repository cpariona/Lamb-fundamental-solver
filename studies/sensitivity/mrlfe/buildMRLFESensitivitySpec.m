function [sweepSpec, caseInfo] = buildMRLFESensitivitySpec(sweepName)
%MRLFEMAKESWEEPSPEC Build maintained one-parameter mRLFE sweep specs.
%
% Supported sweepName values:
%   "mu"         -> shear-modulus sweep, displayed in kPa
%   "viscosity"  -> etaS sweep, displayed in Pa*s
%   "thickness"  -> full-thickness 2h sweep, displayed in mm

sweepName = lower(string(sweepName));
if sweepName == "stiffness"
    sweepName = "mu";
end

sweepSpec = struct();
caseInfo = struct();
caseInfo.sweepName = sweepName;
caseInfo.modelName = "mRLFERealK";
caseInfo.fixedEtaS = 0.05;
caseInfo.showLastValidPoint = false;

switch sweepName
    case "mu"
        mu_kPa = [60, 65, 70, 75, 80];
        sweepSpec.parameter = "mu";
        sweepSpec.parameterPath = "params.mu";
        sweepSpec.values = mu_kPa * 1e3;
        sweepSpec.displayValues = mu_kPa;
        sweepSpec.label = "Shear modulus mu";
        sweepSpec.units = "kPa";
        sweepSpec.displayScale = 1e3;
        caseInfo.fixedEtaS = 0.05;
        caseInfo.titleParameter = "shear modulus";
        caseInfo.taskName = "mu_sweep";
        caseInfo.filePrefix = "mu_sweep_cp";

    case "viscosity"
        sweepSpec.parameter = "etaS";
        sweepSpec.parameterPath = "options.mrlfeParams.etaS";
        sweepSpec.values = [0, 0.1, 0.2, 0.3, 0.4, 0.5];
        sweepSpec.label = "etaS";
        sweepSpec.units = "Pa*s";
        sweepSpec.displayScale = 1;
        caseInfo.fixedEtaS = 0;
        caseInfo.titleParameter = "shear viscosity";
        caseInfo.taskName = "etaS_sweep";
        caseInfo.filePrefix = "etaS_sweep_cp";

    case "thickness"
        thickness_mm = [0.3, 0.4, 0.5, 0.6, 0.7];
        sweepSpec.parameter = "thickness";
        sweepSpec.parameterPath = "params.thickness";
        sweepSpec.values = thickness_mm * 1e-3;
        sweepSpec.displayValues = thickness_mm;
        sweepSpec.label = "Full thickness 2h";
        sweepSpec.units = "mm";
        sweepSpec.displayScale = 1e-3;
        caseInfo.fixedEtaS = 0.05;
        caseInfo.titleParameter = "full thickness";
        caseInfo.taskName = "thickness_sweep";
        caseInfo.filePrefix = "thickness_sweep_cp";

    otherwise
        error('Unsupported mRLFE sweepName "%s". Use "mu", "viscosity", or "thickness".', char(sweepName));
end
end
