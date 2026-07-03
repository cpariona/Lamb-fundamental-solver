function registry = guiGetFitRegistry()
%GUIGETFITREGISTRY Return declarative fitting metadata for app/GUI callers.

registry = struct();
registry.defaultModelFamily = "rayleigh_lamb";
registry.modelFamilies = makeModelFamilies();
end

function modelFamilies = makeModelFamilies()
modelFamilies = repmat(emptyModelFamily(), 1, 3);
modelFamilies(1) = makeRLFamily();
modelFamilies(2) = makeMRLFEFamily();
modelFamilies(3) = makeAEFamily();
end

function family = makeRLFamily()
family = emptyModelFamily();
family.id = "rayleigh_lamb";
family.label = "Rayleigh-Lamb";
family.description = "Fit experimental dispersion data against Rayleigh-Lamb A0/S0 branches.";
family.defaultBranchName = "A0";
family.branchNames = ["A0", "S0"];
family.defaultRobustness = "Fast";
family.defaultExecutionProfile = family.defaultRobustness;
family.surfaceDefaultExecutionProfile = family.defaultExecutionProfile;
family.robustnessPresets = guiExecutionProfileValues();
family.executionProfiles = family.robustnessPresets;
family.supportedExecutionProfiles = family.executionProfiles;
family.profileSupportMode = "fully_supported";
family.defaultMode = "basic";
family.supportedModes = ["basic", "assisted"];
family.parameters = [ ...
    makeParameter("mu", "mu", "Shear modulus", "Pa", "kPa", 1e3, 85e3, [1e3, 1e6], true, "fixedParams", ...
        "Shear modulus. Recommended first free parameter for A0 fitting."), ...
    makeParameter("thickness", "thickness", "Thickness", "m", "mm", 1e-3, 0.50e-3, [0.05e-3, 5e-3], true, "fixedParams", ...
        "Full plate thickness 2h."), ...
    makeParameter("rho", "rho", "Density", "kg/m^3", "kg/m^3", 1, 1070, [500, 2000], false, "fixedParams", ...
        "Mass density. Fixed by default."), ...
    makeParameter("nu", "nu", "Poisson ratio", "", "", 1, 0.4999, [0.0, 0.49999], false, "fixedParams", ...
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
family.defaultExecutionProfile = family.defaultRobustness;
family.surfaceDefaultExecutionProfile = family.defaultExecutionProfile;
family.robustnessPresets = guiExecutionProfileValues();
family.executionProfiles = family.robustnessPresets;
family.supportedExecutionProfiles = family.executionProfiles;
family.profileSupportMode = "mapped_to_fast";
family.defaultMode = "basic";
family.supportedModes = ["basic", "assisted"];
family.parameters = [ ...
    makeParameter("mu", "mu", "Shear modulus", "Pa", "kPa", 1e3, 75e3, [1e3, 1e6], true, "fixedParams", ...
        "Shear modulus. First validated mRLFE fitting parameter."), ...
    makeParameter("etaS", "etaS", "Shear viscosity", "Pa*s", "Pa*s", 1, 0.05, [0, 1.0], true, "controls", ...
        "Shear viscosity for the real-k mRLFE viscous branch."), ...
    makeParameter("thickness", "thickness", "Thickness", "m", "mm", 1e-3, 0.50e-3, [0.05e-3, 5e-3], true, "fixedParams", ...
        "Full plate thickness 2h."), ...
    makeParameter("rho", "rho", "Density", "kg/m^3", "kg/m^3", 1, 1070, [500, 2000], false, "fixedParams", ...
        "Mass density. Fixed by default."), ...
    makeParameter("nu", "nu", "Poisson ratio", "", "", 1, 0.4999, [0.0, 0.49999], false, "fixedParams", ...
        "Poisson ratio. Fixed by default."), ...
    makeParameter("fluidDensity", "fluidDensity", "Fluid density", "kg/m^3", "kg/m^3", 1, 1000, [1, 2000], false, "controls", ...
        "Fluid density. Stored in solver options."), ...
    makeParameter("fluidSoundSpeed", "fluidSoundSpeed", "Fluid sound speed", "m/s", "m/s", 1, 1500, [1, 3000], false, "controls", ...
        "Fluid sound speed. Stored in solver options.") ...
    ];
end

function family = makeAEFamily()
family = emptyModelFamily();
family.id = "acoustoelastic_iop_hgo";
family.label = "AE IOP/HGO";
family.description = "Fit experimental dispersion data against the official AE IOP/HGO atlasA0 output.";
family.defaultBranchName = "atlasA0";
family.branchNames = "atlasA0";
family.defaultRobustness = "Fast";
family.defaultExecutionProfile = family.defaultRobustness;
family.surfaceDefaultExecutionProfile = family.defaultExecutionProfile;
family.robustnessPresets = guiExecutionProfileValues();
family.executionProfiles = family.robustnessPresets;
family.supportedExecutionProfiles = family.executionProfiles;
family.profileSupportMode = "fully_supported";
family.defaultMode = "basic";
family.supportedModes = ["basic", "assisted"];
family.parameters = [ ...
    makeParameter("mu", "mu", "Shear modulus", "Pa", "kPa", 1e3, 64e3, [1e3, 300e3], true, "fixedParams", ...
        "Ground-matrix shear modulus for HGO constitutive block."), ...
    makeParameter("IOP", "IOP", "IOP", "Pa", "mmHg", 133.322, 15 * 133.322, [1, 50] * 133.322, true, "fixedParams", ...
        "Intraocular pressure-like load."), ...
    makeParameter("thickness", "thickness", "Thickness", "m", "um", 1e-6, 550e-6, [250e-6, 900e-6], true, "fixedParams", ...
        "Corneal or plate thickness."), ...
    makeParameter("R", "R", "Radius", "m", "mm", 1e-3, 7.8e-3, [4e-3, 12e-3], false, "fixedParams", ...
        "Curvature radius used to compute prestress."), ...
    makeParameter("k1", "k1", "HGO k1", "Pa", "kPa", 1e3, 50e3, [0, 300e3], false, "fixedParams", ...
        "HGO fiber stiffness parameter."), ...
    makeParameter("k2", "k2", "HGO k2", "", "", 1, 200, [0, 500], false, "fixedParams", ...
        "HGO exponential parameter."), ...
    makeParameter("rho", "rho", "Density", "kg/m^3", "kg/m^3", 1, 1060, [500, 2000], false, "fixedParams", ...
        "Solid density."), ...
    makeParameter("rhoF", "rhoF", "Fluid density", "kg/m^3", "kg/m^3", 1, 1000, [1, 2000], false, "fixedParams", ...
        "Lower-fluid density."), ...
    makeParameter("fluidBulkModulus", "fluidBulkModulus", "Fluid bulk modulus", "Pa", "GPa", 1e9, 2.2e9, [0.1e9, 5e9], false, "fixedParams", ...
        "Fluid bulk modulus.") ...
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
family.defaultExecutionProfile = "";
family.surfaceDefaultExecutionProfile = "";
family.robustnessPresets = strings(1, 0);
family.executionProfiles = strings(1, 0);
family.supportedExecutionProfiles = strings(1, 0);
family.profileSupportMode = "";
family.defaultMode = "basic";
family.supportedModes = "basic";
family.parameters = repmat(emptyParameter(), 1, 0);
end

function param = makeParameter(id, fieldName, label, solverUnit, displayUnit, displayScale, defaultValue, bounds, canFit, fixedDestination, helpText)
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
param.fixedDestination = string(fixedDestination);
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
param.fixedDestination = "fixedParams";
param.helpText = "";
end
