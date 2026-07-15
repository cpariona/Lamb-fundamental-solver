function request = mrlfeBuildGuiSolveRequest(params, frequency_Hz, branchName, guiOptions)
%MRLFEBUILDGUISOLVEREQUEST Map Main GUI state to the shared public request.

if nargin < 4 || isempty(guiOptions)
    guiOptions = struct();
end
if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 1 || ~isstruct(params)
    error('mrlfe:InvalidGuiParameters', 'mRLFE GUI params must be a struct.');
end

policy = struct('parameterOptions', guiOptions);
request = mrlfeBuildPublicSolveRequest(params, frequency_Hz, branchName, policy);
end
