function state = computeAcoustoelasticCpState(alpha, beta, gamma, rho, rhoF, fluidBulkModulus, c)
%COMPUTEACOUSTOELASTICCPSTATE Precompute AE quantities that depend only on Cp.

[s1, s2, rootInfo] = computeAcoustoelasticSRoots(alpha, beta, gamma, rho, c);
xi = sqrt(complex(1 - (c^2 * rhoF / fluidBulkModulus)));
s1SquaredPlusOne = s1^2 + 1;
s2SquaredPlusOne = s2^2 + 1;

state = struct();
state.c = c;
state.s1 = s1;
state.s2 = s2;
state.xi = xi;
state.s1SquaredPlusOne = s1SquaredPlusOne;
state.s2SquaredPlusOne = s2SquaredPlusOne;
state.gammaS1S2SquaredPlusOne = gamma * s1 * s2SquaredPlusOne;
state.gammaS2S1SquaredPlusOne = gamma * s2 * s1SquaredPlusOne;
state.s1S2SquaredPlusOne = s1 * s2SquaredPlusOne;
state.s2S1SquaredPlusOne = s2 * s1SquaredPlusOne;
state.fluidCoupling = 1i * rhoF * c^2;
state.rootInfo = rootInfo;
end
