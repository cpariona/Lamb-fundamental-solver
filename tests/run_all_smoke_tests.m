clear; clc;
startup

% Run all maintained smoke and consistency tests.
%
% This script is intended as the first validation step after refactors,
% folder reorganizations, or path changes. It should remain lightweight and
% avoid generating figures.

fprintf('\nRunning Lamb Fundamental Solver smoke tests...\n');
fprintf('---------------------------------------------\n');


%% Rayleigh-Lamb legacy compatibility wrapper path checks
fprintf('\nChecking Rayleigh-Lamb legacy compatibility wrapper functions...\n');
assert(~isempty(which('buildFrequencyVector')), ...
    'Missing Rayleigh-Lamb legacy compatibility function buildFrequencyVector on MATLAB path.');
assert(~isempty(which('computeFundamentalLambModes')), ...
    'Missing Rayleigh-Lamb legacy compatibility function computeFundamentalLambModes on MATLAB path.');
assert(~isempty(which('computeGeometry')), ...
    'Missing Rayleigh-Lamb legacy compatibility function computeGeometry on MATLAB path.');
assert(~isempty(which('computeMaterial')), ...
    'Missing Rayleigh-Lamb legacy compatibility function computeMaterial on MATLAB path.');
assert(~isempty(which('defaultOptions')), ...
    'Missing Rayleigh-Lamb legacy compatibility function defaultOptions on MATLAB path.');
assert(~isempty(which('defaultParams')), ...
    'Missing Rayleigh-Lamb legacy compatibility function defaultParams on MATLAB path.');
assert(~isempty(which('makeBranchSpec')), ...
    'Missing Rayleigh-Lamb legacy compatibility function makeBranchSpec on MATLAB path.');
assert(~isempty(which('validateOptions')), ...
    'Missing Rayleigh-Lamb legacy compatibility function validateOptions on MATLAB path.');
assert(~isempty(which('validateParams')), ...
    'Missing Rayleigh-Lamb legacy compatibility function validateParams on MATLAB path.');
assert(~isempty(which('rayleighLambAResidual')), ...
    'Missing Rayleigh-Lamb legacy compatibility function rayleighLambAResidual on MATLAB path.');
assert(~isempty(which('rayleighLambSResidual')), ...
    'Missing Rayleigh-Lamb legacy compatibility function rayleighLambSResidual on MATLAB path.');
assert(~isempty(which('computeA0ThinPlateApproximation')), ...
    'Missing Rayleigh-Lamb legacy compatibility function computeA0ThinPlateApproximation on MATLAB path.');
assert(~isempty(which('computeAnalyticalApproximations')), ...
    'Missing Rayleigh-Lamb legacy compatibility function computeAnalyticalApproximations on MATLAB path.');
assert(~isempty(which('computeS0ExtensionalApproximation')), ...
    'Missing Rayleigh-Lamb legacy compatibility function computeS0ExtensionalApproximation on MATLAB path.');
assert(~isempty(which('solveFundamentalBranch')), ...
    'Missing Rayleigh-Lamb legacy compatibility function solveFundamentalBranch on MATLAB path.');


%% Rayleigh-Lamb organized wrapper layer path checks
fprintf('\nChecking Rayleigh-Lamb organized wrapper layer functions...\n');
assert(~isempty(which('rlBuildFrequencyVector')), ...
    'Missing Rayleigh-Lamb wrapper function rlBuildFrequencyVector on MATLAB path.');
assert(~isempty(which('rlComputeFundamentalLambModes')), ...
    'Missing Rayleigh-Lamb wrapper function rlComputeFundamentalLambModes on MATLAB path.');
assert(~isempty(which('rlComputeGeometry')), ...
    'Missing Rayleigh-Lamb wrapper function rlComputeGeometry on MATLAB path.');
assert(~isempty(which('rlComputeMaterial')), ...
    'Missing Rayleigh-Lamb wrapper function rlComputeMaterial on MATLAB path.');
assert(~isempty(which('rlDefaultOptions')), ...
    'Missing Rayleigh-Lamb wrapper function rlDefaultOptions on MATLAB path.');
assert(~isempty(which('rlDefaultParams')), ...
    'Missing Rayleigh-Lamb wrapper function rlDefaultParams on MATLAB path.');
