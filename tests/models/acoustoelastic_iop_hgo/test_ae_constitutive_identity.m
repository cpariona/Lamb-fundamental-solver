function test_ae_constitutive_identity()
%TEST_AE_CONSTITUTIVE_IDENTITY Check alpha - gamma = sigma.

IOP = 15 * 133.322;
R = 7.8e-3;
h = 550e-6;
mu = 50e3;
k1 = 25e3;
k2 = 100;

[alpha, beta, gamma, state] = lamb.models.acoustoelastic_iop_hgo.constitutive.aeComputeABGFromIOPHGO(IOP, R, h, mu, k1, k2);

sigmaFromABG = alpha - gamma;
relativeError = abs(sigmaFromABG - state.sigma) / max(abs(state.sigma), eps);

assert(isfinite(alpha) && isfinite(beta) && isfinite(gamma), 'alpha, beta, gamma must be finite.');
assert(isfinite(state.sigma) && state.sigma > 0, 'sigma must be finite and positive.');
assert(isfinite(state.lambda) && state.lambda >= 1, 'lambda must be finite and >= 1.');
assert(relativeError < 1e-8, 'Constitutive identity alpha - gamma = sigma failed.');

fprintf('test_ae_constitutive_identity passed. sigma = %.6g Pa, alpha-gamma = %.6g Pa, rel. error = %.3e.\n', ...
    state.sigma, sigmaFromABG, relativeError);
end
