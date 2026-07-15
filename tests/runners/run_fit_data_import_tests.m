function results = run_fit_data_import_tests
%RUN_FIT_DATA_IMPORT_TESTS Run maintained FitTool experimental-data import tests.

root = fileparts(fileparts(mfilename('fullpath')));
testFiles = [
    string(fullfile(root, 'app', 'fitting', 'test_gui_read_experimental_fit_file.m'))
    string(fullfile(root, 'app', 'fitting', 'test_gui_prepare_experimental_fit_data.m'))
];

results = runtests(cellstr(testFiles));
disp(table(results));
assertSuccess(results);
end