assert(~isempty(which('rlMakeBranchSpec')), ...
    'Missing Rayleigh-Lamb wrapper function rlMakeBranchSpec on MATLAB path.');
assert(~isempty(which('rlValidateOptions')), ...
    'Missing Rayleigh-Lamb wrapper function rlValidateOptions on MATLAB path.');
assert(~isempty(which('rlValidateParams')), ...
    'Missing Rayleigh-Lamb wrapper function rlValidateParams on MATLAB path.');
assert(~isempty(which('rlAResidual')), ...
    'Missing Rayleigh-Lamb wrapper function rlAResidual on MATLAB path.');
assert(~isempty(which('rlSResidual')), ...
    'Missing Rayleigh-Lamb wrapper function rlSResidual on MATLAB path.');
assert(~isempty(which('rlComputeA0ThinPlateApproximation')), ...
    'Missing Rayleigh-Lamb wrapper function rlComputeA0ThinPlateApproximation on MATLAB path.');
assert(~isempty(which('rlComputeAnalyticalApproximations')), ...
    'Missing Rayleigh-Lamb wrapper function rlComputeAnalyticalApproximations on MATLAB path.');
assert(~isempty(which('rlComputeS0ExtensionalApproximation')), ...
    'Missing Rayleigh-Lamb wrapper function rlComputeS0ExtensionalApproximation on MATLAB path.');
assert(~isempty(which('rlSolveFundamentalBranch')), ...
    'Missing Rayleigh-Lamb wrapper function rlSolveFundamentalBranch on MATLAB path.');


%% Rayleigh-Lamb compatibility wrapper smoke checks
fprintf('\nChecking Rayleigh-Lamb compatibility wrapper forwarding...\n');
compatTol = 1e-12;

paramsOld = defaultParams();
paramsNew = rlDefaultParams();
assert(isequaln(paramsOld, paramsNew), ...
    'defaultParams does not match rlDefaultParams.');

optionsOld = defaultOptions();
optionsNew = rlDefaultOptions();
assert(isequaln(optionsOld, optionsNew), ...
    'defaultOptions does not match rlDefaultOptions.');

materialOld = computeMaterial(paramsNew);
materialNew = rlComputeMaterial(paramsNew);
assert(isequaln(materialOld, materialNew), ...
    'computeMaterial does not match rlComputeMaterial.');

geometryOld = computeGeometry(paramsNew);
geometryNew = rlComputeGeometry(paramsNew);
assert(isequaln(geometryOld, geometryNew), ...
    'computeGeometry does not match rlComputeGeometry.');

frequencyParams = paramsNew;
frequencyParams.fmin = 10;
frequencyParams.fmax = 100;
frequencyParams.numFrequencyPoints = 10;
frequencyParams.frequencySpacing = "linspace";
frequencyOld = buildFrequencyVector(frequencyParams);
frequencyNew = rlBuildFrequencyVector(frequencyParams);
assertNumericClose(frequencyOld, frequencyNew, compatTol, ...
    'buildFrequencyVector does not match rlBuildFrequencyVector.');

branchGeometry = geometryNew;
branchGeometry.frequency0 = frequencyNew(1);
branchSpecOld = makeBranchSpec("A0", materialNew, branchGeometry);
branchSpecNew = rlMakeBranchSpec("A0", materialNew, branchGeometry);
assert(isequaln(branchSpecOld, branchSpecNew), ...
    'makeBranchSpec A0 does not match rlMakeBranchSpec A0.');
branchSpecOld = makeBranchSpec("S0", materialNew, branchGeometry);
branchSpecNew = rlMakeBranchSpec("S0", materialNew, branchGeometry);
assert(isequaln(branchSpecOld, branchSpecNew), ...
    'makeBranchSpec S0 does not match rlMakeBranchSpec S0.');

approxFrequency = [10, 25, 100];
a0ApproxOld = computeA0ThinPlateApproximation(approxFrequency, materialNew, geometryNew);
a0ApproxNew = rlComputeA0ThinPlateApproximation(approxFrequency, materialNew, geometryNew);
assert(isequaln(a0ApproxOld, a0ApproxNew), ...
    'computeA0ThinPlateApproximation does not match rlComputeA0ThinPlateApproximation.');

