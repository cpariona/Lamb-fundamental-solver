function startup()
% Add active Lamb Fundamental Solver folders to the MATLAB path.
%
% Archived examples are intentionally excluded from the default path.
% The models tree contains the primary Rayleigh-Lamb rl* implementation.

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
