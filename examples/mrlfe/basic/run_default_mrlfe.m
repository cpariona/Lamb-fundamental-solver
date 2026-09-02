% Run the default real-k elastic mRLFE example through the public API.

startup();

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "hybrid";
frequency_Hz = rlBuildFrequencyVector(params);

results = struct();
for branchName = ["A0Like", "S0Like"]
    options = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0);
    request = mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
    results.(char(branchName)) = mrlfeSolve(request);
end

figure;
hold on;
plotBranch(results.A0Like, 'mRLFE A0-like');
plotBranch(results.S0Like, 'mRLFE S0-like');
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('Default mRLFE real-k elastic example');
legend('Location', 'best');
hold off;

fprintf('\nDefault mRLFE summary\n');
fprintf('---------------------\n');
for branchName = ["A0Like", "S0Like"]
    result = results.(char(branchName));
    fprintf('%s valid points: %d / %d\n', branchName, ...
        nnz(result.validMask), numel(result.validMask));
    if any(result.validMask)
        cp = result.phaseVelocity_mps(result.validMask);
        fprintf('%s Cp range: %.6g to %.6g m/s\n', branchName, min(cp), max(cp));
    end
end

assignin('base', 'MRLFEDefaultResults', results);

function plotBranch(result, labelText)
cp = result.phaseVelocity_mps;
cp(~result.validMask) = nan;
plot(result.frequency_Hz, cp, ':', 'LineWidth', 2, 'DisplayName', labelText);
end
