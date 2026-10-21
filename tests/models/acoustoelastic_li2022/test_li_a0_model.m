function tests = test_li_a0_model()
%TEST_LI_A0_MODEL Independent roots, limits, units and interpretation.
tests = functiontests(localfunctions);
end

function testIndependentPhysicalRoots(testCase)
% 80-digit Decimal bisection of the ORIGINAL (not deflated) equation,
% eta bracket [0.29, 1-1e-32], 280 iterations. No production calls.
q = [1e-6, 0.001, 0.049999, 0.05, 0.050001, 0.1, 0.5, 1, 2, 5, 10, 30, 63.999, 64, 100];
expectedEta = [0.99999999999933333333, 0.99999933333431110926, ...
    0.99833948187927425662, 0.99833941569870538033, 0.99833934951683216069, ...
    0.99342930071491201626, 0.87550750891350990262, 0.69861389242940848731, ...
    0.49276294507311272130, 0.33109594846937926401, 0.29786764584529804169, ...
    0.29559775980216178529, 0.29559774252208480321, ...
    0.29559774252208480319, 0.29559774252208477098];
curve = lamb.models.acoustoelastic_li2022.liA0MasterCurve(q);
verifyEqual(testCase, curve.eta, expectedEta, 'AbsTol', 2e-13);
verifyLessThan(testCase, max(curve.eta), 1);
verifyLessThan(testCase, max(diff(curve.eta)), 1e-15);
verifyEqual(testCase, size(curve.eta), size(q));
end

function testDeflatedLimitAndFlexuralCorrection(testCase)
q = [0, 1e-12, 1e-9, 1e-6];
curve = lamb.models.acoustoelastic_li2022.liA0MasterCurve(q);
verifyEqual(testCase, curve.eta(1), 1);
verifyEqual(testCase, curve.oneMinusEtaSquared(1), 0);
verifyEqual(testCase, curve.oneMinusEtaSquared(2:end)./q(2:end).^2, ...
    repmat(4/3, 1, 3), 'RelTol', 2e-12);
verifyGreaterThan(testCase, curve.oneMinusEtaSquared(2), 0);
end

function testRayleighLimitAndResidual(testCase)
curve = lamb.models.acoustoelastic_li2022.liA0MasterCurve([0.2, 1, 4, 20, 64, 1e5, Inf]);
e = curve.eta(end);
verifyEqual(testCase, e^3+e^2+3*e-1, 0, 'AbsTol', 2e-15);
verifyEqual(testCase, curve.eta(end-2:end), repmat(e, 1, 3));
q = curve.wavenumberThickness(1:4); eta = curve.eta(1:4);
verifyEqual(testCase, 4*eta.*tanh(eta.*q)./tanh(q)-(1+eta.^2).^2, ...
    zeros(1, 4), 'AbsTol', 2e-14);
end

function testIndependentForwardReferenceAndUnits(testCase)
% Independently tabulated q=0.1,0.5,1,2,5 roots, then rho*Cp^2=a-g*eta^2.
f = [800.14304727021295, 4367.7985459023481, 9583.0979186334731, ...
    20543.560908072888, 53135.565817473445];
expectedCp = [12.568617595625258, 13.721843824166998, 15.053095009905279, ...
    16.134875006844061, 16.693030321651151].';
