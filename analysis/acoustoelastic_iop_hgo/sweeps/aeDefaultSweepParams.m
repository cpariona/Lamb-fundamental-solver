function baseParams = aeDefaultSweepParams(varargin)
%AEDEFAULTSWEEPPARAMS Default AE IOP/HGO parameters for reusable sweep workflows.
%
% Name-value overrides are accepted for any field in the returned structure.

baseParams = struct();
baseParams.R = 7.8e-3;
baseParams.thickness = 550e-6;
baseParams.IOP = 15 * 133.322;
baseParams.mu = 64e3;
baseParams.k1 = 50e3;
baseParams.k2 = 200;
baseParams.rho = 1060;
baseParams.rhoF = 1000;
baseParams.fluidBulkModulus = 2.2e9;
baseParams.frequency = logspace(log10(100), log10(35e3), 120);

baseParams = applyNameValueOverrides(baseParams, varargin{:});
end

function s = applyNameValueOverrides(s, varargin)
if isempty(varargin)
    return;
end
if mod(numel(varargin), 2) ~= 0
    error('Name-value overrides must be provided as pairs.');
end
for i = 1:2:numel(varargin)
    name = char(varargin{i});
    s.(name) = varargin{i+1};
end
end
