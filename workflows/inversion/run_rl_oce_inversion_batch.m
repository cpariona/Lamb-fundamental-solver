function batchResult = run_rl_oce_inversion_batch(plan)
%RUN_RL_OCE_INVERSION_BATCH Review/execute Rayleigh-Lamb inversion cases.
% No band auto-selection or numerical model duplication. PLAN.execute=false
% previews root-relative outputs; true requires approved case configurations.
batchResult=runOceInversionBatch(plan,"RayleighLamb");
end
