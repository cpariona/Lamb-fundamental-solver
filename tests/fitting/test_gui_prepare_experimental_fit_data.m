function tests = test_gui_prepare_experimental_fit_data
tests = functiontests(localfunctions);
end

function testSortConvertFilterAndCollapse(testCase)
imported = struct();
imported.numericData = [5, 12, 1; 1, 8, 1; 3, 10, 0; 3, 14, 1; nan, 9, 1; -1, 7, 1];
imported.columnNames = ["frequency_kHz", "Cp_mps", "Use"];
imported.fileName = "sample.csv";
imported.filePath = "sample.csv";
imported.sourceVariable = "";

prepared = guiPrepareExperimentalFitData(imported, ...
    'FrequencyColumn', 1, 'PhaseSpeedColumn', 2, 'UseColumn', 3, ...
    'FrequencyUnit', "kHz", 'DuplicatePolicy', "mean");

verifyEqual(testCase, prepared.frequency_Hz, [1000; 3000; 5000]);
verifyEqual(testCase, prepared.Cp_mps, [8; 12; 12], 'AbsTol', 1e-12);
verifyEqual(testCase, prepared.validMask, [true; true; true]);
verifyEqual(testCase, prepared.metadata.removedInvalidRows, 2);
verifyEqual(testCase, prepared.metadata.duplicateRowsCollapsed, 1);
verifyEqual(testCase, prepared.metadata.sourceType, "experimental_file");
end

function testRejectSameColumns(testCase)
imported = struct('numericData', [1 2; 2 3], 'columnNames', ["f", "Cp"]);
verifyError(testCase, @()guiPrepareExperimentalFitData(imported, ...
    'FrequencyColumn', 1, 'PhaseSpeedColumn', 1), ...
    'FitDataImport:DuplicateColumnRole');
end

function testRejectInsufficientValidRows(testCase)
imported = struct('numericData', [nan 2; -1 3], 'columnNames', ["f", "Cp"]);
verifyError(testCase, @()guiPrepareExperimentalFitData(imported), ...
    'FitDataImport:InsufficientValidRows');
end

function testDuplicateErrorPolicy(testCase)
imported = struct('numericData', [1 2; 1 3; 2 4], 'columnNames', ["f", "Cp"]);
verifyError(testCase, @()guiPrepareExperimentalFitData(imported, 'DuplicatePolicy', "error"), ...
    'FitDataImport:DuplicateFrequency');
end
