function test_main_gui_diagnostics_text()
%TEST_MAIN_GUI_DIAGNOSTICS_TEXT Validate model-specific Main GUI diagnostics.

fprintf('Running Main GUI diagnostics text test...\n');

setup = struct('modelType', "ShearPoisson", 'rho', 1070, 'mu', 158e3, ...
    'nu', 0.4999, 'thickness', 0.5e-3, 'E', 473968, ...
    'lambda', 7.89842e8, 'K', 7.89947e8, 'CL', 859.34, 'CT', 12.1517);

assertRlDiagnostics(setup);
assertMrlfeDiagnostics(setup);
assertAeDiagnostics(setup);

fprintf('Main GUI diagnostics text test passed.\n');
end

function assertRlDiagnostics(setup)
[~, profile] = rlResolveExecutionProfile("Balanced", ...
    'DefaultProfile', "Balanced", 'DefaultSource', "Main GUI default");
mode = struct('frequency_Hz', [300; 1000], 'phaseVelocity_mps', [2; 3], ...
    'validMask', [true; true]);
result = struct('model', "rayleigh_lamb", 'modes', struct('A0', mode));
view = makeView("RayleighLamb", "A0", mode.phaseVelocity_mps, mode.validMask, profile);
options = struct('executionProfile', "Balanced", 'computeA0', true, 'computeS0', false);

txt = guiBuildMainDiagnosticsText(view, result, options, setup);
assertContains(txt, "Rayleigh-Lamb diagnostics");
assertContains(txt, "requested A0: 1");
assertContains(txt, "requested S0: 0");
assertContains(txt, "lambda_Lame");
assertNotContains(txt, "Rayleigh-Lamb seed");
end

function assertMrlfeDiagnostics(setup)
assertMrlfeStatus();
result = struct();
result.model = "mrlfe";
result.branch = "A0Like";
result.frequency_Hz = [300; 1000];
result.phaseVelocity_mps = [2; 3];
result.validMask = [true; true];
result.quality = struct('accepted', true, 'reason', "accepted");
result.execution = struct('internalEngine', "elastic_adaptive", ...
    'requestedPreset', "balanced", 'effectivePreset', "balanced");
result.termination = struct('policy', "physicalTail", 'applied', false, ...
    'reason', "none", 'firstRejectedFrequency_Hz', nan);
result.fallback = struct('policy', "none", 'applied', false, 'reason', "none");

[~, profile] = mrlfeResolveExecutionProfile("A0Like", ...
    struct('executionProfile', "Balanced"), ...
    'Surface', "solver", 'DefaultProfile', "Balanced", ...
    'DefaultSource', "Main GUI default", 'EtaS', 0, 'A0Policy', "physicalTail");
profile = mrlfeBuildSurfaceExecutionMetadata(profile, {result}, ...
    'SurfaceDefault', "Balanced", ...
    'RoutePolicy', "lamb.models.mrlfe.mrlfeSolve", ...
    'EtaS', 0, 'A0Policy', "physicalTail");

view = makeView("mRLFERealK", "A0Like", result.phaseVelocity_mps, result.validMask, profile);
view.metadata.modelResult = result;
view.metadata.modelResults = struct('A0Like', result);
view.metadata.execution = struct('A0Like', result.execution);
view.metadata.termination = struct('A0Like', result.termination);
view.metadata.fallback = struct('A0Like', result.fallback);
view.metadata.quality = struct('A0Like', result.quality);
params = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
params.etaS = 0;
view.metadata.options = struct('executionProfile', "Balanced", ...
    'branchNames', "A0Like", 'mrlfeA0Policy', "physicalTail", 'mrlfeParams', params);
options = view.metadata.options;

txt = guiBuildMainDiagnosticsText(view, result, options, setup);
assertContains(txt, "mRLFE diagnostics");
assertContains(txt, "numerical preset: balanced");
assertContains(txt, "A0Like termination policy: physicalTail");
assertContains(txt, "S0Like termination policy: none");
assertContains(txt, "termination: physicalTail");
assertNotContains(txt, "atlas preset:");
end

