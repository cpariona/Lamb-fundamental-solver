function tests = test_ae_plate_model()
%TEST_AE_PLATE_MODEL Independent roots, limits, units and interpretation.
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
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
verifyEqual(testCase, curve.eta, expectedEta, 'AbsTol', 2e-13);
verifyLessThan(testCase, max(curve.eta), 1);
verifyLessThan(testCase, max(diff(curve.eta)), 1e-15);
verifyEqual(testCase, size(curve.eta), size(q));
end

function testDeflatedLimitAndFlexuralCorrection(testCase)
q = [0, 1e-12, 1e-9, 1e-6];
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
verifyEqual(testCase, curve.eta(1), 1);
verifyEqual(testCase, curve.oneMinusEtaSquared(1), 0);
verifyEqual(testCase, curve.oneMinusEtaSquared(2:end)./q(2:end).^2, ...
    repmat(4/3, 1, 3), 'RelTol', 2e-12);
verifyGreaterThan(testCase, curve.oneMinusEtaSquared(2), 0);
end

function testTinyFlexuralBracketRegression(testCase)
% All 33 failures identified by the independent characterization sweep.
q = [1.0914403364487571e-14;1.6904409316432633e-14;2.0137242498623896e-14; ...
    4.0550853544838433e-14;4.623810213992594e-14;8.5310011401759131e-14; ...
    1.2105981335504829e-13;4.6989410860521603e-13;7.2777980453682418e-13; ...
    1.0327614057613959e-12;1.4028137045619589e-12;1.4655478409559129e-12; ...
    2.0796966871036939e-12;1.425607593602188e-11;1.625548755750485e-11; ...
    1.9364219639466029e-11;2.2080047330188969e-11;2.3067471887200668e-11; ...
    2.7478941531023972e-11;3.2734069487883859e-11;5.2966344389165804e-11; ...
    5.5335010921573709e-11;1.2705741052085393e-10;2.2438819237827616e-10; ...
    2.5585858869056529e-10;3.4753616144320608e-10;4.3251383103500792e-10; ...
    1.538154640303039e-9;1.6788040181225589e-9;2.2803420720004208e-9; ...
    2.382319469358684e-9;3.2359365692962812e-9;5.4701596289397102e-9];
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
verifyGreaterThan(testCase,curve.oneMinusEtaSquared,0);
verifyEqual(testCase,curve.oneMinusEtaSquared./q.^2,repmat(4/3,size(q)),'RelTol',2e-12);
for k=1:numel(q)
    scalar = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q(k));
    verifyEqual(testCase,scalar.eta,curve.eta(k));
    verifyEqual(testCase,scalar.oneMinusEtaSquared,curve.oneMinusEtaSquared(k));
end
end

function testTransitionNeighboursPreservePhysicalBranch(testCase)
q = [.05-eps(.05),.05,.05+eps(.05);64-eps(64),64,64+eps(64)];
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
reference = repmat([.99833941569870538033;.29559774252208480319],1,3);
verifyEqual(testCase,curve.eta,reference,'AbsTol',2e-13);
verifyEqual(testCase,size(curve.eta),size(q));
residual = 4*curve.eta.*tanh(curve.eta.*q)./tanh(q)-(1+curve.eta.^2).^2;
verifyEqual(testCase,residual,zeros(size(q)),'AbsTol',2e-14);
for k=1:numel(q)
    scalar = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q(k));
    verifyEqual(testCase,scalar.oneMinusEtaSquared,curve.oneMinusEtaSquared(k));
end
end

