function [objectiveMap, yGrid, cGrid, cShear] = aeBuildAtlas(params, options)
%AEBUILDATLAS Build the AE objective landscape on the configured atlas grid.

frequency = params.frequency(:).';
cShear = sqrt(params.alpha / params.rho);
yGrid = logspace(log10(options.atlasYMin), log10(options.atlasYMax), options.atlasNumYPoints);
cGrid = yGrid(:) * cShear;

cpState = cell(numel(cGrid), 1);
for j = 1:numel(cGrid)
    cpState{j} = aeComputeAcoustoelasticCpState(params.alpha, params.beta, params.gamma, ...
        params.rho, params.rhoF, params.fluidBulkModulus, cGrid(j));
end

objectiveMap = nan(numel(cGrid), numel(frequency));
for k = 1:numel(frequency)
    f = frequency(k);
    for j = 1:numel(cGrid)
        objectiveMap(j,k) = objectiveAcoustoelasticResidual(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, ...
            f, cGrid(j), options, cpState{j});
    end
end
end
