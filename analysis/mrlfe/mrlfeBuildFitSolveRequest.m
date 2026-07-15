function request = mrlfeBuildFitSolveRequest(params, frequency_Hz, branchName, solverOptions)
%MRLFEBUILDFITSOLVEREQUEST Map fitting state to the shared public request.

if nargin < 4 || isempty(solverOptions)
    solverOptions = struct();
end
if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 1 || ~isstruct(params)
    error('mrlfe:InvalidFitParameters', 'mRLFE fit parameters must be a struct.');
end

policy = struct('parameterOptions', solverOptions);
request = mrlfeBuildPublicSolveRequest(params, frequency_Hz, branchName, policy);
end
