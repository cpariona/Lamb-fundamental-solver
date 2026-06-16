clear; clc; close all;

%DIAGNOSE_IDENTITYA0_PLAUSIBILITY Short MATLAB-compatible entrypoint.
%
% MATLAB's run() also resolves the script by file stem, so directly running a
% file whose name exceeds namelengthmax still fails. This wrapper copies the
% long descriptive script to a short temporary filename and runs that copy.

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
longScript = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_identityA0_physical_plausibility.m');
shortScript = fullfile(tempdir, 'identityA0_plaus_impl.m');

if ~exist(longScript, 'file')
    error('Expected diagnostic script not found: %s', longScript);
end

copyfile(longScript, shortScript, 'f');
run(shortScript);
