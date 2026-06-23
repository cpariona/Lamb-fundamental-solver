function registry = guiGetSweepRegistry()
%GUIGETSWEEPREGISTRY Return declarative sweep-tool model and parameter metadata.

registry = struct();
registry.defaultModelFamily = "mrlfe";
registry.modelFamilies = makeModelFamilies();
end

function modelFamilies = makeModelFamilies()
modelFamilies = repmat(emptyModelFamily(), 1, 3);
modelFamilies(1) = makeMRLFEFamily();
modelFamilies(2) = makeRLFamily();
modelFamilies(3) = makeAEFamily();
end

function family = makeMRLFEFamily()
family = emptyModelFamily();
family.id = "mrlfe";
family.label = "mRLFE";
family.figureTitle = "Parametric Sweep Tool";
family.description = "One-parameter mRLFE real-k sweeps. etaS = 0 is the elastic limit; etaS > 0 is the viscous case.";
family.defaultParameter = "etaS";
family.defaultModelLabel = "mRLFE real-k";
family.defaultBranchName = "A0Like";
family.defaultRobustness = "Fast";
family.modelLabels = "mRLFE real-k";
family.branchNames = ["A0Like", "S0Like"];
family.robustnessPresets = ["Fast", "Balanced", "Robust"];
family.outputTaskName = "mrlfe_sweep";
family.parameters = [ ...
    makeParameter("etaS", "etaS", [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50], "Pa*s", 1, ...
        "Values use etaS units [Pa*s]. etaS = 0 gives the elastic limit of the same model."), ...
    makeParameter("mu", "mu", [60, 65, 70, 75, 80], "kPa", 1e3, ...
        "Values use shear modulus units [kPa]. Poisson ratio remains fixed in the base request."), ...
    makeParameter("thickness", "thickness", [0.3, 0.4, 0.5, 0.6, 0.7], "mm", 1e-3, ...
        "Values use full-thickness 2h units [mm]. Base etaS remains fixed.") ...
    ];
end

function family = makeRLFamily()
family = emptyModelFamily();
family.id = "rayleigh_lamb";
family.label = "Rayleigh-Lamb";
family.figureTitle = "Parametric Sweep Tool";
family.description = "One-parameter Rayleigh-Lamb A0/S0 sweeps.";
family.defaultParameter = "thickness";
family.defaultModelLabel = "Rayleigh-Lamb";
family.defaultBranchName = "A0";
family.defaultRobustness = "Balanced";
family.modelLabels = "Rayleigh-Lamb";
family.branchNames = ["A0", "S0"];
family.robustnessPresets = ["Fast", "Balanced", "Robust"];
family.outputTaskName = "rayleigh_lamb_sweep";
family.parameters = [ ...
    makeParameter("thickness", "thickness", [0.3, 0.4, 0.5, 0.6, 0.7], "mm", 1e-3, ...
        "Values use full-thickness 2h units [mm]."), ...
    makeParameter("mu", "mu", [60, 65, 70, 75, 80], "kPa", 1e3, ...
        "Values use shear modulus units [kPa]. Poisson ratio remains fixed in the base request.") ...
    ];
end

function family = makeAEFamily()
family = emptyModelFamily();
family.id = "ae_iop_hgo";
family.label = "AE IOP/HGO";
family.figureTitle = "Parametric Sweep Tool";
family.description = "One-parameter AE IOP/HGO sweeps.";
family.defaultParameter = "IOP";
family.defaultModelLabel = "AE IOP/HGO";
family.defaultBranchName = "atlasA0";
family.defaultRobustness = "Fast";
family.modelLabels = "AE IOP/HGO";
family.branchNames = "atlasA0";
family.robustnessPresets = ["Fast", "Balanced"];
family.outputTaskName = "ae_iop_hgo_sweep";
family.parameters = [ ...
    makeParameter("IOP", "IOP", [5, 10, 15, 20, 25], "mmHg", 133.322, ...
        "Values use IOP units [mmHg]. The adapter converts to Pa."), ...
    makeParameter("mu", "mu", [25, 50, 75, 100], "kPa", 1e3, ...
        "Values use shear modulus units [kPa]. Other parameters remain fixed.") ...
    ];
end

function family = emptyModelFamily()
family = struct();
family.id = "";
family.label = "";
family.figureTitle = "Parametric Sweep Tool";
family.description = "";
family.defaultParameter = "";
family.defaultModelLabel = "";
family.defaultBranchName = "";
family.defaultRobustness = "";
family.modelLabels = strings(1, 0);
family.branchNames = strings(1, 0);
family.robustnessPresets = strings(1, 0);
family.outputTaskName = "sweep";
family.parameters = repmat(emptyParameter(), 1, 0);
end

function param = makeParameter(id, label, defaultValues, displayUnit, displayScale, helpText)
param = emptyParameter();
param.id = string(id);
param.label = string(label);
param.defaultValuesDisplay = defaultValues(:).';
param.displayUnit = string(displayUnit);
param.displayScale = displayScale;
param.helpText = string(helpText);
end

function param = emptyParameter()
param = struct();
param.id = "";
param.label = "";
param.defaultValuesDisplay = [];
param.displayUnit = "";
param.displayScale = 1;
param.helpText = "";
end
