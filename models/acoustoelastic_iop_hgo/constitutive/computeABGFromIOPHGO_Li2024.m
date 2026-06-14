function [alpha, beta, gamma, state] = computeABGFromIOPHGO_Li2024(IOP, R, h, mu, k1, k2, varargin)
%COMPUTEABGFROMIOPHGO_LI2024 Compatibility wrapper for computeAcoustoelasticABGFromIOPHGO.
[alpha, beta, gamma, state] = computeAcoustoelasticABGFromIOPHGO(IOP, R, h, mu, k1, k2, varargin{:});
end
