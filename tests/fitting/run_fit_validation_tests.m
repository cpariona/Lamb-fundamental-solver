clear; clc;
startup

%RUN_FIT_VALIDATION_TESTS Run focused synthetic fitting validation tests.
%
% This suite is intentionally separate from run_all_smoke_tests because it
% evaluates fitting quality and may take longer than path/API smoke tests.

fprintf('\nRunning focused fitting validation suite...\n');
fprintf('==========================================\n');

fprintf('\n[Fit validation 1/3] Rayleigh-Lamb validation\n');
test_fit_validation_rayleigh_lamb;

fprintf('\n[Fit validation 2/3] mRLFE validation\n');
test_fit_validation_mrlfe;

fprintf('\n[Fit validation 3/3] AE IOP/HGO validation\n');
test_fit_validation_ae_iop_hgo;

summary = struct();
if evalin('base', 'exist(''RayleighLambFitValidationSummary'', ''var'')')
    summary.RayleighLamb = evalin('base', 'RayleighLambFitValidationSummary');
end
if evalin('base', 'exist(''MRLFEFitValidationSummary'', ''var'')')
    summary.MRLFE = evalin('base', 'MRLFEFitValidationSummary');
end
if evalin('base', 'exist(''AEIOPHGOFitValidationSummary'', ''var'')')
    summary.AEIOPHGO = evalin('base', 'AEIOPHGOFitValidationSummary');
end
assignin('base', 'FitValidationSummary', summary);

fprintf('\nFocused fitting validation suite passed.\n');
fprintf('Summary tables are available in the MATLAB base workspace as FitValidationSummary.\n');
