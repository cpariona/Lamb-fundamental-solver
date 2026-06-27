% Diagnose hook/cut policy for experimental mRLFE A0 modal-atlas branch.
%
% This script compares the continuous modal-atlas path against a conservative
% hook/cut policy. The goal is not to force agreement with the maintained branch
% where the maintained branch may jump to another modal family, but to identify
% ambiguous escape regions.
clear; clc; startup
fprintf('\n=== mRLFE A0 modal-atlas hook policy diagnostic ===\n');

params = rlDefaultParams();
params.modelType = "ShearPoisson"; params.rho = 1070; params.mu = 158e3; params.nu = 0.4999;
params.thickness = 0.5e-3; params.fmin = 10; params.fmax = 32e3;
params.numFrequencyPoints = "auto"; params.frequencySpacing = "hybrid";
mat = rlComputeMaterial(params);
params.E = mat.E; params.K = mat.K; params.CL = mat.CL; params.CT = mat.CT; params.lambda = mat.lambda; params.nu = mat.nu;
geom = rlComputeGeometry(params); f = rlBuildFrequencyVector(params).';
fprintf('Auto frequency points: %d | fmin %.6g Hz | fmax %.6g Hz\n', numel(f), min(f), max(f));

opt = rlDefaultOptions("Fast");
opt.computeA0 = true; opt.computeS0 = false;
opt.computeMRLFE = false; opt.computeMRLFERealK = true; opt.computeMRLFEElasticRealK = true;
opt.computeMRLFEViscoRealK = false; opt.computeMRLFEComplexK = false;
opt.mrlfeComputeA0Like = true; opt.mrlfeComputeS0Like = false;
opt.mrlfeParams = defaultMRLFEParams(); opt.mrlfeParams.fluidDensity = 1000; opt.mrlfeParams.fluidSoundSpeed = 1500;
opt.mrlfeParams.etaS = 0; opt.mrlfeParams.etaL = 0; opt.mrlfeParams.useComplexLambda = false;

t = tic; rawRef = rlComputeFundamentalLambModes(params,opt); tref = toc(t);
ref = rawRef.models.mRLFERealK.branches.A0Like; refCp = ref.Cp(:); refValid = branchValid(ref);
seed = rawRef.modes.A0;
fprintf('Maintained A0Like elastic: %.6g s | valid %d/%d\n', tref, nnz(refValid), numel(refValid));

atlasOpt = opt; atlasOpt.mrlfeModalAtlasCpScanPoints = 1200; atlasOpt.mrlfeModalAtlasTopNMinima = 24;
atlasOpt.mrlfeModalAtlasMaxLogCpJump = 0.075; atlasOpt.mrlfeModalAtlasCpMinFactor = 0.20;
atlasOpt.mrlfeModalAtlasCpMaxFactor = 2.80; atlasOpt.mrlfeModalAtlasCpMaxCeiling = 120;
atlasOpt.mrlfeModalAtlasMinBranchPoints = 8; atlasOpt.mrlfeModalAtlasRefineMinima = true;
atlasOpt.mrlfeModalAtlasRequireLowStartRank = false; atlasOpt.mrlfeModalAtlasRequireResidualValidity = false;

t = tic; atlas = solveMRLFEBranchModalAtlas("A0Like", seed, mat, rmfield(geom,'halfThickness'), opt.mrlfeParams, atlasOpt); tatlas = toc(t);
atlasCp = atlas.Cp(:); atlasValid = branchValid(atlas);
fprintf('Atlas continuous: %.6g s | selected family %g | valid %d/%d\n', tatlas, atlas.modalAtlas.selectedFamily.BranchID, nnz(atlasValid), numel(f));

thresholds = table();
thresholds.ResidualRatio = [2; 4; 8; 12];
thresholds.MinCpSeparation = [0.12; 0.12; 0.12; 0.12];
thresholds.MinConsecutive = [2; 2; 2; 2];
summary = table();
caseRows = table();
for i = 1:height(thresholds)
    ratio = thresholds.ResidualRatio(i);
    sep = thresholds.MinCpSeparation(i);
    minRun = thresholds.MinConsecutive(i);
    [cutMask, escapeTable] = detectHookEscape(atlas, ratio, sep, minRun);
    cutCp = atlasCp; cutCp(cutMask) = nan;
    cutValid = atlasValid & ~cutMask;
    cmpCont = compareCp(f, refCp, refValid, atlasCp, atlasValid);
    cmpCut = compareCp(f, refCp, refValid, cutCp, cutValid);

    row = table();
    row.ResidualRatio = ratio;
    row.MinCpSeparation = sep;
    row.MinConsecutive = minRun;
    row.CutPoints = nnz(cutMask);
    row.FirstCutFrequency_Hz = firstFreq(f, cutMask);
    row.LastCutFrequency_Hz = lastFreq(f, cutMask);
    row.ValidContinuous = nnz(atlasValid);
    row.ValidCut = nnz(cutValid);
    row.ContinuousRMSE_mps = cmpCont.RMSE;
    row.CutRMSE_mps = cmpCut.RMSE;
    row.ContinuousP95_mps = cmpCont.P95;
    row.CutP95_mps = cmpCut.P95;
    row.ContinuousMaxAbs_mps = cmpCont.MaxAbs;
    row.CutMaxAbs_mps = cmpCut.MaxAbs;
    summary = [summary; row]; %#ok<AGROW>
    escapeTable.PolicyResidualRatio = repmat(ratio, height(escapeTable), 1);
    caseRows = [caseRows; escapeTable]; %#ok<AGROW>

    fprintf('ratio %.3g -> cut %d pts | %.6g-%.6g Hz | valid %d | RMSE %.6g | P95 %.6g | max %.6g\n', ...
        ratio, nnz(cutMask), row.FirstCutFrequency_Hz, row.LastCutFrequency_Hz, nnz(cutValid), cmpCut.RMSE, cmpCut.P95, cmpCut.MaxAbs);
