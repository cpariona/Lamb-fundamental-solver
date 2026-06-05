% Sweep mRLFE shear viscosity and plot Cp and spatial attenuation.
% This example uses the complex-k prototype and fundamental-like branches.

startup();

params = defaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 70;
params.frequencySpacing = "hybrid";

etaSValues = [0, 0.01, 0.05, 0.1, 0.5, 1.0]; % [Pa*s]
etaLValue = 0;                                % [Pa*s]

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFEComplexK = true;

resultsByEtaS = cell(size(etaSValues));

fprintf('\nmRLFE viscosity sweep\n');
fprintf('--------------------\n');

for i = 1:numel(etaSValues)
    options = optionsBase;
    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.solveComplexK = true;
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaL = etaLValue;
    mrlfeParams.etaS = etaSValues(i);
    options.mrlfeParams = mrlfeParams;

    results = computeFundamentalLambModes(params, options);
    resultsByEtaS{i} = results;

    fprintf('etaS = %.4g Pa*s\n', etaSValues(i));
    if isfield(results.models, 'mRLFEComplexK')
        branches = results.models.mRLFEComplexK.branches;
        printBranchSummary(branches, 'A0Like');
        printBranchSummary(branches, 'S0Like');
    end
end

% Cp plot: A0-like.
figure;
hold on;
for i = 1:numel(etaSValues)
    branches = resultsByEtaS{i}.models.mRLFEComplexK.branches;
    if isfield(branches, 'A0Like')
        branch = branches.A0Like;
        valid = getValidMask(branch, 'Cp');
        plot(branch.frequency(valid), branch.Cp(valid), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('etaS = %.3g Pa*s', etaSValues(i)));
    end
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE complex-k A0-like: Cp vs shear viscosity');
legend('Location', 'best');
hold off;

% Spatial attenuation plot: A0-like.
figure;
hold on;
for i = 1:numel(etaSValues)
    branches = resultsByEtaS{i}.models.mRLFEComplexK.branches;
    if isfield(branches, 'A0Like')
        branch = branches.A0Like;
        valid = getValidMask(branch, 'attenuation');
        plot(branch.frequency(valid), branch.attenuation(valid), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('etaS = %.3g Pa*s', etaSValues(i)));
    end
end
grid on;
xlabel('frequency [Hz]');
ylabel('Spatial attenuation Im(k) [1/m]');
title('mRLFE complex-k A0-like: spatial attenuation vs shear viscosity');
legend('Location', 'best');
hold off;

% Cp plot: S0-like.
figure;
hold on;
for i = 1:numel(etaSValues)
    branches = resultsByEtaS{i}.models.mRLFEComplexK.branches;
    if isfield(branches, 'S0Like')
        branch = branches.S0Like;
        valid = getValidMask(branch, 'Cp');
        plot(branch.frequency(valid), branch.Cp(valid), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('etaS = %.3g Pa*s', etaSValues(i)));
    end
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE complex-k S0-like: Cp vs shear viscosity');
legend('Location', 'best');
hold off;

% Spatial attenuation plot: S0-like.
figure;
hold on;
for i = 1:numel(etaSValues)
    branches = resultsByEtaS{i}.models.mRLFEComplexK.branches;
    if isfield(branches, 'S0Like')
        branch = branches.S0Like;
        valid = getValidMask(branch, 'attenuation');
        plot(branch.frequency(valid), branch.attenuation(valid), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('etaS = %.3g Pa*s', etaSValues(i)));
    end
end
grid on;
xlabel('frequency [Hz]');
ylabel('Spatial attenuation Im(k) [1/m]');
title('mRLFE complex-k S0-like: spatial attenuation vs shear viscosity');
legend('Location', 'best');
hold off;

assignin('base', 'mRLFEViscositySweepResults', resultsByEtaS);
assignin('base', 'mRLFEViscositySweepEtaS', etaSValues);
fprintf('\nExported mRLFEViscositySweepResults and mRLFEViscositySweepEtaS to workspace.\n');

function printBranchSummary(branches, branchName)
if ~isfield(branches, branchName)
    fprintf('  %s: not available\n', branchName);
    return;
end
branch = branches.(branchName);
validCp = getValidMask(branch, 'Cp');
validAtt = getValidMask(branch, 'attenuation');
fprintf('  %s Cp valid: %d / %d\n', branchName, sum(validCp), numel(branch.Cp));
if any(validCp)
    fprintf('  %s Cp: %.6g to %.6g m/s\n', branchName, min(branch.Cp(validCp)), max(branch.Cp(validCp)));
end
fprintf('  %s attenuation valid: %d / %d\n', branchName, sum(validAtt), numel(branch.Cp));
if any(validAtt)
    fprintf('  %s attenuation: %.6g to %.6g 1/m\n', branchName, min(branch.attenuation(validAtt)), max(branch.attenuation(validAtt)));
end
if any(isfinite(branch.residual))
    fprintf('  %s max residual: %.3e\n', branchName, max(branch.residual(isfinite(branch.residual))));
end
end

function valid = getValidMask(branch, quantity)
switch quantity
    case 'Cp'
        if isfield(branch, 'validCp')
            valid = branch.validCp;
        else
            valid = branch.valid;
        end
        valid = valid & isfinite(branch.Cp);
    case 'attenuation'
        if isfield(branch, 'validAttenuation')
            valid = branch.validAttenuation;
        else
            valid = false(size(branch.Cp));
        end
        valid = valid & isfinite(branch.attenuation);
    otherwise
        valid = false(size(branch.Cp));
end
end