p = physicalParameters();
mode = lamb.models.acoustoelastic_li2022.liPredictA0(f, p);
verifyEqual(testCase, mode.phaseVelocity_mps, expectedCp, 'AbsTol', 2e-11);
verifyEqual(testCase, mode.wavenumberThickness, [0.1; 0.5; 1; 2; 5], 'AbsTol', 2e-11);
verifyEqual(testCase, mode.angularFrequency_radps, 2*pi*f.');
verifyEqual(testCase, mode.wavenumber_radpm*(p.thickness_m/2), ...
    mode.wavenumberThickness, 'AbsTol', 1e-15);
verifyEqual(testCase, mode.wavenumber_radpm.*mode.phaseVelocity_mps, ...
    mode.angularFrequency_radps, 'RelTol', 2e-13);
% Keeping f*fullThickness constant must preserve Cp and kh.
p.thickness_m = 2*p.thickness_m;
doubled = lamb.models.acoustoelastic_li2022.liPredictA0(f/2, p);
verifyEqual(testCase, doubled.phaseVelocity_mps, mode.phaseVelocity_mps, 'AbsTol', 2e-12);
end

function testUnstressedFlexureAndTensileLimit(testCase)
p = physicalParameters();
mode = lamb.models.acoustoelastic_li2022.liPredictA0([0, 1e-8, 1e7], p);
verifyEqual(testCase, mode.phaseVelocity_mps(1), sqrt((p.alpha_Pa-p.gamma_Pa)/p.density_kgpm3));
verifyEqual(testCase, mode.phaseVelocity_mps(3), 16.784448595016187, 'AbsTol', 2e-12);
p.alpha_Pa = p.gamma_Pa;
mode = lamb.models.acoustoelastic_li2022.liPredictA0([0, 1e-10, 1e-6], p);
verifyEqual(testCase, mode.phaseVelocity_mps(1), 0);
verifyEqual(testCase, mode.wavenumber_radpm(1), 0);
verifyGreaterThan(testCase, mode.phaseVelocity_mps(2), 0);
verifyEqual(testCase, mode.phaseVelocity_mps(2:3)./mode.wavenumberThickness(2:3), ...
    repmat(sqrt(4*p.gamma_Pa/(3*p.density_kgpm3)), 2, 1), 'RelTol', 1e-9);
end

function testForwardPreservesOrderAndDuplicates(testCase)
p = physicalParameters();
mode = lamb.models.acoustoelastic_li2022.liPredictA0([1000, 0, 1000, 10], p);
verifyEqual(testCase, mode.frequency_Hz, [1000; 0; 1000; 10]);
verifyEqual(testCase, mode.phaseVelocity_mps(1), mode.phaseVelocity_mps(3));
verifyTrue(testCase, all(mode.validMask));
p.alpha_Pa = p.gamma_Pa/2;
verifyError(testCase, @() lamb.models.acoustoelastic_li2022.liPredictA0(1000, p), ...
    'lamb:li2022:UnsupportedCompression');
end

function testGeneralPrincipalInterpretation(testCase)
% General triaxial stretches: incompressible, NOT uniaxial.
lambda = [1.2, 1.1, 1/(1.2*1.1)];
mu = 180e3;
state = lamb.models.acoustoelastic_li2022.liInterpretModuli(mu*lambda(1)^2, mu*lambda(3)^2);
verifyEqual(testCase, state.stressDifferencePropagationMinusNormal_Pa, ...
    mu*(lambda(1)^2-lambda(3)^2), 'AbsTol', 1e-10);
verifyEqual(testCase, state.stretchRatioPropagationToNormal, lambda(1)/lambda(3), 'AbsTol', 1e-14);
verifyTrue(testCase, isnan(state.propagationStretch));
verifyFalse(testCase, isfield(state, 'principalStress_Pa'));
verifyGreaterThan(testCase, abs((lambda(1)/lambda(3))^(2/3)-lambda(1)), 0.01);
end

function testExplicitUniaxialInterpretation(testCase)
lambda = 1.3; gamma = 147200;
state = lamb.models.acoustoelastic_li2022.liInterpretModuli(gamma*lambda^3, gamma, "uniaxial");
verifyEqual(testCase, state.propagationStretch, lambda, 'AbsTol', 1e-14);
verifyEqual(testCase, state.normalStretch, lambda^(-1/2), 'AbsTol', 1e-14);
verifyEqual(testCase, state.propagationStretch*state.normalStretch*state.otherPrincipalStretch, ...
    1, 'AbsTol', 1e-14);
end

function testUniaxialSelectionMustBeExplicit(testCase)
verifyError(testCase, @() lamb.models.acoustoelastic_li2022.liInterpretModuli(2, 1, "u"), ...
    'lamb:li2022:InvalidKinematics');
verifyError(testCase, @() lamb.models.acoustoelastic_li2022.liInterpretModuli(2, 1, ["principal", "uniaxial"]), ...
    'lamb:li2022:InvalidKinematics');
end

function p = physicalParameters()
p = struct('alpha_Pa', 314300, 'gamma_Pa', 147200, ...
    'density_kgpm3', 1070, 'thickness_m', 0.0005);
end