s0ApproxOld = computeS0ExtensionalApproximation(approxFrequency, materialNew, geometryNew);
s0ApproxNew = rlComputeS0ExtensionalApproximation(approxFrequency, materialNew, geometryNew);
assert(isequaln(s0ApproxOld, s0ApproxNew), ...
    'computeS0ExtensionalApproximation does not match rlComputeS0ExtensionalApproximation.');


%% Rayleigh-Lamb maintained-code old-name audit
fprintf('\nAuditing maintained MATLAB code for old Rayleigh-Lamb function calls...\n');
oldRayleighLambNames = { ...
    'buildFrequencyVector', ...
    'computeFundamentalLambModes', ...
    'computeGeometry', ...
    'computeMaterial', ...
    'defaultOptions', ...
    'defaultParams', ...
    'makeBranchSpec', ...
    'validateOptions', ...
    'validateParams', ...
    'rayleighLambAResidual', ...
    'rayleighLambSResidual', ...
    'computeA0ThinPlateApproximation', ...
    'computeAnalyticalApproximations', ...
    'computeS0ExtensionalApproximation', ...
    'solveFundamentalBranch'};
maintainedAuditRoots = {'analysis', 'app', 'examples', 'tests'};
maintainedAuditExcludes = { ...
    'models/rayleigh_lamb/legacy/', ...
    'models/rayleigh_lamb/', ...
    'archive/', ...
    'prototypes/', ...
    'examples/archive/', ...
    'tests/run_all_smoke_tests.m'};
oldNameMatches = auditOldRayleighLambNames( ...
    maintainedAuditRoots, maintainedAuditExcludes, oldRayleighLambNames);
assert(isempty(oldNameMatches), ...
    sprintf('Maintained code uses old Rayleigh-Lamb function calls outside allowed legacy contexts:\n%s', ...
    strjoin(oldNameMatches, newline)));


%% Rayleigh-Lamb minimal numerical regression fixtures
fprintf('\nChecking Rayleigh-Lamb minimal numerical regression fixtures...\n');
regressionTol = 1e-12;

regressionParams = rlDefaultParams();
regressionParams.fmin = 10;
regressionParams.fmax = 100;
regressionParams.numFrequencyPoints = 10;
regressionParams.frequencySpacing = "linspace";

regressionOptions = rlDefaultOptions();
regressionOptions.computeA0 = true;
regressionOptions.computeS0 = true;
regressionOptions.computeMRLFE = false;

regressionResults = rlComputeFundamentalLambModes(regressionParams, regressionOptions);
regressionRepeat = rlComputeFundamentalLambModes(regressionParams, regressionOptions);
expectedSize = size(rlBuildFrequencyVector(regressionParams));

assert(isfield(regressionResults, 'grid') && isfield(regressionResults.grid, 'frequency'), ...
    'Rayleigh-Lamb regression results are missing grid.frequency.');
assert(isfield(regressionResults, 'modes') && isfield(regressionResults.modes, 'A0'), ...
    'Rayleigh-Lamb regression results are missing A0 mode output.');
assert(isfield(regressionResults.modes, 'S0'), ...
    'Rayleigh-Lamb regression results are missing S0 mode output.');

regressionFrequency = regressionResults.grid.frequency;
regressionA0 = regressionResults.modes.A0;
regressionS0 = regressionResults.modes.S0;

assert(isequal(size(regressionFrequency), expectedSize), ...
    'Rayleigh-Lamb regression frequency size does not match the requested grid.');
assert(isequal(size(regressionA0.frequency), expectedSize), ...
    'Rayleigh-Lamb A0 regression frequency size does not match the requested grid.');
assert(isequal(size(regressionS0.frequency), expectedSize), ...
    'Rayleigh-Lamb S0 regression frequency size does not match the requested grid.');
assert(isequal(size(regressionA0.Cp), expectedSize), ...
    'Rayleigh-Lamb A0 regression Cp size does not match the requested grid.');
assert(isequal(size(regressionS0.Cp), expectedSize), ...
    'Rayleigh-Lamb S0 regression Cp size does not match the requested grid.');

assert(all(isfinite(regressionFrequency(:))), ...
    'Rayleigh-Lamb regression frequencies must be finite.');
