function test_main_gui_export_contract()
%TEST_MAIN_GUI_EXPORT_CONTRACT Validate compact normalized Main GUI exports.

fprintf('Running Main GUI export contract test...\n');
frequency = [1000; 2000; 3000];

%% Rayleigh-Lamb
rlResult = struct();
rlResult.branches = [ ...
    makeBranch("RayleighLamb", "A0", frequency, [4.1; 4.8; 5.4], [true; true; true]); ...
    makeBranch("RayleighLamb", "S0", frequency, [18.0; 18.4; 18.9], [true; true; true])];
rlParameters = struct('modelType', "ShearPoisson", 'rho_kg_m3', 1000, ...
    'mu_Pa', 50000, 'nu', 0.49, 'thickness_m', 5e-4);
assertExportContract(guiBuildMainResultExport(rlResult, rlParameters), 2, rlParameters);

%% mRLFE
mrlfeResult = struct();
mrlfeResult.branches = makeBranch("mRLFERealK", "A0Like", frequency, ...
    [3.9; NaN; 5.0], [true; false; true]);
mrlfeParameters = struct('modelType', "ShearPoisson", 'rho_kg_m3', 1000, ...
    'mu_Pa', 50000, 'nu', 0.49, 'thickness_m', 5e-4, ...
    'fluidDensity_kg_m3', 1000, 'fluidSoundSpeed_m_s', 1500, 'etaS_Pa_s', 0.05);
mrlfeExport = guiBuildMainResultExport(mrlfeResult, mrlfeParameters);
assertExportContract(mrlfeExport, 1, mrlfeParameters);
assert(isequal(mrlfeExport.curves.data.Valid, [true; false; true]), ...
    'Exported validity must preserve normalized branch validity.');

%% AE IOP/HGO
aeResult = struct();
aeResult.branches = makeBranch("AcoustoelasticIOPHGO", "atlasA0", frequency, ...
    [5.2; 5.8; 6.4], [true; true; true]);
aeParameters = struct('modelType', "ShearPoisson", 'rho_kg_m3', 1050, ...
    'mu_Pa', 80000, 'nu', 0.49, 'thickness_m', 5.5e-4, ...
    'IOP_mmHg', 15, 'radius_mm', 7.8, 'k1_Pa', 25000, 'k2', 100, ...
    'fluidDensity_kg_m3', 1000, 'fluidBulkModulus_Pa', 2.2e9);
aeExport = guiBuildMainResultExport(aeResult, aeParameters);
assertExportContract(aeExport, 1, aeParameters);

%% Save contract
filePath = [tempname, '.mat'];
cleanup = onCleanup(@()deleteIfPresent(filePath)); %#ok<NASGU>
savedPath = guiSaveMainResultExport(filePath, aeExport);
assert(strcmp(savedPath, filePath), 'Save helper must return the resolved MAT-file path.');
saved = load(filePath);
assert(isequal(fieldnames(saved), {'LambExport'}), ...
    'The MAT-file must contain only the public LambExport variable.');
assert(isequal(saved.LambExport.parameters, aeParameters), ...
    'Saved physical parameters must match the captured GUI parameters.');

fprintf('Main GUI export contract test passed.\n');
end

function branch = makeBranch(modelName, branchName, frequency, phaseVelocity, valid)
branch = struct();
branch.modelName = modelName;
branch.rawModelName = modelName;
branch.branchName = branchName;
branch.frequency = frequency(:);
branch.phaseVelocity = phaseVelocity(:);
branch.wavenumber = [];
branch.kThickness = [];
branch.metadata = struct('rawResult', struct('mustNotBeExported', true));
branch.diagnostics = struct('valid', logical(valid(:)), 'objective', ones(size(frequency(:))));
end

function assertExportContract(exportData, expectedCurveCount, expectedParameters)
assert(isstruct(exportData), 'Export payload must be a struct.');
assert(isequal(sort(fieldnames(exportData)), {'curves'; 'parameters'}), ...
    'Export payload must contain only curves and physical parameters.');
assert(numel(exportData.curves) == expectedCurveCount, ...
    'Unexpected number of exported GUI-visible curves.');
assert(isequal(exportData.parameters, expectedParameters), ...
    'Exported parameters must match the captured physical GUI inputs.');
for i = 1:numel(exportData.curves)
    curve = exportData.curves(i);
    assert(isequal(sort(fieldnames(curve)), {'branch'; 'data'; 'model'}), ...
        'Each curve must contain only model, branch, and data.');
    assert(istable(curve.data), 'Each exported curve must use a table.');
    assert(isequal(curve.data.Properties.VariableNames, ...
        {'Frequency_Hz', 'PhaseVelocity_mps', 'Valid'}), ...
        'Exported curve tables must remain limited to frequency and phase velocity.');
    assert(~isfield(curve, 'metadata') && ~isfield(curve, 'rawResult'), ...
        'Model internals must not leak into the export payload.');
end
end

function deleteIfPresent(filePath)
if isfile(filePath)
    delete(filePath);
end
end
