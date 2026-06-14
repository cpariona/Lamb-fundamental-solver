function startup()
% Add active Lamb Fundamental Solver folders to the MATLAB path.
%
% Archived examples are intentionally excluded from the default path.
% Rayleigh-Lamb legacy compatibility wrappers under models/rayleigh_lamb/legacy
% are included through the model tree so old function names remain callable.

projectRoot = fileparts(mfilename('fullpath'));

addpath(projectRoot);
addpath(fullfile(projectRoot, 'app'));
addpath(genpath(fullfile(projectRoot, 'models')));
addpath(genpath(fullfile(projectRoot, 'analysis')));
addpath(genpath(fullfile(projectRoot, 'examples', 'acoustoelastic_iop_hgo')));
addpath(genpath(fullfile(projectRoot, 'examples', 'mrlfe')));
addpath(genpath(fullfile(projectRoot, 'examples', 'validation')));
addpath(genpath(fullfile(projectRoot, 'tests')));

fprintf('Lamb Fundamental Solver active paths added from:\n%s\n', projectRoot);
end
