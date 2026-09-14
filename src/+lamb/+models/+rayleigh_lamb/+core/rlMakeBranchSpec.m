function spec = rlMakeBranchSpec(modeName, material, geometry)
%RLMAKEBRANCHSPEC Physical identity and dimensionless material coordinates.
spec = struct('name',string(modeName),'CT',material.CT,'nu',material.nu, ...
    'r2',(1-2*material.nu)/(2*(1-material.nu)),'h',geometry.thickness/2);
switch spec.name
    case "A0"
        spec.family = "antisymmetric";
    case "S0"
        spec.family = "symmetric";
    otherwise
        error('Unsupported branch name: %s.',modeName);
end
end
