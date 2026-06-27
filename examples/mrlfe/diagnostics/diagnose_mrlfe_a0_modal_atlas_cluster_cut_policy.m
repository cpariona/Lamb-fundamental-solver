% Diagnose cluster-based hook/cut policy for experimental mRLFE A0 atlas.
clear; clc; startup
fprintf('\n=== mRLFE A0 modal-atlas cluster cut policy diagnostic ===\n');

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
cont = compareCp(refCp, refValid, atlasCp, atlasValid);
fprintf('Atlas continuous: %.6g s | valid %d/%d | RMSE %.6g | P95 %.6g | max %.6g\n', tatlas, nnz(atlasValid), numel(f), cont.RMSE, cont.P95, cont.MaxAbs);

cases = table();
cases.ResidualRatio = [2; 4; 8; 12; 4; 8];
cases.MinCpSeparation = [0.12; 0.12; 0.12; 0.12; 0.16; 0.16];
cases.MaxGapPoints = [4; 4; 4; 4; 4; 4];
cases.PaddingPoints = [1; 1; 1; 1; 1; 1];
cases.MinClusterTriggers = [2; 2; 2; 2; 2; 2];
summary = table(); clustersAll = table();
for ic = 1:height(cases)
    ratio = cases.ResidualRatio(ic); sep = cases.MinCpSeparation(ic);
    maxGap = cases.MaxGapPoints(ic); pad = cases.PaddingPoints(ic); minTrig = cases.MinClusterTriggers(ic);
    [triggerMask, triggerRows] = detectEscapeTriggers(atlas, ratio, sep);
    [cutMask, clusters] = clusterCut(triggerMask, f, maxGap, pad, minTrig);
    cutCp = atlasCp; cutCp(cutMask) = nan; cutValid = atlasValid & ~cutMask;
    cmp = compareCp(refCp, refValid, cutCp, cutValid);
    row = table();
    row.ResidualRatio = ratio; row.MinCpSeparation = sep; row.MaxGapPoints = maxGap; row.PaddingPoints = pad;
    row.MinClusterTriggers = minTrig; row.NumTriggers = nnz(triggerMask); row.CutPoints = nnz(cutMask);
    row.FirstCut_Hz = firstFreq(f, cutMask); row.LastCut_Hz = lastFreq(f, cutMask);
    row.ValidCut = nnz(cutValid); row.CutRMSE_mps = cmp.RMSE; row.CutP95_mps = cmp.P95; row.CutMaxAbs_mps = cmp.MaxAbs;
    summary = [summary; row]; %#ok<AGROW>
    if ~isempty(clusters)
        clusters.PolicyIndex = repmat(ic, height(clusters), 1); clusters.ResidualRatio = repmat(ratio, height(clusters), 1);
        clustersAll = [clustersAll; clusters]; %#ok<AGROW>
    end
    fprintf('ratio %.3g sep %.3g -> triggers %d | cut %d pts | %.6g-%.6g Hz | RMSE %.6g | P95 %.6g | max %.6g\n', ...
        ratio, sep, nnz(triggerMask), nnz(cutMask), row.FirstCut_Hz, row.LastCut_Hz, cmp.RMSE, cmp.P95, cmp.MaxAbs);
end

fprintf('\nCluster cut summary\n'); disp(summary);
fprintf('\nClusters\n'); disp(clustersAll);
fprintf('\nTriggers in 22-24.5 kHz band\n');
if isempty(triggerRows), disp(table()); else, disp(triggerRows(triggerRows.Frequency_Hz>=22e3 & triggerRows.Frequency_Hz<=24.5e3,:)); end
assignin('base','MRLFEA0ModalAtlasClusterCutSummary',summary);
assignin('base','MRLFEA0ModalAtlasClusterCutClusters',clustersAll);
assignin('base','MRLFEA0ModalAtlasClusterCutAtlas',atlas);
assignin('base','MRLFEA0ModalAtlasClusterCutReference',rawRef);

