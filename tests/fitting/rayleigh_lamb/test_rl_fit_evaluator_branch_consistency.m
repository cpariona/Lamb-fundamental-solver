function tests = test_rl_fit_evaluator_branch_consistency()
%TEST_RL_FIT_EVALUATOR_BRANCH_CONSISTENCY Native fixed-mask and branch contracts.
tests = functiontests(localfunctions);
end

function testCanonicalPublicBranchIdentity(~)
% Public output and fixed objective predictions share one model-owned identity.
p=lamb.models.rayleigh_lamb.rlDefaultParams();p.mu=90e3;
o=lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
objective=[900 1500 2600 4500 7000 9000 12000].';
contexts={objective,sort([objective;linspace(1111,11111,10).']),sort([objective;linspace(222,11999,38).'])};
for branch=["A0","S0"]
 reference=[];
 for j=1:3
  f=contexts{j};[cp,raw]=lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(p,f,branch,o);
  q=p;q.frequencySpacing="explicit";q.frequencyVector_Hz=f;q.fmin=f(1);q.fmax=f(end);
  op=o;op.computeA0=branch=="A0";op.computeS0=branch=="S0";
  r=lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(q,op);
  assert(isequal(cp,r.modes.(branch).phaseVelocity_mps));
  assert(raw.trackingMode=="canonical_public_solver" && ~raw.reliability.SelectionFallbackUsed);
  [~,ix]=ismember(objective,f);if j==1,reference=cp(ix);end
  assert(isequal(reference,cp(ix)) && all(raw.validMask));
  ex=struct('frequency_Hz',f,'Cp_mps',cp,'validMask',ismember(f,objective));
  [~,info]=lamb.fitting.computeDispersionFitResiduals(cp,ex,struct());
  assert(nnz(info.validMask)==7 && isequal(info.validMask,ex.validMask));
 end
end
fprintf('RL canonical public/fitting equality and 7/17/45 fixed observations passed.\n');
end

function testExcludedInvalidFrequenciesRetainRowsAndOfficialDiagnostics(testCase)
p = lamb.models.rayleigh_lamb.rlDefaultParams(); p.mu = 90e3;
f = [4000; 0; 2000; NaN; 4000; -1; 1000; Inf; 3000];
admissible = isfinite(f) & f > 0;
mask = [true; false; false; false; true; false; true; false; true];
for branch = ["A0", "S0"]
    config = fitConfiguration(p, branch);
    [reference, official] = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel( ...
        p, f(admissible), branch, config.solverOptions);
    speed = nan(size(f)); speed(admissible) = reference + 0.1;
    speed(3) = NaN; % Excluded Cp must not prevent prediction at admissible Hz.
    ex = struct('frequency_Hz', f, 'Cp_mps', speed, 'validMask', mask, ...
        'sourceRow', (1:numel(f))');
    problem = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(ex, config);
    [cp, raw] = problem.evaluateModel(problem.baseParams);
    verifyEqual(testCase, problem.experimental.frequency_Hz, f);
    verifyEqual(testCase, problem.experimental.Cp_mps, speed);
    verifyEqual(testCase, problem.experimental.validMask, mask);
    verifyEqual(testCase, problem.experimental.sourceRow, ex.sourceRow);
    verifyEqual(testCase, cp(admissible), reference);
    verifyTrue(testCase, all(isnan(cp(~admissible))));
    verifyEqual(testCase, raw.frequency_Hz, f);
    verifyEqual(testCase, raw.Cp_mps, cp);
    verifyEqual(testCase, raw.omega, 2*pi*f);
    verifyEqual(testCase, raw.evaluatedObservationMask, admissible);
    verifyEqual(testCase, raw.validMask(admissible), official.validMask);
    verifyFalse(testCase, any(raw.validMask(~admissible)));
    for name = ["k", "kThickness", "residual"]
        verifyEqual(testCase, raw.(name)(admissible), official.(name));
        verifyTrue(testCase, all(isnan(raw.(name)(~admissible))));
    end
    verifyEqual(testCase, raw.diagnostics, official.diagnostics);
    verifyEqual(testCase, withoutElapsed(raw.modelResult), withoutElapsed(official.modelResult));
    verifyEqual(testCase, raw.trackingMode, official.trackingMode);
    verifyEqual(testCase, raw.reliability.ValidPoints, nnz(raw.validMask));
    verifyEqual(testCase, raw.reliability.MissingPoints, nnz(~raw.validMask));
    verifyEqual(testCase, raw.reliability.ValidFraction, mean(raw.validMask));
    verifyFalse(testCase, raw.reliability.SelectionFallbackUsed);
    positive = struct('frequency_Hz', f(admissible), 'Cp_mps', speed(admissible), ...
        'validMask', mask(admissible));
    [residual, info] = lamb.fitting.computeDispersionFitResiduals(cp, problem.experimental);
    expected = lamb.fitting.computeDispersionFitResiduals(reference, positive);
    verifyEqual(testCase, residual, expected);
    verifyEqual(testCase, info.objectiveMask, mask);
    verifyTrue(testCase, info.coverageAccepted);
    verifyEqual(testCase, info.evaluatedPointCount, nnz(mask));
    verifyEqual(testCase, lamb.fitting.computeDispersionFitMetrics(cp, problem.experimental), ...
        lamb.fitting.computeDispersionFitMetrics(reference, positive));
    cp(find(mask, 1)) = NaN;
    verifyError(testCase, @() lamb.fitting.computeDispersionFitResiduals(cp, problem.experimental), ...
        'lamb:fitting:IncompleteModelCoverage');
    verifyError(testCase, @() lamb.fitting.computeDispersionFitMetrics(cp, problem.experimental), ...
        'lamb:fitting:IncompleteModelCoverage');
end
end

function testUnitQualifiedSiInputsMatchLegacySolverPhysics(testCase)
% Public fit requests translate unit-qualified names without changing physics.
p = lamb.models.rayleigh_lamb.rlDefaultParams();
config = struct('branchName',"A0",'freeParams',"mu", ...
    'fixedParams',struct('rho',p.rho,'thickness',p.thickness,'nu',p.nu), ...
    'initialGuess',struct('mu',p.mu),'bounds',struct('mu',[5e4 2e5]));
experimental = struct('frequency_Hz',[1000;1500;2000], ...
    'Cp_mps',[2;3;4],'validMask',true(3,1));
legacy = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental,config);
config.fixedParams = struct('density_kgpm3',p.rho, ...
    'thickness_m',p.thickness,'poisson_ratio',p.nu);