assert(all(isfinite(regressionA0.Cp(:)) & regressionA0.Cp(:) > 0), ...
    'Rayleigh-Lamb A0 regression Cp values must be finite and positive.');
assert(all(isfinite(regressionS0.Cp(:)) & regressionS0.Cp(:) > 0), ...
    'Rayleigh-Lamb S0 regression Cp values must be finite and positive.');
assert(any(abs(regressionA0.Cp(:) - regressionS0.Cp(:)) > regressionTol), ...
    'Rayleigh-Lamb A0 and S0 regression Cp outputs should not be identical.');

assertNumericClose(regressionFrequency, regressionRepeat.grid.frequency, regressionTol, ...
    'Rayleigh-Lamb regression frequencies are not repeatable.');
assertNumericClose(regressionA0.Cp, regressionRepeat.modes.A0.Cp, regressionTol, ...
    'Rayleigh-Lamb A0 regression Cp values are not repeatable.');
assertNumericClose(regressionS0.Cp, regressionRepeat.modes.S0.Cp, regressionTol, ...
    'Rayleigh-Lamb S0 regression Cp values are not repeatable.');

fprintf('\nChecking maintained acoustoelastic IOP/HGO wrappers and entrypoints...\n');
assert(~isempty(which('solveAcoustoelasticIOPHGOBranch')), ...
    'Missing solveAcoustoelasticIOPHGOBranch on MATLAB path.');
assert(~isempty(which('solveAcoustoelasticIOPHGOAtlasBranch')), ...
    'Missing solveAcoustoelasticIOPHGOAtlasBranch on MATLAB path.');
assert(~isempty(which('solveAcoustoelasticAtlasBranch')), ...
    'Missing solveAcoustoelasticAtlasBranch on MATLAB path.');
assert(~isempty(which('solveAcoustoelasticIOPHGODispersion')), ...
    'Missing solveAcoustoelasticIOPHGODispersion on MATLAB path.');
assert(~isempty(which('solveAcoustoelasticDispersion')), ...
    'Missing solveAcoustoelasticDispersion on MATLAB path.');
assert(~isempty(which('solveAcoustoelasticComplexCDispersion')), ...
    'Missing solveAcoustoelasticComplexCDispersion on MATLAB path.');
assert(~isempty(which('objectiveAcoustoelasticResidual')), ...
    'Missing objectiveAcoustoelasticResidual on MATLAB path.');
assert(~isempty(which('objectiveAcoustoelasticComplexDeterminant')), ...
    'Missing objectiveAcoustoelasticComplexDeterminant on MATLAB path.');
assert(~isempty(which('buildAcoustoelasticMatrix')), ...
    'Missing buildAcoustoelasticMatrix on MATLAB path.');
assert(~isempty(which('defaultAcoustoelasticIOPHGOOptions')), ...
    'Missing defaultAcoustoelasticIOPHGOOptions on MATLAB path.');
assert(~isempty(which('computeAcoustoelasticABGFromIOPHGO')), ...
    'Missing computeAcoustoelasticABGFromIOPHGO on MATLAB path.');
assert(~isempty(which('computeAcoustoelasticAlphaBetaGamma')), ...
    'Missing computeAcoustoelasticAlphaBetaGamma on MATLAB path.');
assert(~isempty(which('computeAcoustoelasticPrestressSigma')), ...
    'Missing computeAcoustoelasticPrestressSigma on MATLAB path.');
assert(~isempty(which('computeAcoustoelasticSRoots')), ...
    'Missing computeAcoustoelasticSRoots on MATLAB path.');
assert(~isempty(which('solveAcoustoelasticHGOStretch')), ...
    'Missing solveAcoustoelasticHGOStretch on MATLAB path.');
assert(~isempty(which('run_acoustoelastic_iop_hgo_atlas_branch')), ...
    'Missing run_acoustoelastic_iop_hgo_atlas_branch on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_branch_policy')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_branch_policy on MATLAB path.');
assert(~isempty(which('run_acoustoelastic_iop_hgo_A0_backward')), ...
    'Missing run_acoustoelastic_iop_hgo_A0_backward on MATLAB path.');
