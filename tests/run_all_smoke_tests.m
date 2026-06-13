clear; clc;
startup

% Run all maintained smoke and consistency tests.
%
% This script is intended as the first validation step after refactors,
% folder reorganizations, or path changes. It should remain lightweight and
% avoid generating figures.

fprintf('\nRunning Lamb Fundamental Solver smoke tests...\n');
fprintf('---------------------------------------------\n');

fprintf('\n[1/3] Li 2024 constitutive identity test\n');
test_li2024_constitutive_identity;

fprintf('\n[2/3] Li 2024 strict-A0 atlas branch smoke test\n');
test_li2024_strictA0_smoke;

fprintf('\n[3/3] mRLFE smoke test\n');
test_mrlfe_smoke;

fprintf('\nAll maintained smoke tests passed.\n');
