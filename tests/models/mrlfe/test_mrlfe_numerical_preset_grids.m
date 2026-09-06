function test_mrlfe_numerical_preset_grids()
%TEST_MRLFE_NUMERICAL_PRESET_GRIDS Verify production preset grid contracts.

requestedFrequency_Hz = [10 500 1000 2000].';
presetNames = ["fast" "balanced" "robust" "dense"];
expectedSteps_Hz = [50 25 20 10];
expectedLowAnchors_Hz = [10:10:100, 125:25:250, 300:50:500].';

for i = 1:numel(presetNames)
    request = makeRequest(requestedFrequency_Hz, presetNames(i));
    configuration = mrlfeResolveConfiguration(request);
    problem = mrlfeBuildProblem(configuration);
    grid = problem.frequencySolve_Hz(:);
    metadata = problem.frequencyGrid;

    assert(configuration.effectivePreset == presetNames(i), ...
        'The effective numerical preset must match the requested preset.');
    assert(metadata.source == "numericalPreset", ...
        'Production preset grids must report numericalPreset as their source.');
    assert(metadata.presetName == presetNames(i), ...
        'Frequency-grid metadata must report the effective preset name.');
    assert(metadata.configuredStep_Hz == expectedSteps_Hz(i), ...
        'Frequency-grid metadata must report the validated configured step.');
    assert(metadata.transitionFrequency_Hz == 500, ...
        'Production preset grids must transition at 500 Hz.');
    assert(metadata.lowFrequencyPolicy == "fixedLowAnchorsConstantHighStep", ...
        'Production preset grids must report the maintained hybrid-grid policy.');
    assert(grid(1) == requestedFrequency_Hz(1) && ...
        grid(end) == requestedFrequency_Hz(end), ...
        'Production preset grids must include the exact requested bounds.');
    assert(all(diff(grid) > 0), ...
        'Production preset grids must be strictly ascending.');
    assert(all(ismember(expectedLowAnchors_Hz, grid)), ...
        'Production preset grids must contain all maintained low-frequency anchors.');

    high = grid(grid >= 500 & grid < requestedFrequency_Hz(end));
    highStep = diff(high);
    assert(~isempty(highStep) && all(highStep == expectedSteps_Hz(i)), ...
        'Production preset grids must use the validated constant step above 500 Hz.');
end

override_Hz = [10 100 500 777 1200 2000].';
request = makeRequest(requestedFrequency_Hz, "robust");
request.numerics.frequencySolveOverride_Hz = override_Hz;
configuration = mrlfeResolveConfiguration(request);
problem = mrlfeBuildProblem(configuration);
assert(isequal(problem.frequencySolve_Hz(:), override_Hz), ...
    'frequencySolveOverride_Hz must take exact precedence over preset grids.');
assert(problem.frequencyGrid.source == "diagnosticOverride", ...
    'An exact override must be identified as diagnosticOverride.');
assert(isnan(problem.frequencyGrid.configuredStep_Hz), ...
    'Override metadata must not report a preset step as the active grid step.');

request = makeRequest(requestedFrequency_Hz, "fast");
result = mrlfeSolve(request);
assert(isequal(result.frequency_Hz(:), requestedFrequency_Hz), ...
    'Numerical preset grids must not change the public requested-frequency output grid.');

didReject = false;
try
    mrlfeGetNumericalPreset("unsupported");
catch ME
    didReject = strcmp(ME.identifier, 'mrlfe:InvalidNumericalPreset');
end
assert(didReject, 'Unsupported numerical preset names must be rejected.');

fprintf(['test_mrlfe_numerical_preset_grids passed. Production presets use ' ...
    'validated hybrid solve grids while preserving override and public-output contracts.\n']);
end

function request = makeRequest(frequency_Hz, presetName)
request = struct();
request.branch = "A0Like";
request.frequency_Hz = frequency_Hz;
request.material = struct( ...
    'mu_Pa', 75e3, ...
    'etaS_Pas', 0, ...
    'rho_kgm3', 1070, ...
    'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', presetName);
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");
end
