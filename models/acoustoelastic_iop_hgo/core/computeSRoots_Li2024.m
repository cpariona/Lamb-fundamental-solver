function [s1, s2, rootInfo] = computeSRoots_Li2024(alpha, beta, gamma, rho, c)
%COMPUTESROOTS_LI2024 Compatibility wrapper for computeAcoustoelasticSRoots.

[s1, s2, rootInfo] = computeAcoustoelasticSRoots(alpha, beta, gamma, rho, c);
end
