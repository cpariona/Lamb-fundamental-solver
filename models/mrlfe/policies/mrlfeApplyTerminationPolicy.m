function branchOut = mrlfeApplyTerminationPolicy(branchIn, seed, configuration)
%MRLFEAPPLYTERMINATIONPOLICY Apply the requested mRLFE branch termination policy.

policy = string(configuration.terminationPolicy);
branchOut = branchIn;
branchOut.terminationPolicy = policy;

switch policy
    case "physicalTail"
        if configuration.branch == "A0Like"
            branchOut = mrlfeEvaluatePhysicalTail(branchOut, seed.Cp, seed.frequency, ...
                makePhysicalTailOptions(configuration.internalOptions));
        end
    case "none"
        return;
    case "continuity"
        return;
    otherwise
        error('mrlfe:InvalidTerminationPolicy', ...
            'Unsupported mRLFE termination policy "%s".', policy);
end
end

function options = makePhysicalTailOptions(internalOptions)
options = struct();
options.minRatioToGuide = getOption(internalOptions, 'mrlfeA0PhysicalMinRatioToGuide', 0.70);
options.maxRatioToGuide = getOption(internalOptions, 'mrlfeA0PhysicalMaxRatioToGuide', inf);
options.minFrequencyHz = getOption(internalOptions, 'mrlfeA0PhysicalMinFrequencyHz', 1000);
options.minValidRunBeforeCut = getOption(internalOptions, 'mrlfeA0PhysicalMinValidRunBeforeCut', 8);
options.maxLocalDropRelative = getOption(internalOptions, 'mrlfeA0PhysicalMaxLocalDropRelative', 0.05);
options.maxTwoStepDropRelative = getOption(internalOptions, 'mrlfeA0PhysicalMaxTwoStepDropRelative', 0.10);
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
