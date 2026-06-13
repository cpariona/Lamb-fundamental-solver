function [alpha, beta, gamma, state] = computeABGFromIOPHGO_Li2024(IOP, R, h, mu, k1, k2, varargin)
%COMPUTEABGFROMIOPHGO_LI2024 Compute alpha, beta, gamma from IOP and HGO parameters.
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

sigma = computePrestressSigma_Li2024(IOP, R, h);
[lambda, stretchInfo] = solveStretchHGO_Li2024(sigma, mu, k1, k2, varargin{:});
[alpha, beta, gamma, abgInfo] = computeAlphaBetaGamma_Li2024(lambda, mu, k1, k2);

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