function testLowFrequencyForwardNearTensileBoundary(testCase)
p = physicalParameters();
frequency = [0;logspace(-10,8,61)'];
for stress = [0,eps(p.gamma_Pa),1e-8*p.gamma_Pa,1e-4*p.gamma_Pa,p.gamma_Pa]
    p.alpha_Pa = p.gamma_Pa+stress;
    mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(frequency,p);
    verifyTrue(testCase,all(mode.validMask));
    verifyEqual(testCase,mode.frequency_Hz,frequency);
    verifyEqual(testCase,mode.wavenumber_radpm(2:end).*mode.phaseVelocity_mps(2:end), ...
        mode.angularFrequency_radps(2:end),'RelTol',2e-13);
    verifyEqual(testCase,mode.phaseVelocity_mps(1),sqrt((p.alpha_Pa-p.gamma_Pa)/p.density_kgpm3));
end
end

function testRayleighLimitAndResidual(testCase)
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve([0.2, 1, 4, 20, 64, 1e5, Inf]);
e = curve.eta(end);
verifyEqual(testCase,e,0.29559774252208477098);
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
mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(f, p);
verifyEqual(testCase, mode.phaseVelocity_mps, expectedCp, 'AbsTol', 2e-11);
verifyEqual(testCase, mode.wavenumberThickness, [0.1; 0.5; 1; 2; 5], 'AbsTol', 2e-11);
verifyEqual(testCase, mode.angularFrequency_radps, 2*pi*f.');
verifyEqual(testCase, mode.wavenumber_radpm*(p.thickness_m/2), ...
    mode.wavenumberThickness, 'AbsTol', 1e-15);
verifyEqual(testCase, mode.wavenumber_radpm.*mode.phaseVelocity_mps, ...
    mode.angularFrequency_radps, 'RelTol', 2e-13);
% Keeping f*fullThickness constant must preserve Cp and kh.
p.thickness_m = 2*p.thickness_m;
doubled = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(f/2, p);
verifyEqual(testCase, doubled.phaseVelocity_mps, mode.phaseVelocity_mps, 'AbsTol', 2e-12);
end

function testUnstressedFlexureAndTensileLimit(testCase)
p = physicalParameters();
mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion([0, 1e-8, 1e7], p);
verifyEqual(testCase, mode.phaseVelocity_mps(1), sqrt((p.alpha_Pa-p.gamma_Pa)/p.density_kgpm3));
verifyEqual(testCase, mode.phaseVelocity_mps(3), 16.784448595016187, 'AbsTol', 2e-12);
p.alpha_Pa = p.gamma_Pa;
mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion([0, 1e-10, 1e-6], p);
verifyEqual(testCase, mode.phaseVelocity_mps(1), 0);
verifyEqual(testCase, mode.wavenumber_radpm(1), 0);
verifyGreaterThan(testCase, mode.phaseVelocity_mps(2), 0);
verifyEqual(testCase, mode.phaseVelocity_mps(2:3)./mode.wavenumberThickness(2:3), ...
    repmat(sqrt(4*p.gamma_Pa/(3*p.density_kgpm3)), 2, 1), 'RelTol', 1e-9);
end

function testForwardPreservesOrderAndDuplicates(testCase)
p = physicalParameters();
mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion([1000, 0, 1000, 10], p);
verifyEqual(testCase, mode.frequency_Hz, [1000; 0; 1000; 10]);
verifyEqual(testCase, mode.phaseVelocity_mps(1), mode.phaseVelocity_mps(3));
verifyTrue(testCase, all(mode.validMask));
p.alpha_Pa = p.gamma_Pa/2;
verifyError(testCase, @() lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(1000, p), ...
    'lamb:aePlate:UnsupportedCompression');
end

function testGeneralPrincipalInterpretation(testCase)
% General triaxial stretches: incompressible, NOT uniaxial.
lambda = [1.2, 1.1, 1/(1.2*1.1)];
mu = 180e3;
state = lamb.models.acoustoelastic_prestressed_plate.aePlateInterpretModuli(mu*lambda(1)^2, mu*lambda(3)^2);
verifyEqual(testCase, state.stressDifferencePropagationMinusNormal_Pa, ...
    mu*(lambda(1)^2-lambda(3)^2), 'AbsTol', 1e-10);
verifyEqual(testCase, state.stretchRatioPropagationToNormal, lambda(1)/lambda(3), 'AbsTol', 1e-14);
verifyTrue(testCase, isnan(state.propagationStretch));
verifyFalse(testCase, isfield(state, 'principalStress_Pa'));
verifyGreaterThan(testCase, abs((lambda(1)/lambda(3))^(2/3)-lambda(1)), 0.01);
end

function testExplicitUniaxialInterpretation(testCase)
lambda = 1.3; gamma = 147200;
state = lamb.models.acoustoelastic_prestressed_plate.aePlateInterpretModuli(gamma*lambda^3, gamma, "uniaxial");
verifyEqual(testCase, state.propagationStretch, lambda, 'AbsTol', 1e-14);
verifyEqual(testCase, state.normalStretch, lambda^(-1/2), 'AbsTol', 1e-14);
verifyEqual(testCase, state.propagationStretch*state.normalStretch*state.otherPrincipalStretch, ...
    1, 'AbsTol', 1e-14);
end

function testUniaxialSelectionMustBeExplicit(testCase)
verifyError(testCase, @() lamb.models.acoustoelastic_prestressed_plate.aePlateInterpretModuli(2, 1, "u"), ...
    'lamb:aePlate:InvalidKinematics');
verifyError(testCase, @() lamb.models.acoustoelastic_prestressed_plate.aePlateInterpretModuli(2, 1, ["principal", "uniaxial"]), ...
    'lamb:aePlate:InvalidKinematics');
end

function p = physicalParameters()
p = struct('alpha_Pa', 314300, 'gamma_Pa', 147200, ...
    'density_kgpm3', 1070, 'thickness_m', 0.0005);
end