assert(~isempty(which('run_acoustoelastic_iop_hgo_A0_complexC')), ...
    'Missing run_acoustoelastic_iop_hgo_A0_complexC on MATLAB path.');
assert(~isempty(which('run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma')), ...
    'Missing run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma on MATLAB path.');
assert(~isempty(which('compare_acoustoelastic_iop_hgo_tracking_strategies')), ...
    'Missing compare_acoustoelastic_iop_hgo_tracking_strategies on MATLAB path.');
assert(~isempty(which('summarizeAcoustoelasticIOPHGOTrackingQuality')), ...
    'Missing summarizeAcoustoelasticIOPHGOTrackingQuality on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_grid_convergence')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_grid_convergence on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_dimensionless_A1')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_dimensionless_A1 on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_matrix_variants')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_matrix_variants on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_modal_atlas')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_modal_atlas on MATLAB path.');
assert(~isempty(which('diagnose_acoustoelastic_iop_hgo_residual_landscape')), ...
    'Missing diagnose_acoustoelastic_iop_hgo_residual_landscape on MATLAB path.');
assert(~isempty(which('track_acoustoelastic_iop_hgo_raw_branch1_candidate')), ...
    'Missing track_acoustoelastic_iop_hgo_raw_branch1_candidate on MATLAB path.');
assert(~isempty(which('sweep_acoustoelastic_iop_hgo_A0_backward')), ...
    'Missing sweep_acoustoelastic_iop_hgo_A0_backward on MATLAB path.');
assert(~isempty(which('test_acoustoelastic_iop_hgo_constitutive_identity')), ...
    'Missing test_acoustoelastic_iop_hgo_constitutive_identity on MATLAB path.');
assert(~isempty(which('test_acoustoelastic_iop_hgo_strictA0_smoke')), ...
    'Missing test_acoustoelastic_iop_hgo_strictA0_smoke on MATLAB path.');

fprintf('\nChecking Acoustoelastic legacy compatibility wrappers...\n');
assert(~isempty(which('defaultLi2024AcoustoelasticOptions')), ...
    'Missing legacy wrapper defaultLi2024AcoustoelasticOptions on MATLAB path.');
assert(~isempty(which('solveDispersionIOPHGO_Li2024')), ...
    'Missing legacy wrapper solveDispersionIOPHGO_Li2024 on MATLAB path.');
assert(~isempty(which('solveDispersionIOPHGOAtlasBranch_Li2024')), ...
    'Missing legacy wrapper solveDispersionIOPHGOAtlasBranch_Li2024 on MATLAB path.');
assert(~isempty(which('solveDispersionAtlasBranch_Li2024_Acoustoelastic')), ...
    'Missing legacy wrapper solveDispersionAtlasBranch_Li2024_Acoustoelastic on MATLAB path.');
assert(~isempty(which('solveDispersion_Li2024_Acoustoelastic')), ...
    'Missing legacy wrapper solveDispersion_Li2024_Acoustoelastic on MATLAB path.');
assert(~isempty(which('solveDispersionComplexC_Li2024_Acoustoelastic')), ...
    'Missing legacy wrapper solveDispersionComplexC_Li2024_Acoustoelastic on MATLAB path.');
assert(~isempty(which('computeABGFromIOPHGO_Li2024')), ...
    'Missing legacy wrapper computeABGFromIOPHGO_Li2024 on MATLAB path.');
assert(~isempty(which('computeAlphaBetaGamma_Li2024')), ...
    'Missing legacy wrapper computeAlphaBetaGamma_Li2024 on MATLAB path.');
assert(~isempty(which('computePrestressSigma_Li2024')), ...
    'Missing legacy wrapper computePrestressSigma_Li2024 on MATLAB path.');
assert(~isempty(which('solveStretchHGO_Li2024')), ...
    'Missing legacy wrapper solveStretchHGO_Li2024 on MATLAB path.');
assert(~isempty(which('computeSRoots_Li2024')), ...
    'Missing legacy wrapper computeSRoots_Li2024 on MATLAB path.');
assert(~isempty(which('objective_Li2024_Acoustoelastic')), ...
    'Missing legacy wrapper objective_Li2024_Acoustoelastic on MATLAB path.');
