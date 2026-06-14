% Run the real-k elastic mRLFE plotting prototype.
% This model is seeded from the Rayleigh-Lamb A0/S0 branches and computes
% only A0-like and S0-like fundamental branches.

startup();

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "hybrid";

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFE = true;

results = rlComputeFundamentalLambModes(params, options);

figure;
hold on;
plot(results.modes.A0.frequency, results.modes.A0.Cp, '-', 'LineWidth', 2, 'DisplayName', 'A0');
plot(results.modes.S0.frequency, results.modes.S0.Cp, '-', 'LineWidth', 2, 'DisplayName', 'S0');

if isfield(results.models, 'mRLFE')
    branches = results.models.mRLFE.branches;
    if isfield(branches, 'A0Like')
        plot(branches.A0Like.frequency, branches.A0Like.Cp, ':', 'LineWidth', 2, 'DisplayName', 'mRLFE A0-like');
    end
    if isfield(branches, 'S0Like')
        plot(branches.S0Like.frequency, branches.S0Like.Cp, ':', 'LineWidth', 2, 'DisplayName', 'mRLFE S0-like');
    end
end

grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE real-k elastic prototype');
legend('Location', 'best');
hold off;

fprintf('\nmRLFE prototype summary\n');
fprintf('-----------------------\n');
if isfield(results.models, 'mRLFE')
    branchNames = fieldnames(results.models.mRLFE.branches);
    for i = 1:numel(branchNames)
        name = branchNames{i};
        branch = results.models.mRLFE.branches.(name);
        fprintf('%s valid points: %d / %d\n', name, sum(branch.valid), numel(branch.valid));
        if any(branch.valid)
            fprintf('%s Cp range: %.6g to %.6g m/s\n', name, min(branch.Cp(branch.valid)), max(branch.Cp(branch.valid)));
        end
        if any(isfinite(branch.residual))
            fprintf('%s max residual: %.3e\n', name, max(branch.residual(isfinite(branch.residual))));
        end
    end
else
    fprintf('No mRLFE result was computed.\n');
end