function [mask, rowsTable] = detectEscapeTriggers(atlas, ratioThreshold, minCpSeparation)
f = atlas.frequency(:); cp = atlas.Cp(:); res = atlas.residual(:); fid = atlas.modalAtlasFamilyId(:); T = atlas.modalAtlas.minimaTable;
mask = false(size(f)); rows = [];
for i=1:numel(f)
    if ~isfinite(cp(i)) || ~isfinite(res(i)) || ~isfinite(fid(i)), continue; end
    Tf = sortrows(T(T.FrequencyIndex==i,:), 'Objective'); if isempty(Tf), continue; end
    best = Tf(1,:); if best.BranchID == fid(i) || best.Cp_mps <= cp(i), continue; end
    relSep = abs(best.Cp_mps - cp(i)) / max(abs(cp(i)), eps); objRatio = res(i) / max(best.Objective, realmin);
    if relSep >= minCpSeparation && objRatio >= ratioThreshold
        mask(i)=true; r.Frequency_Hz=f(i); r.SelectedCp_mps=cp(i); r.BestCp_mps=best.Cp_mps; r.RelativeCpSeparation=relSep; r.ObjectiveRatio=objRatio; rows=[rows; r]; %#ok<AGROW>
    end
end
if isempty(rows), rowsTable=table(); else, rowsTable=struct2table(rows); end
end

function [cutMask, clusters] = clusterCut(triggerMask, f, maxGap, pad, minTriggers)
idx = find(triggerMask(:)); cutMask = false(size(triggerMask(:))); rows=[];
if isempty(idx), clusters=table(); return; end
start = idx(1); last = idx(1); nTrig = 1;
for k=2:numel(idx)
    if idx(k)-last <= maxGap+1
        last = idx(k); nTrig = nTrig + 1;
    else
        [cutMask, rows] = addCluster(cutMask, rows, start, last, nTrig, f, pad, minTriggers);
        start = idx(k); last = idx(k); nTrig = 1;
    end
end
[cutMask, rows] = addCluster(cutMask, rows, start, last, nTrig, f, pad, minTriggers);
if isempty(rows), clusters=table(); else, clusters=struct2table(rows); end
end

function [cutMask, rows] = addCluster(cutMask, rows, startIdx, lastIdx, nTrig, f, pad, minTriggers)
if nTrig < minTriggers, return; end
a = max(1, startIdx-pad); b = min(numel(cutMask), lastIdx+pad); cutMask(a:b)=true;
r.StartIndex=a; r.EndIndex=b; r.TriggerCount=nTrig; r.StartFrequency_Hz=f(a); r.EndFrequency_Hz=f(b); r.CutPoints=b-a+1; rows=[rows; r]; %#ok<AGROW>
end

function cmp = compareCp(refCp, refValid, cp, valid)
mask = refValid(:) & valid(:) & isfinite(refCp(:)) & isfinite(cp(:)); err = cp(:)-refCp(:); ae=abs(err);
cmp.RMSE=nan; cmp.P95=nan; cmp.MaxAbs=nan; if any(mask), cmp.RMSE=sqrt(mean(err(mask).^2,'omitnan')); cmp.P95=pct(ae(mask),95); cmp.MaxAbs=max(ae(mask),[],'omitnan'); end
end
function valid = branchValid(branch)
cp=branch.Cp(:); valid=isfinite(cp)&cp>0; if isfield(branch,'validCp'), valid=valid&logical(branch.validCp(:)); elseif isfield(branch,'valid'), valid=valid&logical(branch.valid(:)); end
end
function v=pct(x,p), x=sort(x(isfinite(x))); if isempty(x), v=nan; else, v=x(max(1,min(numel(x),ceil(p/100*numel(x))))); end, end
function v=firstFreq(f,m), i=find(m(:),1,'first'); if isempty(i), v=nan; else, v=f(i); end, end
function v=lastFreq(f,m), i=find(m(:),1,'last'); if isempty(i), v=nan; else, v=f(i); end, end
