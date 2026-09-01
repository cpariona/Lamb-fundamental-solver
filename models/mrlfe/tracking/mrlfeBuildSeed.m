function [seedMode, seedResult] = mrlfeBuildSeed(problem, configuration)
%MRLFEBUILDSEED Build an mRLFE branch seed through Rayleigh-Lamb.

branchName = string(configuration.branch);
frequency = problem.frequencySolve_Hz(:);
material = problem.material;
geometry = problem.geometry;
seedOptions = rlDefaultOptions("Fast");
seedOptions.computeA0 = branchName == "A0Like";
seedOptions.computeS0 = branchName == "S0Like";
seedResult = rlComputeFundamentalLambModes(problem.params, seedOptions);
seedModes = seedResult.modes;

omega = 2*pi*frequency;

seedMode = [];
seedSource = "physicalSynthetic";
seedName = char(erase(branchName, "Like"));
if isstruct(seedModes) && isfield(seedModes, seedName) && isstruct(seedModes.(seedName))
    candidate = seedModes.(seedName);
    if isfield(candidate, 'Cp') && numel(candidate.Cp) == numel(frequency)
        seedMode = candidate;
        seedSource = "RayleighLambSeed";
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
