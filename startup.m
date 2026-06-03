function startup()
% Add the Lamb Fundamental Solver project folders to the MATLAB path.

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(projectRoot));

fprintf('Lamb Fundamental Solver paths added from:\n%s\n', projectRoot);
end
