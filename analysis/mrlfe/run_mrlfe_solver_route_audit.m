clear; clc; close all;
startup

% Quick characterization matrix:
%   A0Like and S0Like
%   etaS = 0 and etaS > 0
%   Main GUI, FitTool fast atlas, unified atlas, and legacy compute routes
%
% Outputs are written under the system temporary folder by default.

audit = auditMRLFESolverRoutes('Mode', "quick", 'WriteOutputs', true);

assignin('base', 'MRLFESolverRouteAudit', audit);

fprintf('\nThe audit structure is available in the base workspace as:\n');
fprintf('  MRLFESolverRouteAudit\n');
fprintf('\nFor the wider parameter matrix, run:\n');
fprintf('  auditMRLFESolverRoutes(''Mode'', "full");\n');
