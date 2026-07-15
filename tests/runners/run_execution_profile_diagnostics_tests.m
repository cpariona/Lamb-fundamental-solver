clear; clc;
startup

fprintf('\nRunning execution profile diagnostics tests...\n');
fprintf('---------------------------------------------\n');

% The obsolete mapped-to-Fast benchmark remains manual and deferred until
% its contract is redesigned around distinct public presets.
test_execution_profile_diagnostics_format;

fprintf('\nExecution profile diagnostics tests passed.\n');
