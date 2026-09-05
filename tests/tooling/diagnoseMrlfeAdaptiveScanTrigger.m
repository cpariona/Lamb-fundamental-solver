% TEMPORARY_DIAGNOSTIC
function detail = diagnoseMrlfeAdaptiveScanTrigger(varargin)
%DIAGNOSEMRLFEADAPTIVESCANTRIGGER Inspect signals before coarse/dense divergence.

parser = inputParser;
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

request = buildRequest();
coarse = runCase(request, 100);
dense = runCase(request, 260);

bc = coarse.branchSolve;
bd = dense.branchSolve;
if ~isequal(bc.frequency(:), bd.frequency(:))
    error('mrlfe:DiagnosticGridMismatch', 'Coarse and dense solve grids differ.');
end

f = bc.frequency(:);
cpCoarse = bc.Cp(:);
cpDense = bd.Cp(:);
validCoarse = logical(bc.validCp(:));
validDense = logical(bd.validCp(:));
typeCoarse = string(bc.candidateType(:));
typeDense = string(bd.candidateType(:));
center = bc.adaptiveCenterCp(:);
window = bc.adaptiveWindowUsed(:);
numCandidates = bc.adaptiveCandidateCount(:);
residual = bc.residual(:);
score = bc.score(:);

deltaCp = cpCoarse - cpDense;
finiteBoth = isfinite(cpCoarse) & isfinite(cpDense);
relativeDelta = nan(size(f));
relativeDelta(finiteBoth) = abs(deltaCp(finiteBoth)) ./ max(abs(cpDense(finiteBoth)), eps);

firstWindow = bc.dpOptions.windows(1);
residualTolerance = bc.dpOptions.residualTolerance;
predictionDeviation = abs(cpCoarse - center) ./ max(abs(center), eps);

triggerFallback = typeCoarse == "valleyFallback";
triggerInvalid = ~validCoarse;
triggerExpandedWindow = isfinite(window) & window > firstWindow + 10*eps(firstWindow);
triggerLowCandidateCount = numCandidates <= 1;
triggerResidualNearLimit = isfinite(residual) & residual > 0.10 * residualTolerance;
triggerPredictionDeviation = isfinite(predictionDeviation) & predictionDeviation > 0.05;

cpMismatch = finiteBoth & abs(deltaCp) > 1e-5;
maskMismatch = validCoarse ~= validDense;
typeMismatch = typeCoarse ~= typeDense;
meaningfulDifference = cpMismatch | maskMismatch | typeMismatch;
firstDifference = find(meaningfulDifference, 1, 'first');

detail = table(f, cpCoarse, cpDense, deltaCp, relativeDelta, ...
    validCoarse, validDense, typeCoarse, typeDense, center, window, ...
    numCandidates, residual, score, predictionDeviation, ...
    triggerFallback, triggerInvalid, triggerExpandedWindow, ...
    triggerLowCandidateCount, triggerResidualNearLimit, triggerPredictionDeviation, ...
    cpMismatch, maskMismatch, typeMismatch, meaningfulDifference, ...
    'VariableNames', {'Frequency_Hz','CpCoarse_mps','CpDense_mps','DeltaCp_mps', ...
    'RelativeDelta','ValidCoarse','ValidDense','TypeCoarse','TypeDense', ...
    'CoarseCenter_mps','CoarseWindow','CoarseCandidateCount','CoarseResidual', ...
    'CoarseScore','CoarsePredictionDeviation','TriggerFallback','TriggerInvalid', ...
    'TriggerExpandedWindow','TriggerLowCandidateCount','TriggerResidualNearLimit', ...
    'TriggerPredictionDeviation','CpMismatch','MaskMismatch','TypeMismatch', ...
    'MeaningfulDifference'});

fprintf('\nmRLFE adaptive scan trigger diagnostic\n');
fprintf('======================================\n');
if isempty(firstDifference)
    fprintf('No coarse/dense difference detected.\n');
else
    fprintf('First difference: index %d, %.0f Hz\n', firstDifference, f(firstDifference));
    lo = max(1, firstDifference-3);
    hi = min(height(detail), firstDifference+3);
    disp(detail(lo:hi, {'Frequency_Hz','CpCoarse_mps','CpDense_mps','DeltaCp_mps', ...
        'ValidCoarse','ValidDense','TypeCoarse','TypeDense','CoarseWindow', ...
        'CoarseCandidateCount','CoarseResidual','CoarsePredictionDeviation', ...
        'TriggerFallback','TriggerInvalid','TriggerExpandedWindow', ...
        'TriggerResidualNearLimit','TriggerPredictionDeviation'}));
end

fprintf('\nTrigger counts before/at first difference\n');
if isempty(firstDifference)
    stopIndex = height(detail);
else
    stopIndex = firstDifference;
end
fprintf('Fallback: %d\n', nnz(triggerFallback(1:stopIndex)));
fprintf('Invalid: %d\n', nnz(triggerInvalid(1:stopIndex)));
fprintf('Expanded window: %d\n', nnz(triggerExpandedWindow(1:stopIndex)));
fprintf('Low candidate count: %d\n', nnz(triggerLowCandidateCount(1:stopIndex)));
fprintf('Residual near limit: %d\n', nnz(triggerResidualNearLimit(1:stopIndex)));
fprintf('Prediction deviation > 5%%: %d\n', nnz(triggerPredictionDeviation(1:stopIndex)));

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'adaptive_scan_trigger');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(detail, fullfile(outputFolder, 'mrlfe_adaptive_scan_trigger.csv'));
    fprintf('Saved Results/mrlfe/diagnostics/adaptive_scan_trigger/mrlfe_adaptive_scan_trigger.csv\n');
end
end

function raw = runCase(request, scanPoints)
configuration = mrlfeResolveConfiguration(request);
configuration.internalOptions.trackerCpScanPoints = scanPoints;
problem = mrlfeBuildProblem(configuration);
raw = mrlfeSolveBranch(problem, configuration);
end

function request = buildRequest()
defaults = mrlfeDefaultParameters();
publicOptions = mrlfeDefaultOptions();
request = struct();
request.branch = "A0Like";
request.frequency_Hz = linspace(1000,12000,20).';
request.material = struct('mu_Pa', 50e3, 'etaS_Pas', 0.10, ...
    'rho_kgm3', defaults.rho_kgm3, 'nu', defaults.nu);
request.geometry = struct('thickness_m', defaults.thickness_m);
request.fluid = struct('density_kgm3', defaults.fluidDensity_kgm3, ...
    'soundSpeed_mps', defaults.fluidSoundSpeed_mps);
request.numerics = struct('preset', "fast");
request.selection = publicOptions.selection;
request.termination = struct('policy', publicOptions.termination.A0Like);
request.fallback = publicOptions.fallback;
end

function root = findRepositoryRoot(anchorFile)
folder = fileparts(anchorFile);
while true
    if isfile(fullfile(folder, 'startup.m'))
        root = folder;
        return
    end
    parent = fileparts(folder);
    if strcmp(parent, folder)
        error('mrlfe:RepositoryRootNotFound', 'Could not locate repository root.');
    end
    folder = parent;
end
end
