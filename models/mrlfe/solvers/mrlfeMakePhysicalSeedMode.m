function seedMode = mrlfeMakePhysicalSeedMode(branchName, frequency, material, geometry, seedModes)
%MRLFEMAKEPHYSICALSEEDMODE Build a cheap branch seed for atlas-based mRLFE solving.
%
% The atlas route must not require a precomputed etaS = 0 mRLFE branch to solve
% a viscous etaS > 0 branch. It may use Rayleigh-Lamb A0/S0 seeds because those
% branches are already computed cheaply by the caller. If no Rayleigh-Lamb seed is
% available, a synthetic Cp curve is constructed from material scales.

if nargin < 5
    seedModes = struct();
end

branchName = string(branchName);
frequency = frequency(:);
omega = 2*pi*frequency;

switch branchName
    case "S0Like"
        preferredSeedNames = {'S0', 'S0Like'};
    otherwise
        preferredSeedNames = {'A0', 'A0Like'};
end

seedMode = [];
seedSource = "physicalSynthetic";
if isstruct(seedModes)
    for i = 1:numel(preferredSeedNames)
        candidateName = preferredSeedNames{i};
        if isfield(seedModes, candidateName) && isstruct(seedModes.(candidateName))
            candidate = seedModes.(candidateName);
            if isfield(candidate, 'Cp') && numel(candidate.Cp) == numel(frequency)
                seedMode = candidate;
                if endsWith(candidateName, 'Like')
                    seedSource = "mRLFESeedFallback";
                else
                    seedSource = "RayleighLambSeed";
                end
                break;
            end
        end
    end
end

if isempty(seedMode)
    cp = makeSyntheticCp(branchName, frequency, material, geometry);
    seedMode = struct();
    seedMode.residual = nan(size(frequency));
    seedMode.valid = isfinite(cp) & cp > 0;
else
    cp = seedMode.Cp(:);
end

% RL-S0 may bend toward the shear-speed neighborhood at high frequency. For
% S0Like atlas tracking, keep the seed in the extensional neighborhood so the
% Cp scan window does not collapse toward CT and invite a branch switch.
if branchName == "S0Like" && startsWith(seedSource, "RayleighLambSeed")
    physicalCp = makeSyntheticCp(branchName, frequency, material, geometry);
    cp = max(cp(:), physicalCp(:));
    seedSource = "RayleighLambSeedPhysicalFloor";
end

seedMode.name = erase(branchName, "Like");
seedMode.family = branchName;
seedMode.frequency = frequency;
seedMode.omega = omega;
seedMode.Cp = cp(:);
seedMode.k = omega ./ seedMode.Cp(:);
seedMode.kThickness = seedMode.k .* geometry.thickness;
seedMode.seedSource = seedSource;
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
