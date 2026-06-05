% Diagnose A0-like mRLFE Han real-k residual under shear viscosity.
% This script plots the real-k residual landscape versus trial Cp for several
% frequencies and etaS values. It is meant to identify whether A0 tracking
% shows branch switching or valley weakening at high frequency.
%
% Model used here:
%   lambda real
%   muStar = mu + 1i*omega*etaS
%   k real
%
% The plotted residual is sigma_min(M)/sigma_max(M).

startup();

params = defaultParams();
params.fmin = 500;
params.fmax = 30000;
params.numFrequencyPoints = 160;
params.frequencySpacing = "hybrid";

% Frequencies selected to inspect the A0-like residual landscape.
frequenciesToInspect = [2000, 8000, 16000, 30000]; % [Hz]

% Viscosities to inspect.
etaSValues = [0, 0.1, 0.3, 0.5, 0.7, 1.0]; % [Pa*s]

% Cp scan range for A0-like. Expand if the minimum is near an edge.
CpScan = linspace(0.5, 30, 6000); % [m/s]

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFEHanViscoRealK = true;

material = computeMaterial(params);
geometryFull = computeGeometry(params);
geometry = rmfield(geometryFull, 'halfThickness');

resultsByEtaS = cell(size(etaSValues));

fprintf('\nA0-like mRLFE Han real-k residual diagnostic\n');
fprintf('--------------------------------------------\n');
fprintf('Cp scan range: %.3g to %.3g m/s (%d samples)\n', min(CpScan), max(CpScan), numel(CpScan));

for iEta = 1:numel(etaSValues)
    options = optionsBase;
    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = etaSValues(iEta);
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    options.mrlfeParams = mrlfeParams;

    resultsByEtaS{iEta} = computeFundamentalLambModes(params, options);

    fprintf('\netaS = %.4g Pa*s\n', etaSValues(iEta));
    branch = resultsByEtaS{iEta}.models.mRLFEHanViscoRealK.branches.A0Like;
    valid = getValidCp(branch);
    fprintf('  tracked A0Like valid Cp points: %d / %d\n', sum(valid), numel(valid));
    if any(valid)
        fprintf('  tracked A0Like Cp range: %.6g to %.6g m/s\n', min(branch.Cp(valid)), max(branch.Cp(valid)));
    end
end

% One figure per frequency. Each figure overlays residual curves for etaS.
for iFreq = 1:numel(frequenciesToInspect)
    f = frequenciesToInspect(iFreq);
    omega = 2*pi*f;

    figure;
    hold on;
    minTable = zeros(numel(etaSValues), 4); % etaS, CpMin, residualMin, trackedCp

    for iEta = 1:numel(etaSValues)
        etaS = etaSValues(iEta);
        mrlfeParams = defaultMRLFEParams();
        mrlfeParams.fluidDensity = 1000;
        mrlfeParams.fluidSoundSpeed = 1500;
        mrlfeParams.etaS = etaS;
        mrlfeParams.etaL = 0;
        mrlfeParams.useComplexLambda = false;

        residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams);
        semilogy(CpScan, residual, 'LineWidth', 1.3, ...
            'DisplayName', sprintf('etaS = %.3g Pa*s', etaS));

        [resMin, idxMin] = min(residual);
        cpMin = CpScan(idxMin);
        trackedCp = interpolateTrackedCp(resultsByEtaS{iEta}, f);
        minTable(iEta,:) = [etaS, cpMin, resMin, trackedCp];

        if isfinite(trackedCp)
            trackedResidual = interp1(CpScan, residual, trackedCp, 'linear', nan);
            semilogy(trackedCp, trackedResidual, 'o', 'MarkerSize', 6, ...
                'HandleVisibility', 'off');
        end
    end

    grid on;
    xlabel('Trial phase velocity Cp [m/s]');
    ylabel('mRLFE residual sigma_{min}(M)/sigma_{max}(M)');
    title(sprintf('A0-like residual landscape at f = %.0f Hz', f));
    legend('Location', 'best');
    hold off;

    fprintf('\nFrequency %.0f Hz\n', f);
    fprintf('  etaS [Pa*s] | global-min Cp [m/s] | min residual | tracked Cp [m/s]\n');
    for iEta = 1:size(minTable,1)
        fprintf('  %10.4g | %19.6g | %12.3e | %16.6g\n', ...
            minTable(iEta,1), minTable(iEta,2), minTable(iEta,3), minTable(iEta,4));
    end
end

% Residual heatmaps for selected etaS values.
etaSMapValues = [0, 0.5, 1.0];
fMap = linspace(500, 30000, 120);
CpMap = linspace(0.5, 30, 1200);

for iEta = 1:numel(etaSMapValues)
    etaS = etaSMapValues(iEta);
    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = etaS;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    Rmap = nan(numel(CpMap), numel(fMap));
    for j = 1:numel(fMap)
        Rmap(:,j) = computeResidualVsCp(CpMap, 2*pi*fMap(j), material, geometry, mrlfeParams).';
    end

    figure;
    imagesc(fMap, CpMap, log10(Rmap));
    set(gca, 'YDir', 'normal');
    colorbar;
    xlabel('frequency [Hz]');
    ylabel('Trial phase velocity Cp [m/s]');
    title(sprintf('log10 residual map: A0-like, etaS = %.3g Pa*s', etaS));
    hold on;
    idx = find(abs(etaSValues - etaS) < 1e-12, 1);
    if ~isempty(idx)
        branch = resultsByEtaS{idx}.models.mRLFEHanViscoRealK.branches.A0Like;
        valid = getValidCp(branch);
        plot(branch.frequency(valid), branch.Cp(valid), 'w.', 'MarkerSize', 8, 'DisplayName', 'tracked valid Cp');
    end
    hold off;
end

assignin('base', 'mRLFEA0ResidualDiagnosticResults', resultsByEtaS);
assignin('base', 'mRLFEA0ResidualDiagnosticEtaS', etaSValues);
assignin('base', 'mRLFEA0ResidualDiagnosticCpScan', CpScan);
fprintf('\nExported A0 diagnostic variables to workspace.\n');

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    Cp = CpScan(i);
    if Cp <= 0 || ~isfinite(Cp)
        continue;
    end
    k = omega / Cp;
    residual(i) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
end
end

function trackedCp = interpolateTrackedCp(results, frequency)
trackedCp = nan;
if ~isfield(results.models, 'mRLFEHanViscoRealK')
    return;
end
branches = results.models.mRLFEHanViscoRealK.branches;
if ~isfield(branches, 'A0Like')
    return;
end
branch = branches.A0Like;
valid = getValidCp(branch);
if sum(valid) < 2
    return;
end
trackedCp = interp1(branch.frequency(valid), branch.Cp(valid), frequency, 'linear', nan);
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid & isfinite(branch.Cp);
end
