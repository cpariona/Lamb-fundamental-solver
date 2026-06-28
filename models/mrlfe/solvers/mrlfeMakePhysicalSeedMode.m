function seedMode = mrlfeMakePhysicalSeedMode(branchName, frequency, material, geometry, seedModes)
%MRLFEMAKEPHYSICALSEEDMODE Build a cheap branch seed for atlas-based mRLFE solving.
%
% The atlas route should not require a precomputed elastic mRLFE reference branch.
% This helper follows the acoustoelastic start-policy idea: use a physically
% motivated starting scale to define the Cp scan and first-family preference,
% then let the atlas/DP tracker select the branch from local minima.
%
% If a Rayleigh-Lamb seed is already available, it is used because it is computed
% by the caller anyway and is much cheaper than an elastic mRLFE reference. If no
% seed is available, a synthetic Cp curve is constructed from material scales.

if nargin < 5
    seedModes = struct();
end

branchName = string(branchName);
frequency = frequency(:);
omega = 2*pi*frequency;

switch branchName
    case "S0Like"
        seedName = 'S0';
    otherwise
        seedName = 'A0';
end

if isstruct(seedModes) && isfield(seedModes, seedName) && isstruct(seedModes.(seedName))
    seedMode = seedModes.(seedName);
    seedMode.frequency = frequency;
    seedMode.omega = omega;
    if ~isfield(seedMode, 'Cp') || numel(seedMode.Cp) ~= numel(frequency)
        seedMode.Cp = makeSyntheticCp(branchName, frequency, material, geometry);
    else
        seedMode.Cp = seedMode.Cp(:);
    end
    seedMode.k = omega ./ seedMode.Cp(:);
    seedMode.kThickness = seedMode.k .* geometry.thickness;
    seedMode.family = branchName;
    seedMode.name = erase(branchName, "Like");
    seedMode.seedSource = "RayleighLambOrCallerSeed";
    return;
end

cp = makeSyntheticCp(branchName, frequency, material, geometry);
seedMode = struct();
seedMode.name = erase(branchName, "Like");
seedMode.family = branchName;
seedMode.frequency = frequency;
seedMode.omega = omega;
seedMode.Cp = cp;
seedMode.k = omega ./ cp;
seedMode.kThickness = seedMode.k .* geometry.thickness;
seedMode.residual = nan(size(frequency));
seedMode.valid = isfinite(cp) & cp > 0;
seedMode.seedSource = "physicalSynthetic";
end

function cp = makeSyntheticCp(branchName, frequency, material, geometry)
frequency = frequency(:);
ct = getMaterialField(material, 'CT', 1.0);
rho = getMaterialField(material, 'rho', 1000);
E = getMaterialField(material, 'E', nan);
nu = getMaterialField(material, 'nu', nan);
mu = getMaterialField(material, 'mu', rho * ct^2);
if ~isfinite(E) || E <= 0
    E = 2 * mu * (1 + max(min(nu, 0.4999), -0.99));
end
if ~isfinite(nu)
    nu = 0.49;
end

switch string(branchName)
    case "S0Like"
        cp0 = sqrt(max(E / max(rho * (1 - nu^2), eps), eps));
        cp0 = max(cp0, 1.05 * ct);
    otherwise
        h = max(getGeometryField(geometry, 'thickness', 1e-3), eps);
        fScale = max(frequency ./ max(max(frequency), eps), 0);
        cp0 = max(0.35 * ct, 0.25);
        cp = cp0 .* sqrt(max(fScale, 0.02));
        cp = max(cp, 0.20 * ct);
        cp = min(cp, 1.25 * ct);
        return;
end
cp = cp0 * ones(size(frequency));
end

function value = getMaterialField(material, fieldName, defaultValue)
if isstruct(material) && isfield(material, fieldName) && ~isempty(material.(fieldName))
    value = material.(fieldName);
else
    value = defaultValue;
end
end

function value = getGeometryField(geometry, fieldName, defaultValue)
if isstruct(geometry) && isfield(geometry, fieldName) && ~isempty(geometry.(fieldName))
    value = geometry.(fieldName);
else
    value = defaultValue;
end
end
