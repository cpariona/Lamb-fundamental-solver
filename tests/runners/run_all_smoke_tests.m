clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% Run the historical aggregate suite by delegating to focused group runners.
% The current membership mixes contracts and smoke checks with representative
% numerical regression, synthetic fitting, and characterization coverage.
%
% For faster validation after localized changes, run one group directly:
%   run_core_smoke_tests
%   run_gui_smoke_tests
%   run_acoustoelastic_smoke_tests
%   run_mrlfe_smoke_tests
%   run_mrlfe_route_integrity_tests

fprintf('\nRunning complete Lamb Fundamental Solver smoke-test suite...\n');
fprintf('--------------------------------------------------------\n');

fprintf('\n[Group 1/5] Core smoke tests\n');
run_core_smoke_tests;

fprintf('\n[Group 2/5] GUI smoke tests\n');
run_gui_smoke_tests;

fprintf('\n[Group 3/5] Acoustoelastic IOP/HGO smoke tests\n');
run_acoustoelastic_smoke_tests;

fprintf('\n[Group 4/5] mRLFE smoke tests\n');
run_mrlfe_smoke_tests;

fprintf('\n[Group 5/5] mRLFE route-integrity tests\n');
run_mrlfe_route_integrity_tests;

fprintf('\nComplete smoke-test suite passed.\n');