config.freeParams = "mu_Pa";
config.initialGuess = struct('mu_Pa',p.mu);
config.bounds = struct('mu_Pa',[5e4 2e5]);
current = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental,config);
verifyEqual(testCase,current.freeParams,legacy.freeParams);
verifyEqual(testCase,current.baseParams,legacy.baseParams);
verifyEqual(testCase,current.x0,legacy.x0);
verifyEqual(testCase,current.lowerBounds,legacy.lowerBounds);
verifyEqual(testCase,current.upperBounds,legacy.upperBounds);
verifyEqual(testCase,current.experimental,legacy.experimental);
bad = config;
bad.fixedParams.rho = p.rho;
verifyError(testCase,@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem( ...
    experimental,bad),'lamb:rl:AmbiguousPhysicalInput');
bad = config;
bad.initialGuess.mu = p.mu;
verifyError(testCase,@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem( ...
    experimental,bad),'lamb:rl:AmbiguousPhysicalInput');
bad = config;
bad.bounds.mu = [5e4 2e5];
verifyError(testCase,@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem( ...
    experimental,bad),'lamb:rl:AmbiguousPhysicalInput');
bad = config;
bad.freeParams = ["mu","mu_Pa"];
verifyError(testCase,@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem( ...
    experimental,bad),'lamb:rl:AmbiguousPhysicalInput');
end

function testSelectedInvalidDataAreRejectedWithoutMaskRepair(testCase)
p = lamb.models.rayleigh_lamb.rlDefaultParams();
config = fitConfiguration(p, "A0");
ex = struct('frequency_Hz', [1000; 2000; 3000], ...
    'Cp_mps', [3; 4; 5], 'validMask', true(3, 1));
for bad = [0, -1, NaN, Inf]
    invalid = ex; invalid.frequency_Hz(2) = bad;
    verifyError(testCase, @() lamb.fitting.rayleigh_lamb.rlBuildFitProblem(invalid, config), ...
        'lamb:rl:InvalidSelectedObservation');
    % The absent/empty optional mask must not implicitly exclude invalid Hz.
    absent = rmfield(invalid, 'validMask');
    verifyError(testCase, @() lamb.fitting.rayleigh_lamb.rlBuildFitProblem(absent, config), ...
        'lamb:rl:InvalidSelectedObservation');
    absent.validMask = [];
    verifyError(testCase, @() lamb.fitting.rayleigh_lamb.rlBuildFitProblem(absent, config), ...
        'lamb:rl:InvalidSelectedObservation');
