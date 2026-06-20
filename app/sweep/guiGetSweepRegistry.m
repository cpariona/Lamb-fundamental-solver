function registry = guiGetSweepRegistry()
%GUIGETSWEEPREGISTRY Return declarative sweep-tool model and parameter metadata.
%
% The SweepTool GUI should use this registry to populate controls and default
% values instead of hardcoding sweep parameters in callback logic. New model
% families can add their own entries while keeping the same request/adapter
% pipeline.

registry = struct();
registry.defaultModelFamily = "mrlfe";
registry.modelFamilies = makeModelFamilies();
end

function modelFamilies = makeModelFamilies()
modelFamilies = repmat(emptyModelFamily(), 1, 1);
modelFamilies(1) = makeMRLFEFamily();
end

function family = makeMRLFEFamily()
family = emptyModelFamily();
family.id = "mrlfe";
family.label = "mRLFE";
family.figureTitle = "mRLFE Parametric Sweep Tool";
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
