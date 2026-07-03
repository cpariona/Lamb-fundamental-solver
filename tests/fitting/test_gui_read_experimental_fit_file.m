function tests = test_gui_read_experimental_fit_file
tests = functiontests(localfunctions);
end

function testReadCsv(testCase)
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@()rmdir(folder, 's')); %#ok<NASGU>
filePath = fullfile(folder, 'dispersion.csv');
T = table([1;2;3], [10;11;12], [1;0;1], ...
    'VariableNames', {'frequency_kHz','Cp_mps','Use'});
writetable(T, filePath);

imported = guiReadExperimentalFitFile(string(filePath));
verifyEqual(testCase, imported.numRows, 3);
verifyEqual(testCase, imported.numColumns, 3);
verifyEqual(testCase, imported.columnNames, ["frequency_kHz","Cp_mps","Use"]);
verifyEqual(testCase, imported.numericData, [1 10 1; 2 11 0; 3 12 1]);
end

function testReadMatStruct(testCase)
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@()rmdir(folder, 's')); %#ok<NASGU>
filePath = fullfile(folder, 'dispersion.mat');
experimental = struct('frequency_Hz', [1000;2000], 'Cp_mps', [8;9], 'validMask', [1;1]); %#ok<NASGU>
save(filePath, 'experimental');

imported = guiReadExperimentalFitFile(string(filePath));
verifyEqual(testCase, imported.sourceVariable, "experimental");
verifyEqual(testCase, imported.numRows, 2);
verifyGreaterThanOrEqual(testCase, imported.numColumns, 2);
verifyTrue(testCase, any(imported.columnNames == "frequency_Hz"));
verifyTrue(testCase, any(imported.columnNames == "Cp_mps"));
end

function testRejectUnsupportedExtension(testCase)
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@()rmdir(folder, 's')); %#ok<NASGU>
filePath = fullfile(folder, 'dispersion.bin');
fid = fopen(filePath, 'w');
fwrite(fid, uint8([1 2 3]));
fclose(fid);
verifyError(testCase, @()guiReadExperimentalFitFile(string(filePath)), ...
    'FitDataImport:UnsupportedExtension');
end