function assertMrlfeStatus()
for complete = [false true]
    for accepted = [false true]
        r = struct('model', "mrlfe", 'branch', "A0Like", ...
            'validMask', [true; complete; true], ...
            'quality', struct('accepted', accepted, 'reason', "large_relative_jump"));
        status = "success";
        if ~accepted, status = "partial"; end
        view = struct('metadata', struct('status', status, 'modelResults', struct('A0Like', r)));
        before = view;
        lines = guiBuildMrlfeStatusText(view);
        assert(contains(lines(1), '(partial)') == (~complete || ~accepted));
        assertContains(lines(2), sprintf('Cp valid %d/3', 2+complete));
        assertContains(lines(2), sprintf('quality accepted: %d', accepted));
        assertContains(lines(2), 'large_relative_jump');
        assert(isequaln(view, before));
        second = r; second.branch = "S0Like"; second.validMask = true(3,1);
        view.metadata.modelResults.S0Like = second;
        assert(numel(guiBuildMrlfeStatusText(view)) == 3);
    end
end
assert(isempty(guiBuildMrlfeStatusText(struct())));
assert(contains(fileread(which('LambFundamental_GUI')), 'guiBuildMrlfeStatusText(lastGuiResult'));
end

function assertAeDiagnostics(setup)
[~, profile] = aeResolveExecutionProfile("Balanced", ...
    'DefaultProfile', "Balanced", 'DefaultSource', "Main GUI default", ...
    'Surface', "MainGUI");

frequency = [10; 300; 1000];
valid = [false; true; true];
selected = table(1, 2, 300, 1000, 0.1, 1, true, false, ...
    'VariableNames', {'BranchID','NumPoints','FrequencyStart_Hz','FrequencyEnd_Hz', ...
    'YStart','StartRank','A0StartFilterPassed','SelectionFallbackUsed'});
result = struct();
result.model = "acoustoelastic_iop_hgo";
result.frequency_Hz = frequency;
result.phaseVelocity_mps = [nan; 2; 3];
result.validMask = valid;
result.internalAtlasTracking = struct('Used', true, ...
    'TrackingFrequency_Hz', [300, 1000], ...
    'RequestedFrequency_Hz', frequency.', ...
    'InitializationMinFrequency_Hz', 300, ...
    'InitializationNumFrequencyPoints', 50);
result.selectedBranch = selected;
result.quality = struct('firstValidFrequency_Hz', 300, ...
    'lastValidFrequency_Hz', 1000, 'firstMissingFrequency_Hz', nan, ...
    'a0StartFilterPassed', true, 'selectionFallbackUsed', false, ...
    'accepted', true, 'reason', "accepted");
result.diagnostics = struct('explicitBranchPoints', 2, 'interpolatedPoints', 0);
result.constitutiveState = struct('IOP', 15*133.322, 'R', 7.8e-3, ...
    'h', 0.5e-3, 'mu', 158e3, 'k1', 25e3, 'k2', 100, ...
    'sigma', 15598.674, 'lambda', 1.03);
result.directParams = struct('alpha', 170e3, 'beta', 200e3, 'gamma', 140e3, ...
    'rho', 1070, 'rhoF', 1000, 'fluidBulkModulus', 2.2e9);

view = makeView("AcoustoelasticIOPHGO", "atlasA0", result.phaseVelocity_mps, valid, profile);
options = struct('executionProfile', "Balanced", 'computeAcoustoelasticIOPHGO', true);

txt = guiBuildMainDiagnosticsText(view, result, options, setup);
assertContains(txt, "AE identity / requested grid:");
assertContains(txt, "requested below anchor: 1");
assertContains(txt, "missing at/above anchor: 0");
assertContains(txt, "initialization anchor: 300 Hz");
assertContains(txt, "selection fallback used: 0");
assertContains(txt, "prestress sigma");
assertContains(txt, "stretch lambda");
assertContains(txt, "alpha");
assertNotContains(txt, "lambda_Lame");
assertNotContains(txt, "Rayleigh-Lamb seed");
end

function view = makeView(modelName, branchName, Cp, valid, profile)
branch = struct('modelName', string(modelName), 'branchName', string(branchName), ...
    'phaseVelocity', Cp(:), 'diagnostics', struct('valid', logical(valid(:))));
view = struct();
view.branches = branch;
view.metadata = struct('executionProfile', profile, 'elapsedSeconds', 1.25);
view.diagnostics = struct('elapsedSeconds', 1.25);
end

function assertContains(txt, expected)
assert(contains(string(txt), string(expected)), ...
    'Expected diagnostics to contain "%s".', string(expected));
end

function assertNotContains(txt, unexpected)
assert(~contains(string(txt), string(unexpected)), ...
    'Diagnostics should not contain "%s".', string(unexpected));
end
