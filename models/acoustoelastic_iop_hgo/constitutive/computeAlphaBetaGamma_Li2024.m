function [alpha, beta, gamma, info] = computeAlphaBetaGamma_Li2024(lambda, mu, k1, k2)
%COMPUTEALPHABETAGAMMA_LI2024 Compatibility wrapper for computeAcoustoelasticAlphaBetaGamma.
[alpha, beta, gamma, info] = computeAcoustoelasticAlphaBetaGamma(lambda, mu, k1, k2);
end
