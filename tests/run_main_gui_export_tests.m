clear; clc;
startup

fprintf('\nRunning Main GUI export tests...\n');
fprintf('--------------------------------\n');

assert(~isempty(which('guiBuildMainResultExport')), ...
    'Missing GUI export builder on the MATLAB path.');
assert(~isempty(which('guiSaveMainResultExport')), ...
    'Missing GUI export save helper on the MATLAB path.');

test_main_gui_export_contract;

fprintf('\nMain GUI export tests passed.\n');