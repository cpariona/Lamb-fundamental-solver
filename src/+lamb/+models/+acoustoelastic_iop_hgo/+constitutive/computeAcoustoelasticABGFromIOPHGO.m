function [alpha, beta, gamma, state] = computeAcoustoelasticABGFromIOPHGO(IOP, R, h, mu, k1, k2, varargin)
%COMPUTEACOUSTOELASTICABGFROMIOPHGO Compute alpha, beta, gamma from IOP and HGO parameters.
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

sigma = lamb.models.acoustoelastic_iop_hgo.constitutive.computeAcoustoelasticPrestressSigma(IOP, R, h);
[lambda, stretchInfo] = lamb.models.acoustoelastic_iop_hgo.constitutive.solveAcoustoelasticHGOStretch(sigma, mu, k1, k2, varargin{:});
[alpha, beta, gamma, abgInfo] = lamb.models.acoustoelastic_iop_hgo.constitutive.computeAcoustoelasticAlphaBetaGamma(lambda, mu, k1, k2);

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
