clear; clc;
startup

%RUN_FIT_VALIDATION_TESTS Run focused synthetic fitting validation tests.
%
% This suite is intentionally separate from run_all_smoke_tests because it
% evaluates fitting quality and may take longer than path/API smoke tests.

fprintf('\nRunning focused fitting validation suite...\n');
fprintf('==========================================\n');

fprintf('\n[Fit validation 1/8] Rayleigh-Lamb validation\n');
test_fit_validation_rayleigh_lamb;

fprintf('\n[Fit validation 2/8] mRLFE baseline validation\n');
test_fit_validation_mrlfe;

fprintf('\n[Fit validation 3/8] mRLFE hidden-parameter validation\n');
test_fit_validation_mrlfe_hidden_params;

fprintf('\n[Fit validation 4/8] AE IOP/HGO baseline validation\n');
test_fit_validation_ae_iop_hgo;

fprintf('\n[Fit validation 5/8] AE IOP/HGO hidden-parameter validation\n');
test_fit_validation_ae_iop_hgo_hidden_params;

fprintf('\n[Fit validation 6/8] Physical QC flat RL A0 warning test\n');
test_fit_physical_qc_flat_rl;

fprintf('\n[Fit validation 7/8] Physical QC synthetic pass test\n');
test_fit_physical_qc_synthetic_pass;

fprintf('\n[Fit validation 8/8] RL prediction fallback rejection test\n');
test_rl_fit_rejects_prediction_fallback;

summary = struct();
if evalin('base', 'exist(''RayleighLambFitValidationSummary'', ''var'')')
    summary.RayleighLamb = evalin('base', 'RayleighLambFitValidationSummary');
end
if evalin('base', 'exist(''MRLFEFitValidationSummary'', ''var'')')
    summary.MRLFE = evalin('base', 'MRLFEFitValidationSummary');
end
if evalin('base', 'exist(''MRLFEHiddenParamFitValidationSummary'', ''var'')')
    summary.MRLFEHiddenParams = evalin('base', 'MRLFEHiddenParamFitValidationSummary');
end
if evalin('base', 'exist(''AEIOPHGOFitValidationSummary'', ''var'')')
    summary.AEIOPHGO = evalin('base', 'AEIOPHGOFitValidationSummary');
end
if evalin('base', 'exist(''AEIOPHGOHiddenParamFitValidationSummary'', ''var'')')
    summary.AEIOPHGOHiddenParams = evalin('base', 'AEIOPHGOHiddenParamFitValidationSummary');
end
assignin('base', 'FitValidationSummary', summary);

fprintf('\nFocused fitting validation suite passed.\n');
fprintf('Summary tables are available in the MATLAB base workspace as FitValidationSummary.\n');
