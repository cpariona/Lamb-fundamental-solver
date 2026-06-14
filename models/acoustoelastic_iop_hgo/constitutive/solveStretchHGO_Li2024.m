function [lambda, info] = solveStretchHGO_Li2024(sigma, mu, k1, k2, varargin)
%SOLVESTRETCHHGO_LI2024 Compatibility wrapper for solveAcoustoelasticHGOStretch.
[lambda, info] = solveAcoustoelasticHGOStretch(sigma, mu, k1, k2, varargin{:});
end
