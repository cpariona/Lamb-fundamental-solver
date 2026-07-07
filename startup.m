function startup()
%STARTUP Configure active Lamb Fundamental Solver folders.

projectRoot = fileparts(mfilename('fullpath'));
configureProjectPath(projectRoot);

fprintf('Lamb Fundamental Solver active paths added from:\n%s\n', projectRoot);
end