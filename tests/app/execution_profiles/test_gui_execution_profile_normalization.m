clear; clc;
startup

fprintf('\nRunning execution profile normalization tests...\n');
fprintf('-----------------------------------------------\n');

%% Direct char/string input and case canonicalization.
[profile, metadata] = guiNormalizeExecutionProfile('fast');
assert(profile == "Fast", 'char input should canonicalize to Fast.');
assert(metadata.requestedExecutionProfile == "Fast", 'metadata must record requested profile.');
assert(metadata.effectiveExecutionProfile == "Fast", 'metadata must record effective profile.');

[profile, ~] = guiNormalizeExecutionProfile("BALANCED");
assert(profile == "Balanced", 'string input should canonicalize case-insensitively.');

[profile, ~] = guiNormalizeExecutionProfile("robust");
assert(profile == "Robust", 'robust input should canonicalize to Robust.');

%% Struct alias resolution.
[profile, metadata] = guiNormalizeExecutionProfile(struct('executionProfile', "Fast"));
assert(profile == "Fast", 'executionProfile field should be canonical.');
assert(metadata.executionProfileSource == "executionProfile", 'source should identify executionProfile.');
assert(metadata.legacyRobustnessAliasUsed == false, 'executionProfile alone should not mark legacy alias.');

[profile, metadata] = guiNormalizeExecutionProfile(struct('robustness', "balanced"));
assert(profile == "Balanced", 'robustness alias should canonicalize.');
assert(metadata.executionProfileSource == "robustness", 'source should identify robustness alias.');
assert(metadata.legacyRobustnessAliasUsed == true, 'robustness should mark legacy alias.');

[profile, metadata] = guiNormalizeExecutionProfile(struct('executionProfile', "Robust", 'robustness', "robust"));
assert(profile == "Robust", 'matching executionProfile and robustness should pass.');
assert(metadata.executionProfileSource == "executionProfile+robustness", ...
    'matching aliases should record combined source.');

[profile, metadata] = guiNormalizeExecutionProfile(struct(), ...
    'DefaultProfile', "Fast", 'DefaultSource', "FitTool default");
assert(profile == "Fast", 'empty struct should use supplied default.');
assert(metadata.executionProfileSource == "FitTool default", 'default source should be preserved.');

%% Invalid and contradictory inputs fail clearly.
assertThrows(@()guiNormalizeExecutionProfile("dense"), 'guiNormalizeExecutionProfile:InvalidProfile');
assertThrows(@()guiNormalizeExecutionProfile(struct('executionProfile', "Fast", 'robustness', "Robust")), ...
    'guiNormalizeExecutionProfile:ConflictingProfiles');

fprintf('Execution profile normalization tests passed.\n');

function assertThrows(fcn, expectedId)
threw = false;
try
    fcn();
catch ME
    threw = true;
    assert(strcmp(ME.identifier, expectedId), ...
        'Expected error id %s, got %s.', expectedId, ME.identifier);
end
assert(threw, 'Expected function to throw %s.', expectedId);
end