end
for bad = [NaN, Inf]
    invalid = ex; invalid.Cp_mps(2) = bad;
    verifyError(testCase, @() lamb.fitting.rayleigh_lamb.rlBuildFitProblem(invalid, config), ...
        'lamb:rl:InvalidSelectedObservation');
end
end

function testPositiveRequestsKeepDirectEvaluationExactly(testCase)
p = lamb.models.rayleigh_lamb.rlDefaultParams(); p.mu = 90e3;
f = [7000; 1000; 3000; 3000; 2000];
for branch = ["A0", "S0"]
    config = fitConfiguration(p, branch);
    [expected, official] = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel( ...
        p, f, branch, config.solverOptions);
    ex = struct('frequency_Hz', f, 'Cp_mps', expected, 'validMask', true(size(f)));
    for explicitMask = [true, false]
        if ~explicitMask, ex = rmfield(ex, 'validMask'); end
        problem = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(ex, config);
        [actual, raw] = problem.evaluateModel(problem.baseParams);
        verifyEqual(testCase, actual, expected);
        raw.modelResult = withoutElapsed(raw.modelResult);
        reference = official; reference.modelResult = withoutElapsed(reference.modelResult);
        verifyEqual(testCase, raw, reference);
        verifyFalse(testCase, isfield(raw, 'evaluatedObservationMask'));
    end
end
end

function testCompletedFitPreservesStatisticsAndMaskWithExcludedDc(testCase)
p = lamb.models.rayleigh_lamb.rlDefaultParams(); p.mu = 85e3;
f = [4000; 1000; 4000; 2000; 6000];
mask = [true; true; false; true; true];
for branch = ["A0", "S0"]
    config = fitConfiguration(p, branch); config.initialGuess.mu = 50e3;
    cp = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(p, f, branch, config.solverOptions);
    cp = cp + [0.01; -0.01; 0; 0.02; -0.02]; cp(3) = NaN;
    ex = struct('frequency_Hz', f, 'Cp_mps', cp, 'validMask', mask);
    reference = lamb.fitting.rayleigh_lamb.rlFitDispersionData(ex, config);
    padded = struct('frequency_Hz', [0; f; NaN], 'Cp_mps', [NaN; cp; NaN], ...
        'validMask', [false; mask; false]);
    result = lamb.fitting.rayleigh_lamb.rlFitDispersionData(padded, config);
    verifyEqual(testCase, result.frequency_Hz, padded.frequency_Hz);
    verifyEqual(testCase, result.Cp_exp_mps, padded.Cp_mps);
    verifyEqual(testCase, result.validMask, padded.validMask);
    verifyEqual(testCase, result.problem.experimental.validMask, padded.validMask);
    verifyEqual(testCase, result.Cp_fit_mps(2:end-1), reference.Cp_fit_mps);
    verifyTrue(testCase, all(isnan(result.Cp_fit_mps([1 end]))));
    for name = ["bestParams", "allParams", "residuals", "metrics", ...
            "identifiability", "sensitivityMatrix", "optimizer"]
        verifyEqual(testCase, result.(name), reference.(name));
    end
    verifyEqual(testCase, result.residualInfo.objectiveMask, padded.validMask);
    verifyTrue(testCase, result.residualInfo.coverageAccepted);
    verifyEqual(testCase, result.residualInfo.expectedPointCount, nnz(mask));
    verifyEqual(testCase, result.residualInfo.rawResiduals_mps, reference.residualInfo.rawResiduals_mps);
    verifyEqual(testCase, result.modelEvaluation.diagnostics, reference.modelEvaluation.diagnostics);
    verifyEqual(testCase, withoutElapsed(result.modelEvaluation.modelResult), ...
        withoutElapsed(reference.modelEvaluation.modelResult));
end
end

function testSingletonFrequencyRetainsNativeAuxiliaryGrid(testCase)
p = lamb.models.rayleigh_lamb.rlDefaultParams();
for branch = ["A0", "S0"]
    config = fitConfiguration(p, branch);
    [expected, official] = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel( ...
        p, [2000; 2000], branch, config.solverOptions);
    ex = struct('frequency_Hz', [0; 2000; 2000], 'Cp_mps', [NaN; expected], ...
        'validMask', [false; true; true]);
    problem = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(ex, config);
    [cp, raw] = problem.evaluateModel(problem.baseParams);
    verifyEqual(testCase, cp(2:3), expected);
    verifyTrue(testCase, isnan(cp(1)));
    verifyEqual(testCase, withoutElapsed(raw.modelResult), withoutElapsed(official.modelResult));
