function branchSpec = makeBranchSpec(modeName, material, geometry)
% Build branch-specific numerical settings and physical initial guesses.

modeName = string(modeName);

branchSpec = struct();
branchSpec.name = modeName;
branchSpec.initialCpGuess = [];
branchSpec.initialSearchRange = [];
branchSpec.preferLowestCp = false;
branchSpec.description = "";

switch modeName
    case "A0"
        branchSpec.family = "antisymmetric";
        branchSpec.preferLowestCp = true;
        branchSpec.description = "fundamental antisymmetric flexural branch";
        branchSpec.initialCpGuess = estimateA0InitialCp(material, geometry);
        if isfinite(branchSpec.initialCpGuess) && branchSpec.initialCpGuess > 0
            branchSpec.initialSearchRange = [0.20, 5.00] * branchSpec.initialCpGuess;
        end

    case "S0"
        branchSpec.family = "symmetric";
        branchSpec.description = "fundamental symmetric extensional branch";
        branchSpec.initialCpGuess = sqrt(material.E / (material.rho * (1 - material.nu^2)));
        if isfinite(branchSpec.initialCpGuess) && branchSpec.initialCpGuess > 0
            branchSpec.initialSearchRange = [0.35, 1.75] * branchSpec.initialCpGuess;
        end

    otherwise
        error('Unsupported branch name: %s.', modeName);
end
end

function Cp0 = estimateA0InitialCp(material, geometry)
% Low-frequency flexural estimate for the first A0 point.

frequency0 = [];
if isfield(geometry, 'frequency0')
    frequency0 = geometry.frequency0;
end

if isempty(frequency0) || ~isfinite(frequency0) || frequency0 <= 0
    Cp0 = nan;
    return;
end

thickness = geometry.thickness;
omega0 = 2 * pi * frequency0;
Dplate = material.E * thickness^3 / (12 * (1 - material.nu^2));
rhoArea = material.rho * thickness;
Cp0 = sqrt(omega0) * (Dplate / rhoArea)^(1/4);
end
