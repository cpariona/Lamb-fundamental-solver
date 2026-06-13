clear; clc;
startup

% Consistency test for the Li 2024 IOP/HGO constitutive block.
% The acoustoelastic parameters should satisfy alpha - gamma = sigma for the
% current equibiaxial prestress implementation.

IOP = 15 * 133.322;
R = 7.8e-3;
h = 550e-6;
mu = 50e3;
k1 = 25e3;
k2 = 100;

[alpha, beta, gamma, state] = computeABGFromIOPHGO_Li2024(IOP, R, h, mu, k1, k2);

sigmaFromABG = alpha - gamma;
relativeError = abs(sigmaFromABG - state.sigma) / max(abs(state.sigma), eps);

assert(isfinite(alpha) && isfinite(beta) && isfinite(gamma), 'alpha, beta, gamma must be finite.');
assert(isfinite(state.sigma) && state.sigma > 0, 'sigma must be finite and positive.');
assert(isfinite(state.lambda) && state.lambda >= 1, 'lambda must be finite and >= 1.');
assert(relativeError < 1e-8, 'Constitutive identity alpha - gamma = sigma failed.');

fprintf('test_li2024_constitutive_identity passed. sigma = %.6g Pa, alpha-gamma = %.6g Pa, rel. error = %.3e.\n', ...
    state.sigma, sigmaFromABG, relativeError);
