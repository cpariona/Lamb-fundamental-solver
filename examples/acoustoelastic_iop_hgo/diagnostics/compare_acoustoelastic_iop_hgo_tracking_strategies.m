clear; clc; close all;
startup

% Compare Li 2024 tracking strategies for the same IOP/HGO case.
%
% This diagnostic intentionally keeps all previous strategies available:
%   - globalScan
%   - predictiveContinuation
%   - singularVectorTracking
%   - A0High reference
%   - complex-C determinant continuation as experimental diagnostic
%
% The goal is to avoid selecting a solver based only on visual impression.

params = struct();

% Geometry and pressure.
params.IOP = 15 * 133.322;          % Pa, 15 mmHg
params.R = 7.8e-3;                  % m
params.thickness = 550e-6;          % m

% HGO parameters. Example values for pipeline testing only.
params.mu = 50e3;                   % Pa
params.k1 = 25e3;                   % Pa
params.k2 = 100;                    % dimensionless

% Densities and fluid bulk modulus.
params.rho = 1060;                  % kg/m^3
params.rhoF = 1000;                 % kg/m^3
params.fluidBulkModulus = 2.2e9;    % Pa
params.frequency = linspace(6e3, 35e3, 100);

baseOptions = defaultLi2024AcoustoelasticOptions();
baseOptions.M54_variant = "corrected";
baseOptions.minDimensionlessFrequency = 0.20;
baseOptions.numCpScanPoints = 1800;

results = {};
labels = strings(0, 1);

% A0 low, backward, global scan.
opt = baseOptions;
opt.branch = "A0";
opt.trackingDirection = "backward";
opt.trackingMethod = "globalScan";
results{end+1,1} = solveDispersionIOPHGO_Li2024(params, opt); %#ok<SAGROW>
labels(end+1,1) = "A0 global backward";

% A0 low, backward, predictive continuation.
opt = baseOptions;
opt.branch = "A0";
opt.trackingDirection = "backward";
opt.trackingMethod = "predictiveContinuation";
opt.predictiveWindow = 0.18;
opt.predictionWeight = 8.0;
opt.curvatureWeight = 4.0;
results{end+1,1} = solveDispersionIOPHGO_Li2024(params, opt); %#ok<SAGROW>
labels(end+1,1) = "A0 predictive backward";

% A0 low, backward, singular-vector/MAC tracking.
opt = baseOptions;
opt.branch = "A0";
opt.trackingDirection = "backward";
opt.trackingMethod = "singularVectorTracking";
opt.predictiveWindow = 0.18;
opt.predictionWeight = 8.0;
opt.curvatureWeight = 4.0;
opt.macWeight = 12.0;
results{end+1,1} = solveDispersionIOPHGO_Li2024(params, opt); %#ok<SAGROW>
labels(end+1,1) = "A0 singular-vector backward";
seedResult = results{end};

% A0 high reference, forward. This is not necessarily the A0 flexural branch;
% it is kept as a reference for the surface-wave-like plateau.
opt = baseOptions;
opt.branch = "A0High";
opt.trackingDirection = "forward";
opt.trackingMethod = "globalScan";
results{end+1,1} = solveDispersionIOPHGO_Li2024(params, opt); %#ok<SAGROW>
labels(end+1,1) = "A0High global forward";

% Complex-C determinant continuation, seeded by singular-vector tracking.
complexOptions = baseOptions;
complexOptions.branch = "A0";
complexOptions.trackingDirection = "backward";
complexOptions.complexCInitialImagRatio = -1e-3;
complexOptions.complexCImagLimitRatio = 0.50;
complexOptions.complexCMaxIter = 250;
complexOptions.complexCMaxFunEvals = 900;
complexResult = solveDispersionComplexC_Li2024_Acoustoelastic(seedResult.directParams, complexOptions, seedResult);
results{end+1,1} = complexResult; %#ok<SAGROW>
labels(end+1,1) = "A0 complex-C seeded";

summaryTable = summarizeLi2024TrackingQuality(results, labels, 'Print', true);

figure('Color', 'w');
hold on; grid on;
for i = 1:numel(results)
    [fPlot, cpPlot, valid] = extractPlotCurve(results{i});
    plot(fPlot(valid)/1e3, cpPlot(valid), 'LineWidth', 1.6, 'DisplayName', labels(i));
end
xlabel('frequency [kHz]');
ylabel('Phase velocity [m/s]');
title('Li 2024 IOP/HGO tracking strategy comparison');
legend('Location', 'best');
hold off;

figure('Color', 'w');
bar(categorical(summaryTable.Strategy), summaryTable.QualityScore);
grid on;
ylabel('Diagnostic quality score [-]');
title('Li 2024 tracking quality score: lower is better');
xtickangle(30);

assignin('base', 'Li2024TrackingComparisonResults', results);
assignin('base', 'Li2024TrackingComparisonLabels', labels);
assignin('base', 'Li2024TrackingComparisonSummary', summaryTable);

function [f, cp, valid] = extractPlotCurve(result)
if isfield(result, 'Cp')
    cp = result.Cp(:);
elseif isfield(result, 'CpReal')
    cp = result.CpReal(:);
else
    error('Result must contain Cp or CpReal.');
end
f = result.frequency(:);
if isfield(result, 'validCp')
    valid = logical(result.validCp(:));
elseif isfield(result, 'valid')
    valid = logical(result.valid(:));
else
    valid = isfinite(cp);
end
valid = valid & isfinite(cp) & isfinite(f);
end
