function registry = guiGetFitRegistry()
%GUIGETFITREGISTRY Return declarative fitting metadata for app/GUI callers.
%
% Phase 3 exposes only Rayleigh-Lamb fitting. Other model families should be
% added here only after their model-specific fitting helpers are implemented.

registry = struct();
registry.defaultModelFamily = "rayleigh_lamb";
registry.modelFamilies = makeModelFamilies();
end

function modelFamilies = makeModelFamilies()
modelFamilies = makeRLFamily();
end

function family = makeRLFamily()
family = emptyModelFamily();
family.id = "rayleigh_lamb";
family.label = "Rayleigh-Lamb";
family.description = "Fit experimental dispersion data against Rayleigh-Lamb A0/S0 branches.";
family.defaultBranchName = "A0";
family.branchNames = ["A0", "S0"];
family.defaultRobustness = "Fast";
family.robustnessPresets = ["Fast", "Balanced", "Robust"];
family.defaultMode = "basic";
family.supportedModes = ["basic", "assisted"];
family.parameters = [ ...
    makeParameter("mu", "mu", "Shear modulus", "Pa", "kPa", 1e3, 85e3, [1e3, 1e6], true, ...
        "Shear modulus. Recommended first free parameter for A0 fitting."), ...
    makeParameter("thickness", "thickness", "Thickness", "m", "mm", 1e-3, 0.50e-3, [0.05e-3, 5e-3], true, ...
        "Full plate thickness 2h."), ...
    makeParameter("rho", "rho", "Density", "kg/m^3", "kg/m^3", 1, 1070, [500, 2000], false, ...
        "Mass density. Fixed by default."), ...
    makeParameter("nu", "nu", "Poisson ratio", "", "", 1, 0.4999, [0.0, 0.49999], false, ...
        "Poisson ratio. Fixed by default for soft nearly incompressible materials.") ...
    ];
end

function family = emptyModelFamily()
family = struct();
family.id = "";
family.label = "";
family.description = "";
family.defaultBranchName = "";
family.branchNames = strings(1, 0);
family.defaultRobustness = "";
family.robustnessPresets = strings(1, 0);
family.defaultMode = "basic";
family.supportedModes = "basic";
family.parameters = repmat(emptyParameter(), 1, 0);
end

function param = makeParameter(id, fieldName, label, solverUnit, displayUnit, displayScale, defaultValue, bounds, canFit, helpText)
param = emptyParameter();
param.id = string(id);
param.fieldName = string(fieldName);
param.label = string(label);
param.solverUnit = string(solverUnit);
param.displayUnit = string(displayUnit);
param.displayScale = displayScale;
param.defaultValue = defaultValue;
param.defaultDisplayValue = defaultValue ./ displayScale;
param.bounds = bounds;
param.boundsDisplay = bounds ./ displayScale;
param.canFit = logical(canFit);
param.helpText = string(helpText);
end

function param = emptyParameter()
param = struct();
param.id = "";
param.fieldName = "";
param.label = "";
param.solverUnit = "";
param.displayUnit = "";
param.displayScale = 1;
param.defaultValue = [];
param.defaultDisplayValue = [];
param.bounds = [];
param.boundsDisplay = [];
param.canFit = false;
param.helpText = "";
end