end

fprintf('\nHook/cut summary\n');
disp(summary);

fprintf('\nDetected escape candidates near cut regions\n');
if isempty(caseRows)
    disp(table());
else
    showRows = caseRows(caseRows.Frequency_Hz >= 22e3 & caseRows.Frequency_Hz <= 24.5e3, :);
    disp(showRows(:, {'PolicyResidualRatio','Frequency_Hz','SelectedCp_mps','SelectedObjective','BestCp_mps','BestObjective','BestRank','RelativeCpSeparation','ObjectiveRatio'}));
end

assignin('base','MRLFEA0ModalAtlasHookPolicySummary',summary);
assignin('base','MRLFEA0ModalAtlasHookPolicyRows',caseRows);
assignin('base','MRLFEA0ModalAtlasHookPolicyAtlas',atlas);
assignin('base','MRLFEA0ModalAtlasHookPolicyReference',rawRef);

fprintf('\nInterpretation guide:\n');
fprintf('  - If hook/cut removes the max error while losing few points, promote a cut policy.\n');
fprintf('  - If it cuts too much, tune ResidualRatio or MinCpSeparation.\n');
fprintf('  - A cut policy is safer than switching to another modal family in ambiguous bands.\n');

function [cutMask, escapeTable] = detectHookEscape(atlas, ratioThreshold, minCpSeparation, minConsecutive)
f = atlas.frequency(:); cp = atlas.Cp(:); res = atlas.residual(:); fid = atlas.modalAtlasFamilyId(:);
T = atlas.modalAtlas.minimaTable;
escape = false(size(f)); rows = [];
for i = 1:numel(f)
    if ~isfinite(cp(i)) || ~isfinite(res(i)) || ~isfinite(fid(i))
        continue;
    end
    Tf = T(T.FrequencyIndex == i,:);
    if isempty(Tf), continue; end
    Tf = sortrows(Tf,'Objective'); best = Tf(1,:);
    if best.BranchID == fid(i), continue; end
    if best.Cp_mps <= cp(i), continue; end
    relSep = abs(best.Cp_mps - cp(i)) / max(abs(cp(i)), eps);
    objRatio = res(i) / max(best.Objective, realmin);
    if relSep >= minCpSeparation && objRatio >= ratioThreshold
        escape(i) = true;
        r.Frequency_Hz = f(i); r.SelectedCp_mps = cp(i); r.SelectedObjective = res(i);
        r.BestCp_mps = best.Cp_mps; r.BestObjective = best.Objective; r.BestRank = best.MinRank;
        r.RelativeCpSeparation = relSep; r.ObjectiveRatio = objRatio; rows = [rows; r]; %#ok<AGROW>
    end
end
cutMask = keepConsecutiveRuns(escape, minConsecutive);
if isempty(rows), escapeTable = table(); else, escapeTable = struct2table(rows); end
end

function mask = keepConsecutiveRuns(mask, minRun)
mask = logical(mask(:)); out = false(size(mask)); i = 1;
while i <= numel(mask)
    if ~mask(i), i = i + 1; continue; end
    j = i; while j <= numel(mask) && mask(j), j = j + 1; end
    if (j-i) >= minRun, out(i:j-1) = true; end
    i = j;
end
mask = out;
end

function cmp = compareCp(f, refCp, refValid, cp, valid)
mask = refValid(:) & valid(:) & isfinite(refCp(:)) & isfinite(cp(:)); err = cp(:) - refCp(:); ae = abs(err);
cmp.RMSE = nan; cmp.P95 = nan; cmp.MaxAbs = nan;
if any(mask), cmp.RMSE = sqrt(mean(err(mask).^2,'omitnan')); cmp.P95 = pct(ae(mask),95); cmp.MaxAbs = max(ae(mask),[],'omitnan'); end
end
function valid = branchValid(branch)
cp = branch.Cp(:); valid = isfinite(cp) & cp > 0;
if isfield(branch,'validCp'), valid = valid & logical(branch.validCp(:)); elseif isfield(branch,'valid'), valid = valid & logical(branch.valid(:)); end
end
function v = pct(x,p)
x = sort(x(isfinite(x))); if isempty(x), v=nan; else, v=x(max(1,min(numel(x),ceil(p/100*numel(x))))); end
end
function v = firstFreq(f,m)
i=find(m(:),1,'first'); if isempty(i), v=nan; else, v=f(i); end
end
function v = lastFreq(f,m)
i=find(m(:),1,'last'); if isempty(i), v=nan; else, v=f(i); end
end
