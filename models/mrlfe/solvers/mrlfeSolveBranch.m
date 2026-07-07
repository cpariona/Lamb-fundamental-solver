function rawResult = mrlfeSolveBranch(problem, configuration)
%MRLFESOLVEBRANCH Dispatch one mRLFE production branch solve.

switch string(configuration.materialRegime)
    case "elasticZeroViscosity"
        rawResult = mrlfeSolveElasticBranch(problem, configuration);
    case "viscoelastic"
        rawResult = mrlfeSolveViscoelasticBranch(problem, configuration);
    otherwise
        error('mrlfe:InvalidMaterialRegime', ...
            'Unsupported mRLFE material regime "%s".', string(configuration.materialRegime));
end
end
