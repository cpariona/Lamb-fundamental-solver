% Run the complex-k mRLFE plotting prototype.
% This model is seeded from Rayleigh-Lamb A0/S0 branches and computes only
% A0-like and S0-like fundamental branches.

startup();

params = defaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 80;
params.frequencySpacing = "hybrid";

options = defaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFEComplexK = true;

mrlfeParams = defaultMRLFEParams();
mrlfeParams.solveComplexK = true;
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaL = 0;
mrlfeParams.etaS = 0;
options.mrlfeParams = mrlfeParams;

results = computeFundamentalLambModes(params, options);

figure;
hold on;
plot(results.modes.A0.frequency, results.modes.A0.Cp, '-', 'LineWidth', 2, 'DisplayName', 'A0');
plot(results.modes.S0.frequency, results.modes.S0.Cp, '-', 'LineWidth', 2, 'DisplayName', 'S0');

if isfield(results.models, 'mRLFEComplexK')
    branches = results.models.mRLFEComplexK.branches;
    if isfield(branches, 'A0Like')
        plot(branches.A0Like.frequency, branches.A0Like.Cp, '-.', 'LineWidth', 2, 'DisplayName', 'complex-k A0-like');
    end
    if isfield(branches, 'S0Like')
        plot(branches.S0Like.frequency, branches.S0Like.Cp, '-.', 'LineWidth', 2, 'DisplayName', 'complex-k S0-like');
    end
end

grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE complex-k prototype');
legend('Location', 'best');
hold off;

fprintf('\nmRLFE complex-k prototype summary\n');
fprintf('--------------------------------\n');
if isfield(results.models, 'mRLFEComplexK')
    branchNames = fieldnames(results.models.mRLFEComplexK.branches);
    for i = 1:numel(branchNames)
        name = branchNames{i};
        branch = results.models.mRLFEComplexK.branches.(name);
        fprintf('%s valid points: %d / %d\n', name, sum(branch.valid), numel(branch.valid));
        if any(branch.valid)
            fprintf('%s Cp range: %.6g to %.6g m/s\n', name, min(branch.Cp(branch.valid)), max(branch.Cp(branch.valid)));
            fprintf('%s attenuation range: %.6g to %.6g 1/m\n', name, min(branch.attenuation(branch.valid)), max(branch.attenuation(branch.valid)));
        end
        if any(isfinite(branch.residual))
            fprintf('%s max residual: %.3e\n', name, max(branch.residual(isfinite(branch.residual))));
        end
    end
else
    fprintf('No mRLFE complex-k result was computed.\n');
end
