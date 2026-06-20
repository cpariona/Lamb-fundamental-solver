function registry = guiGetSweepRegistry()
%GUIGETSWEEPREGISTRY Return declarative sweep-tool model and parameter metadata.

registry = struct();
registry.defaultModelFamily = "mrlfe";
registry.modelFamilies = makeModelFamilies();
end

function modelFamilies = makeModelFamilies()
modelFamilies = repmat(emptyModelFamily(), 1, 2);
modelFamilies(1) = makeMRLFEFamily();
modelFamilies(2) = makeAEFamily();
end

function family = makeMRLFEFamily()
family = emptyModelFamily();
family.id = "mrlfe";
family.label = "mRLFE";
family.figureTitle = "Parametric Sweep Tool";
family.description = "One-parameter mRLFE real-k sweeps.";
family.defaultParameter = "etaS";
family.defaultModelLabel = "Viscoelastic real-k";
family.defaultBranchName = "A0Like";
family.defaultRobustness = "Fast";
family.modelLabels = ["Viscoelastic real-k", "Elastic real-k"];
family.branchNames = ["A0Like", "S0Like"];
family.robustnessPresets = ["Fast", "Balanced", "Robust"];
family.outputTaskName = "mrlfe_sweep";
family.parameters = [ ...
    makeParameter("etaS", "etaS", [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50], "Pa*s", 1, ...
        "Values use etaS units [Pa*s]. etaS sweeps require the viscoelastic real-k model."), ...
    makeParameter("E", "E", [50, 100, 300, 500, 1000, 1500], "kPa", 1e3, ...
        "Values use Young's modulus units [kPa]. Base etaS remains fixed."), ...
    makeParameter("thickness", "thickness", [0.3, 0.5, 0.7, 1.0], "mm", 1e-3, ...
        "Values use thickness units [mm]. Base etaS remains fixed.") ...
    ];
end

function family = makeAEFamily()
family = emptyModelFamily();
family.id = "ae_iop";
family.label = "AE IOP";
family.figureTitle = "Parametric Sweep Tool";
family.description = "One-parameter AE sweeps.";
family.defaultParameter = "IOP";
family.defaultModelLabel = "AE IOP";
family.defaultBranchName = "atlasA0";
family.defaultRobustness = "Fast";
family.modelLabels = "AE IOP";
family.branchNames = "atlasA0";
family.robustnessPresets = ["Fast", "Balanced"];
family.outputTaskName = "ae_iop_sweep";
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
