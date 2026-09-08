function [alpha, beta, gamma, state] = aeComputeABGFromIOPHGO(IOP, R, h, mu, k1, k2, varargin)
%AECOMPUTEABGFROMIOPHGO Compute alpha, beta, gamma from IOP and HGO parameters.
%
% Pipeline:
%   IOP, R, h, mu, k1, k2
%       -> sigma = IOP*R/(2h)
%       -> lambda from HGO stress equation
%       -> alpha, beta, gamma
%
% Inputs are SI units:
%   IOP : Pa
%   R   : m
%   h   : m
%   mu  : Pa
%   k1  : Pa
%   k2  : dimensionless

sigma = lamb.models.acoustoelastic_iop_hgo.constitutive.aeComputePrestressSigma(IOP, R, h);
[lambda, stretchInfo] = lamb.models.acoustoelastic_iop_hgo.constitutive.aeSolveHGOStretch(sigma, mu, k1, k2, varargin{:});
[alpha, beta, gamma, abgInfo] = lamb.models.acoustoelastic_iop_hgo.constitutive.aeComputeAlphaBetaGamma(lambda, mu, k1, k2);

state = struct();
state.IOP = IOP;
state.R = R;
state.h = h;
state.mu = mu;
state.k1 = k1;
state.k2 = k2;
state.sigma = sigma;
state.lambda = lambda;
state.stretchInfo = stretchInfo;
state.abgInfo = abgInfo;
end
