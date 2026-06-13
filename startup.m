function startup()
% Add active Lamb Fundamental Solver folders to the MATLAB path.
%
% Archived examples and legacy material are intentionally excluded from the
% default path so that routine use only sees the current backend, GUI, tests,
% and maintained examples.

projectRoot = fileparts(mfilename('fullpath'));

addpath(projectRoot);
addpath(fullfile(projectRoot, 'app'));
addpath(fullfile(projectRoot, 'core'));
addpath(fullfile(projectRoot, 'equations'));
addpath(fullfile(projectRoot, 'approximations'));
addpath(fullfile(projectRoot, 'tracking'));
addpath(genpath(fullfile(projectRoot, 'models')));
addpath(genpath(fullfile(projectRoot, 'analysis')));
addpath(genpath(fullfile(projectRoot, 'examples', 'li2024')));
addpath(genpath(fullfile(projectRoot, 'examples', 'mrlfe')));
addpath(genpath(fullfile(projectRoot, 'examples', 'validation')));
addpath(genpath(fullfile(projectRoot, 'tests')));

fprintf('Lamb Fundamental Solver active paths added from:\n%s\n', projectRoot);
end