assert(~isempty(which('objectiveComplexDet_Li2024_Acoustoelastic')), ...
    'Missing legacy wrapper objectiveComplexDet_Li2024_Acoustoelastic on MATLAB path.');
assert(~isempty(which('buildMatrix_Li2024_Acoustoelastic')), ...
    'Missing legacy wrapper buildMatrix_Li2024_Acoustoelastic on MATLAB path.');

fprintf('\n[1/3] Acoustoelastic IOP/HGO constitutive identity test\n');
test_acoustoelastic_iop_hgo_constitutive_identity;

fprintf('\n[2/3] Acoustoelastic IOP/HGO strict-A0 atlas branch smoke test\n');
test_acoustoelastic_iop_hgo_strictA0_smoke;

fprintf('\n[3/3] mRLFE smoke test\n');
test_mrlfe_smoke;

fprintf('\nAll maintained smoke tests passed.\n');


function matches = auditOldRayleighLambNames(auditRoots, auditExcludes, oldNames)
%AUDITOLDRAYLEIGHLAMBNAMES Find old-name function calls in maintained code.
matches = {};
repoRoot = fileparts(fileparts(mfilename('fullpath')));
for iRoot = 1:numel(auditRoots)
    rootPath = fullfile(repoRoot, auditRoots{iRoot});
    if ~isfolder(rootPath)
        continue;
    end
    files = dir(fullfile(rootPath, '**', '*.m'));
    for iFile = 1:numel(files)
        filePath = fullfile(files(iFile).folder, files(iFile).name);
        relativePath = normalizeAuditPath(strrep(filePath, [repoRoot filesep], ''));
        if isExcludedAuditPath(relativePath, auditExcludes)
            continue;
        end
        fileText = fileread(filePath);
        codeText = stripMatlabComments(fileText);
        for iName = 1:numel(oldNames)
            expression = ['(?<![A-Za-z0-9_])' oldNames{iName} '\s*\('];
            if ~isempty(regexp(codeText, expression, 'once'))
                matches{end + 1} = sprintf('%s: %s(', relativePath, oldNames{iName}); %#ok<AGROW>
            end
        end
    end
end
matches = unique(matches, 'stable');
end

function tf = isExcludedAuditPath(relativePath, auditExcludes)
%ISEXCLUDEDAUDITPATH Return true for compatibility, archive, or audit files.
tf = false;
for iExclude = 1:numel(auditExcludes)
    excludedPath = normalizeAuditPath(auditExcludes{iExclude});
    if endsWith(excludedPath, '/')
        if startsWith(relativePath, excludedPath) || contains(relativePath, ['/' excludedPath])
            tf = true;
            return;
        end
    elseif strcmp(relativePath, excludedPath)
        tf = true;
        return;
    end
end
end

function normalizedPath = normalizeAuditPath(pathText)
%NORMALIZEAUDITPATH Use forward slashes for stable path matching.
normalizedPath = strrep(pathText, '\', '/');
end

function codeText = stripMatlabComments(fileText)
%STRIPMATLABCOMMENTS Remove MATLAB comments while preserving quoted strings.
lines = regexp(fileText, '\r\n|\n|\r', 'split');
for iLine = 1:numel(lines)
    lineText = lines{iLine};
    inString = false;
    commentStart = 0;
    iChar = 1;
    while iChar <= strlength(lineText)
        currentChar = extractBetween(lineText, iChar, iChar);
        if strcmp(currentChar, '''')
            if inString && iChar < strlength(lineText) && strcmp(extractBetween(lineText, iChar + 1, iChar + 1), '''')
                iChar = iChar + 2;
                continue;
            end
            inString = ~inString;
        elseif strcmp(currentChar, '%') && ~inString
            commentStart = iChar;
            break;
        end
        iChar = iChar + 1;
    end
    if commentStart > 0
        lines{iLine} = extractBefore(lineText, commentStart);
    end
end
codeText = strjoin(lines, newline);
end
function assertNumericClose(actual, expected, tol, message)
%ASSERTNUMERICCLOSE Strict numeric comparison that treats matching empty arrays as equal.
if isempty(actual) && isempty(expected)
    return;
end
assert(isequal(size(actual), size(expected)), message);
assert(max(abs(actual(:) - expected(:))) < tol, message);
end
