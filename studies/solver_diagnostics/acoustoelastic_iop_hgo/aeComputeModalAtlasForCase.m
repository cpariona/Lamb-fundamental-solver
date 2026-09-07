function atlas = aeComputeModalAtlasForCase(params, options, yGrid, topN, maxLogYJump, minBranchPoints, mode)
%AECOMPUTEMODALATLASFORCASE Build an AE modal-atlas objective map and branch table.
%
% This helper centralizes the repeated modal-atlas logic used by the standard
% and low-frequency acoustoelastic IOP/HGO diagnostics. It computes the
% objective map over a dimensionless phase-velocity grid,
%
%   y = Cp / sqrt(alpha/rho),
%
% extracts the top local minima at each frequency, and links local minima into
% persistent branch families.
%
% Inputs:
%   params.alpha, beta, gamma, thickness, rho, rhoF, fluidBulkModulus, frequency
%   options          options passed to lamb.models.acoustoelastic_iop_hgo.core.objectiveAcoustoelasticResidual
%   yGrid            dimensionless Cp grid
%   topN             max local minima retained per frequency
%   maxLogYJump      max log10(y) jump for branch linking
%   minBranchPoints  minimum points required to retain a branch
%   mode             "standard" or "lowFrequency" branch summary fields

if nargin < 7 || strlength(string(mode)) == 0
    mode = "standard";
end
mode = string(mode);

freq = params.frequency(:).';
cShear = sqrt(params.alpha / params.rho);
cGrid = yGrid(:) * cShear;
objectiveMap = nan(numel(yGrid), numel(freq));
minimaRows = [];

for k = 1:numel(freq)
    f = freq(k);
    for j = 1:numel(cGrid)
        objectiveMap(j, k) = lamb.models.acoustoelastic_iop_hgo.core.objectiveAcoustoelasticResidual(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(j), options);
    end

    minima = lamb.models.acoustoelastic_iop_hgo.tracking.aeFindAtlasLocalMinima( ...
        cGrid, objectiveMap(:, k), cShear, topN);
    for m = 1:height(minima)
        row = struct();
        row.Frequency_Hz = f;
        row.Frequency_kHz = f / 1e3;
        row.MinRank = m;
        row.Cp_mps = minima.Cp_mps(m);
        row.y = minima.y(m);
        row.log10y = log10(minima.y(m));
        row.Objective = minima.Objective(m);
        row.DepthRelativeToMedian = minima.DepthRelativeToMedian(m);
        row.DepthRelativeToDeepest = minima.DepthRelativeToDeepest(m);
        row.SpacingToNearestLogY = minima.SpacingToNearestLogY(m);
        row.BranchID = nan;
        minimaRows = [minimaRows; row]; %#ok<AGROW>
    end
end

if isempty(minimaRows)
    minimaTable = table();
    branchTable = table();
else
    minimaTable = struct2table(minimaRows);
    trackingOptions = struct( ...
        'atlasMaxLogYJump', maxLogYJump, ...
        'atlasSplitOnLargeCpJump', false, ...
        'atlasMaxRelativeCpJump', inf, ...
        'atlasMinBranchPoints', minBranchPoints);
    [minimaTable, branchTable] = ...
        lamb.models.acoustoelastic_iop_hgo.tracking.aeLinkAtlasBranches( ...
        minimaTable, trackingOptions);
    if isempty(branchTable)
        retainedIDs = [];
    else
        retainedIDs = branchTable.BranchID;
    end
    minimaTable.BranchID(~ismember(minimaTable.BranchID, retainedIDs)) = nan;
end

atlas = struct();
atlas.frequency = freq;
atlas.yGrid = yGrid(:);
atlas.cGrid = cGrid(:);
atlas.objectiveMap = objectiveMap;
atlas.minimaTable = minimaTable;
atlas.branchTable = branchTable;
atlas.options = options;
atlas.cShear = cShear;
atlas.branchSummaryMode = mode;
end
