clear; clc;
startup

%RUN_FIT_VALIDATION_TESTS Run focused synthetic fitting validation tests.
%
% This suite is intentionally separate from run_all_smoke_tests because it
% evaluates fitting quality and may take longer than path/API smoke tests.

fprintf('\nRunning focused fitting validation suite...\n');
fprintf('==========================================\n');

fprintf('\n[Fit validation 1/5] Rayleigh-Lamb validation\n');
test_fit_validation_rayleigh_lamb;

fprintf('\n[Fit validation 2/5] mRLFE baseline validation\n');
test_fit_validation_mrlfe;

fprintf('\n[Fit validation 3/5] mRLFE hidden-parameter validation\n');
test_fit_validation_mrlfe_hidden_params;

fprintf('\n[Fit validation 4/5] AE IOP/HGO baseline validation\n');
test_fit_validation_ae_iop_hgo;

fprintf('\n[Fit validation 5/5] AE IOP/HGO hidden-parameter validation\n');
test_fit_validation_ae_iop_hgo_hidden_params;

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
