clear; clc;
startup

% Run all maintained smoke and consistency tests.
%
% This script is intended as the first validation step after refactors,
% folder reorganizations, or path changes. It should remain lightweight and
% avoid generating figures.

fprintf('\nRunning Lamb Fundamental Solver smoke tests...\n');
fprintf('---------------------------------------------\n');

fprintf('\nChecking maintained acoustoelastic IOP/HGO wrappers and entrypoints...\n');
assert(~isempty(which('solveAcoustoelasticIOPHGOBranch')), ...
    'Missing solveAcoustoelasticIOPHGOBranch on MATLAB path.');
assert(~isempty(which('defaultAcoustoelasticIOPHGOOptions')), ...
    'Missing defaultAcoustoelasticIOPHGOOptions on MATLAB path.');
assert(~isempty(which('run_acoustoelastic_iop_hgo_atlas_branch')), ...
    'Missing run_acoustoelastic_iop_hgo_atlas_branch on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_branch_policy')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_branch_policy on MATLAB path.');
assert(~isempty(which('test_acoustoelastic_iop_hgo_constitutive_identity')), ...
    'Missing test_acoustoelastic_iop_hgo_constitutive_identity on MATLAB path.');
assert(~isempty(which('test_acoustoelastic_iop_hgo_strictA0_smoke')), ...
    'Missing test_acoustoelastic_iop_hgo_strictA0_smoke on MATLAB path.');

fprintf('\n[1/3] Acoustoelastic IOP/HGO constitutive identity test\n');
test_acoustoelastic_iop_hgo_constitutive_identity;

fprintf('\n[2/3] Acoustoelastic IOP/HGO strict-A0 atlas branch smoke test\n');
test_acoustoelastic_iop_hgo_strictA0_smoke;

fprintf('\n[3/3] mRLFE smoke test\n');
test_mrlfe_smoke;

fprintf('\nAll maintained smoke tests passed.\n');
