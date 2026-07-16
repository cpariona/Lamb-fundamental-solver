function [summaryTable, comparison] = compareMRLFETrackingStrategies(params, options, varargin)
%COMPAREMRLFETRACKINGSTRATEGIES Compare maintained mRLFE tracking strategies.
%
% [summaryTable, comparison] = compareMRLFETrackingStrategies(params, options)
% runs the same mRLFE real-k branch with direct tracking and internal-grid
% tracking, then summarizes both with summarizeMRLFETrackingQuality.
%
% This is a maintained analysis helper. It does not create files or figures.

p = inputParser;
addParameter(p, 'BranchName', "A0Like", @(x)ischar(x) || isstring(x));
addParameter(p, 'EtaS', [], @(x)isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0));
addParameter(p, 'Print', true, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});

branchName = string(p.Results.BranchName);
etaS = p.Results.EtaS;

if nargin < 1 || isempty(params)
    params = rlDefaultParams();
end
if nargin < 2 || isempty(options)
    options = rlDefaultOptions("Fast");
end

baseOptions = configureBaseMRLFEOptions(options, branchName, etaS);
etaS = baseOptions.mrlfeParams.etaS;

elasticReference = [];
if etaS > 0
    elasticOptions = baseOptions;
    elasticOptions.mrlfeParams.etaS = 0;
    elasticOptions.mrlfeUseInternalTrackingGrid = false;
    elasticOptions.mrlfeUseInternalTrackingGridForViscousRealK = false;
    elasticResult = rlComputeFundamentalLambModes(params, elasticOptions);
    elasticReference = elasticResult.models.mRLFERealK;
end

directOptions = baseOptions;
directOptions.mrlfeUseInternalTrackingGrid = false;
directOptions.mrlfeUseInternalTrackingGridForViscousRealK = false;
if ~isempty(elasticReference)
    directOptions.mrlfeElasticReferenceResult = elasticReference;
end

gridOptions = baseOptions;
gridOptions.mrlfeUseInternalTrackingGrid = true;
gridOptions.mrlfeUseInternalTrackingGridForViscousRealK = true;
if ~isempty(elasticReference)
    gridOptions.mrlfeElasticReferenceResult = elasticReference;
end

directRaw = rlComputeFundamentalLambModes(params, directOptions);
gridRaw = rlComputeFundamentalLambModes(params, gridOptions);

directModel = directRaw.models.mRLFERealK;
gridModel = gridRaw.models.mRLFERealK;

summaryTable = summarizeMRLFETrackingQuality({directModel, gridModel}, ...
    ["direct", "internalGrid"], ...
    'BranchName', branchName, ...
    'Print', false);

comparison = struct();
comparison.params = params;
comparison.branchName = branchName;
comparison.etaS = etaS;
comparison.directOptions = directOptions;
comparison.internalGridOptions = gridOptions;
comparison.directRaw = directRaw;
comparison.internalGridRaw = gridRaw;
comparison.direct = directModel;
comparison.internalGrid = gridModel;
comparison.summaryTable = summaryTable;

if p.Results.Print
    disp(summaryTable);
end
end

function options = configureBaseMRLFEOptions(options, branchName, etaS)
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.computeMRLFE = false;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = true;
options.computeMRLFEViscoRealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = branchName == "A0Like";
options.mrlfeComputeS0Like = branchName == "S0Like";

if ~(options.mrlfeComputeA0Like || options.mrlfeComputeS0Like)
    error('compareMRLFETrackingStrategies:UnsupportedBranch', ...
        'Unsupported branchName "%s". Use "A0Like" or "S0Like".', branchName);
end

if ~isfield(options, 'mrlfeParams') || isempty(options.mrlfeParams)
    options.mrlfeParams = mrlfeDefaultInternalParameters();
end
if ~isempty(etaS)
    options.mrlfeParams.etaS = etaS;
elseif ~isfield(options.mrlfeParams, 'etaS') || isempty(options.mrlfeParams.etaS)
    options.mrlfeParams.etaS = 0;
end
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeParams.solveComplexK = false;
end
