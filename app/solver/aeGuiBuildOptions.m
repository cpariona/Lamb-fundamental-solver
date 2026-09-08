function aeOptions = aeGuiBuildOptions(executionProfile)
%AEGUIBUILDOPTIONS Build AE options for the solver GUI.
[aeOptions, profileMetadata] = aeResolveExecutionProfile(executionProfile, ...
    'DefaultProfile', "Balanced", ...
    'DefaultSource', "Solver GUI default");
aeOptions.executionProfileMetadata = profileMetadata;
end
