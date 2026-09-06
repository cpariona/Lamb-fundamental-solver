function test_ae_configuration_characterization()
production = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
assert(production.atlasNumYPoints == 1000);
assert(production.atlasTopNMinima == 18);
assert(production.refineLocalMinima == true);
assert(production.atlasInitializationMinFrequency_Hz == 300);
assert(production.atlasInitializationNumFrequencyPoints == 50);
assert(production.atlasBranchPolicy == "atlasA0");
for diagnosticField = ["trackingMethod", "numCpScanPoints", ...
        "complexCMaxIter", "usePhysicalCpWindow"]
    assert(~isfield(production, diagnosticField), ...
        'Public production defaults must not expose %s.', diagnosticField);
end
diagnostic = lamb.models.acoustoelastic_iop_hgo.configuration.aeDefaultDiagnosticOptions();
assert(diagnostic.numCpScanPoints == 1400);
assert(diagnostic.maxLocalCandidates == 12);
assert(diagnostic.trackingMethod == "globalScan");

profileNames = ["Fast", "Balanced", "Robust"];
expectedY = [300, 600, 900];
expectedTopN = [12, 16, 20];
for i = 1:numel(profileNames)
    physicalSweep = aeDefaultSweepOptions(profileNames(i));
    assert(physicalSweep.atlasNumYPoints == expectedY(i));
    assert(physicalSweep.atlasTopNMinima == expectedTopN(i));
    assert(physicalSweep.M54_variant == "corrected");
    assert(physicalSweep.normalizeRows == false);
    assert(physicalSweep.atlasBranchPolicy == "atlasA0");

    [surfaceOptions, metadata] = aeResolveExecutionProfile(profileNames(i));
    assert(surfaceOptions.atlasNumYPoints == expectedY(i));
    assert(surfaceOptions.atlasTopNMinima == expectedTopN(i));
    assert(metadata.requestedExecutionProfile == profileNames(i));
    assert(metadata.effectiveExecutionProfile == profileNames(i));
    assert(metadata.atlasNumYPoints == expectedY(i));
    assert(metadata.atlasTopNMinima == expectedTopN(i));
    assert(metadata.internalAtlasPreset == ...
        "ae_atlas_" + string(expectedY(i)) + "x" + string(expectedTopN(i)));
end

% Main GUI currently passes a complete profile configuration to its model
% adapter. These values therefore have explicit-override precedence over the
% separately maintained interactive bundle.
mainGui = guiBuildAcoustoelasticIOPHGOOptions("Balanced");
assert(mainGui.atlasNumYPoints == 600);
assert(mainGui.atlasTopNMinima == 16);
assert(mainGui.refineLocalMinima == true);
assert(mainGui.atlasInitializationNumFrequencyPoints == 50);
assert(mainGui.executionProfileMetadata.surfaceDefaultExecutionProfile == "Balanced");

% SweepTool and FitTool both begin with the Fast profile. Their adapters may
% subsequently apply explicit visible controls, which must remain higher
% precedence than this profile selection.
[sweepTool, sweepMetadata] = aeResolveExecutionProfile(struct('executionProfile', "Fast"), ...
    'DefaultProfile', "Fast", 'DefaultSource', "SweepTool default");
[fitTool, fitMetadata] = aeResolveExecutionProfile(struct('robustness', "Fast"), ...
    'DefaultProfile', "Fast", 'DefaultSource', "FitTool default");
assert(sweepTool.atlasNumYPoints == 300 && sweepTool.atlasTopNMinima == 12);
assert(fitTool.atlasNumYPoints == 300 && fitTool.atlasTopNMinima == 12);
assert(sweepMetadata.surfaceDefaultExecutionProfile == "Fast");
assert(fitMetadata.surfaceDefaultExecutionProfile == "Fast");

explicit = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions( ...
    'atlasNumYPoints', 321, ...
    'atlasTopNMinima', 7, ...
    'atlasBranchPolicy', "ATLASA0");
assert(explicit.atlasNumYPoints == 321);
assert(explicit.atlasTopNMinima == 7);
assert(explicit.atlasBranchPolicy == "atlasA0");

missingParams = struct('IOP', 1);
didReject = false;
try
    lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(missingParams, production);
catch ME
    didReject = contains(ME.message, ...
        'Missing required acoustoelastic IOP/HGO atlas parameter: R');
end
assert(didReject, 'The maintained solver must reject a request missing R.');

fprintf('test_ae_configuration_characterization passed.\n');
end
