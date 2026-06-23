function [branches, modelName] = mrlfeSelectRealKBranches(results, etaS)
%MRLFESELECTREALKBRANCHES Select the maintained mRLFE real-k branch container.
%
% The maintained real-k convention is:
%
%   etaS = 0  -> elastic real-k limit
%   etaS > 0 -> viscoelastic real-k case
%
% For etaS > 0, prefer the physical viscoelastic raw model when available.
% For etaS = 0, diagnostics must not require mRLFEViscoRealK; they should use
% the unified or elastic real-k result instead.

arguments
    results (1,1) struct
    etaS (1,1) double {mustBeFinite, mustBeNonnegative}
end

if ~isfield(results, 'models')
    error('results.models is missing.');
end

if etaS > 0 && isfield(results.models, 'mRLFEViscoRealK')
    modelName = "mRLFEViscoRealK";
    branches = results.models.mRLFEViscoRealK.branches;
elseif isfield(results.models, 'mRLFERealK')
    modelName = "mRLFERealK";
    branches = results.models.mRLFERealK.branches;
elseif isfield(results.models, 'mRLFEElasticRealK')
    modelName = "mRLFEElasticRealK";
    branches = results.models.mRLFEElasticRealK.branches;
else
    error('No mRLFE real-k branches were found in results.models.');
end
end
