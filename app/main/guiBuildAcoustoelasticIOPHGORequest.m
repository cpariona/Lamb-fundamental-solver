function guiRequest = guiBuildAcoustoelasticIOPHGORequest(baseParams, aeControls, robustness)
aeParams = struct();
aeParams.R = aeControls.R.Value * 1e-3;
aeParams.thickness = baseParams.thickness;
aeParams.IOP = aeControls.IOP.Value * 133.322;
aeParams.mu = baseParams.mu;
aeParams.k1 = aeControls.k1.Value * 1e3;
aeParams.k2 = aeControls.k2.Value;
aeParams.rho = baseParams.rho;
aeParams.rhoF = aeControls.rhoF.Value;
aeParams.fluidBulkModulus = aeControls.fluidBulkModulus.Value * 1e9;
aeParams.frequency = buildFrequencyVector(baseParams);

guiRequest = struct();
guiRequest.params = aeParams;
guiRequest.options = guiBuildAcoustoelasticIOPHGOOptions(robustness);
end
