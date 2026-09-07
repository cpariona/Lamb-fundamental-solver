function test_mrlfe_fit_frequency_grid_contract()
%TEST_MRLFE_FIT_FREQUENCY_GRID_CONTRACT Validate optimized fitting grid construction.

fprintf('\nRunning mRLFE optimized fit-grid contract test...\n');
fprintf('-------------------------------------------------\n');

frequencyRequested_Hz = [1000; 1800; 3100; 5000; 8000];
forwardModel = struct('gridPolicy', "fitOptimized", ...
    'minimumPointCount', 12, 'maximumPointCount', 40, 'maximumStep_Hz', 250);
[frequencySolve_Hz, metadata] = lamb.fitting.mrlfe.mrlfeBuildFitFrequencyGrid(frequencyRequested_Hz, forwardModel);

assert(all(ismember(frequencyRequested_Hz, frequencySolve_Hz)), ...
    'Optimized fit grid must preserve every requested frequency.');
assert(all(diff(frequencySolve_Hz) > 0), ...
    'Optimized fit grid must be strictly ascending.');
assert(numel(frequencySolve_Hz) >= 12, ...
    'Optimized fit grid must satisfy minimumPointCount.');
assert(numel(frequencySolve_Hz) <= 40, ...
    'Optimized fit grid must satisfy maximumPointCount when requested count is lower.');
assert(metadata.gridPolicy == "fitOptimized", ...
    'Optimized fit-grid metadata policy mismatch.');
assert(metadata.preservedRequestedFrequencies, ...
    'Optimized fit-grid metadata must confirm requested-frequency preservation.');

manyRequested_Hz = linspace(1000, 8000, 55).';
[manySolve_Hz, manyMetadata] = lamb.fitting.mrlfe.mrlfeBuildFitFrequencyGrid(manyRequested_Hz, forwardModel);
assert(all(ismember(manyRequested_Hz, manySolve_Hz)), ...
    'Requested frequencies may not be discarded when their count exceeds maximumPointCount.');
assert(numel(manySolve_Hz) >= numel(manyRequested_Hz), ...
    'Grid count must expand when requested frequencies exceed maximumPointCount.');
assert(manyMetadata.preservedRequestedFrequencies, ...
    'Large requested grid preservation metadata mismatch.');

fprintf('mRLFE optimized fit-grid contract test passed.\n');
end