end
end

function testPerObservationThicknessKeepsNativeGroupsAndOriginalRows(testCase)
% Direction-matched thickness groups must not be averaged or rounded.
p=lamb.models.rayleigh_lamb.rlDefaultParams();
p.mu=85e3; p.rho=1050; p.nu=0.4999;
f=[0;900;1100;1500;1800;2200;2600];
h=[NaN;.405e-3;.406e-3;.405e-3;.406e-3;.405e-3;.406e-3];
selected=[false;true;true;false;true;true;true];
cp=nan(size(f));op=lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
for thickness=unique(h(2:end))'
    rows=find(f>0 & h==thickness);
    q=p;q.thickness=thickness;
    cp(rows)=lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(q,f(rows),"A0",op);
end
ex=struct('frequency_Hz',f,'Cp_mps',cp,'validMask',selected, ...
    'observationThickness_m',h);
config=fitConfiguration(p,"A0");
config.fixedParams.thickness=NaN; % Not a physical constant in grouped mode.
problem=lamb.fitting.rayleigh_lamb.rlBuildFitProblem(ex,config);
verifyEqual(testCase,problem.baseParams.thickness,h(2));
verifyEqual(testCase,problem.experimental.observationThickness_m,h);
[fitCp,raw]=problem.evaluateModel(problem.baseParams);
verifyEqual(testCase,fitCp(2:end),cp(2:end));
verifyTrue(testCase,isnan(fitCp(1)));
verifyEqual(testCase,raw.validMask,[false;true(6,1)]);
verifyEqual(testCase,raw.observationThickness_m,h);
verifyEqual(testCase,raw.trackingMode,"canonical_public_solver_by_thickness");
verifyEmpty(testCase,raw.modelResult);
verifyEqual(testCase,[raw.modelResultsByThickness.thickness_m]',unique(h(2:end),'stable'));
verifyEqual(testCase,raw.modelResultsByThickness(1).observationRows,[2;4;6]);
verifyEqual(testCase,raw.modelResultsByThickness(2).observationRows,[3;5;7]);
verifyEqual(testCase,raw.reliability.ValidPoints,6);
fit=lamb.fitting.rayleigh_lamb.rlFitDispersionData(ex,config);
verifyEqual(testCase,fit.validMask,selected);
verifyEqual(testCase,fit.problem.experimental.observationThickness_m,h);
verifyLessThan(testCase,abs(fit.bestParams.mu-p.mu)/p.mu,0.05);
verifyLessThan(testCase,fit.metrics.RMSE,0.05);
end

function testObservationThicknessRejectsMissingDataAndScalarFit(testCase)
p=lamb.models.rayleigh_lamb.rlDefaultParams();
config=fitConfiguration(p,"A0");
ex=struct('frequency_Hz',[0;1000;2000],'Cp_mps',[NaN;5;6], ...
    'validMask',[false;true;true], ...
    'observationThickness_m',[NaN;.405e-3;.406e-3]);
for bad=[NaN,0,-.001,Inf]
    changed=ex;changed.observationThickness_m(2)=bad;
    verifyError(testCase,@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem(changed,config), ...
        'lamb:rl:ObservationThickness');
end
changed=ex;changed.observationThickness_m=changed.observationThickness_m(2:end);
verifyError(testCase,@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem(changed,config), ...
    'lamb:rl:ObservationThickness');
config.freeParams="thickness";
verifyError(testCase,@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem(ex,config), ...
    'lamb:rl:ThicknessConflict');
end

function config = fitConfiguration(p, branch)
config = struct('branchName', branch, 'freeParams', "mu", ...
    'fixedParams', struct('rho', p.rho, 'thickness', p.thickness, 'nu', p.nu), ...
    'initialGuess', struct('mu', p.mu), 'bounds', struct('mu', [20e3 200e3]), ...
    'solverOptions', lamb.models.rayleigh_lamb.rlDefaultOptions("Fast"), ...
    'fitOptions', struct('useStandardErrorWeights', false));
end

function result = withoutElapsed(result)
result.execution = rmfield(result.execution, 'elapsedSeconds');
end
