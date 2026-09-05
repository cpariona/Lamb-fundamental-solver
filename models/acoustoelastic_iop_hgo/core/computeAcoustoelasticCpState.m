function state = computeAcoustoelasticCpState(alpha, beta, gamma, rho, rhoF, fluidBulkModulus, c)
%COMPUTEACOUSTOELASTICCPSTATE Precompute AE quantities that depend only on Cp.

[s1, s2, rootInfo] = computeAcoustoelasticSRoots(alpha, beta, gamma, rho, c);
xi = sqrt(complex(1 - (c^2 * rhoF / fluidBulkModulus)));

state = struct();
state.c = c;
state.s1 = s1;
state.s2 = s2;
state.xi = xi;
state.rootInfo = rootInfo;
end
