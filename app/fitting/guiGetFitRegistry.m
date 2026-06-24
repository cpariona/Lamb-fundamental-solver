function registry = guiGetFitRegistry()
%GUIGETFITREGISTRY Return declarative fitting metadata for app/GUI callers.

registry = struct();
registry.defaultModelFamily = "rayleigh_lamb";
registry.modelFamilies = makeModelFamilies();
end

function modelFamilies = makeModelFamilies()
modelFamilies = repmat(emptyModelFamily(), 1, 2);
modelFamilies(1) = makeRLFamily();
modelFamilies(2) = makeMRLFEFamily();
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

function family = makeMRLFEFamily()
family = emptyModelFamily();
family.id = "mrlfe";
family.label = "mRLFE";
family.description = "Fit experimental dispersion data against mRLFE real-k A0-like/S0-like branches.";
family.defaultBranchName = "A0Like";
family.branchNames = ["A0Like", "S0Like"];
family.defaultRobustness = "Fast";
family.robustnessPresets = ["Fast", "Balanced", "Robust"];
family.defaultMode = "basic";
family.supportedModes = ["basic", "assisted"];
family.parameters = [ ...
    makeParameter("mu", "mu", "Shear modulus", "Pa", "kPa", 1e3, 75e3, [1e3, 1e6], true, ...
        "Shear modulus. First validated mRLFE fitting parameter."), ...
    makeParameter("etaS", "etaS", "Shear viscosity", "Pa*s", "Pa*s", 1, 0.05, [0, 1.0], true, ...
        "Shear viscosity for the real-k mRLFE viscous branch."), ...
    makeParameter("thickness", "thickness", "Thickness", "m", "mm", 1e-3, 0.50e-3, [0.05e-3, 5e-3], true, ...
        "Full plate thickness 2h."), ...
    makeParameter("rho", "rho", "Density", "kg/m^3", "kg/m^3", 1, 1070, [500, 2000], false, ...
        "Mass density. Fixed by default."), ...
    makeParameter("nu", "nu", "Poisson ratio", "", "", 1, 0.4999, [0.0, 0.49999], false, ...
        "Poisson ratio. Fixed by default."), ...
    makeParameter("fluidDensity", "fluidDensity", "Fluid density", "kg/m^3", "kg/m^3", 1, 1000, [1, 2000], false, ...
        "Fluid density. Stored in solver options, not in the elastic parameter struct."), ...
    makeParameter("fluidSoundSpeed", "fluidSoundSpeed", "Fluid sound speed", "m/s", "m/s", 1, 1500, [1, 3000], false, ...
        "Fluid sound speed. Stored in solver options, not in the elastic parameter struct.") ...
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
