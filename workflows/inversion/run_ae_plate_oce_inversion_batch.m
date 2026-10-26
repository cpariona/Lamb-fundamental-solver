function batchResult = run_ae_plate_oce_inversion_batch(plan)
%RUN_AE_PLATE_OCE_INVERSION_BATCH Review/execute Li-type Plate A0 cases.
% Plate retains one explicitly reviewed current scalar thickness per case.
batchResult=runOceInversionBatch(plan,"Plate");
end
