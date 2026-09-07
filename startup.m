function startup()
%STARTUP Configure maintained Lamb Fundamental Solver folders.

projectRoot = fileparts(mfilename('fullpath'));
configureProjectPath(projectRoot);

fprintf('Lamb Fundamental Solver paths added from:\n%s\n', projectRoot);
end
