function test_rl_near_incompressible_contract()
verifyProfileInvariance();
p=lamb.models.rayleigh_lamb.rlDefaultParams();assert(p.nu==.4999);
o=lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
for nu=[.49 .495 .499 .4999]
 p.nu=nu;lamb.models.rayleigh_lamb.configuration.rlValidateParams(p);
end
for nu=[.49-eps(.49) .5]
 p.nu=nu;mustError(@()lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(p,o),'lamb:rl:UnsupportedPoissonRatio');
end
p=lamb.models.rayleigh_lamb.rlDefaultParams();p.modelType="LameParameters";p.lambda=p.mu;
mustError(@()lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(p,o),'lamb:rl:UnsupportedPoissonRatio');
p.lambda=49*p.mu;p.nu=.1;
lamb.models.rayleigh_lamb.configuration.rlValidateParams(p);
assert(lamb.elasticity.elasticFromMuNu(p.mu,.3,p.rho).nu==.3);
refs=rlNearIncompressibleReferences();
for nu=[.49 .495 .499 .4999]
 p=lamb.models.rayleigh_lamb.rlDefaultParams();p.nu=nu;
 mat=lamb.models.rayleigh_lamb.core.rlComputeMaterial(p);g=lamb.models.rayleigh_lamb.core.rlComputeGeometry(p);
 for family=["A","S"]
  rows=cell2mat(refs(:,1))==nu & string(refs(:,3))==family;om=cell2mat(refs(rows,2)).';expected=cell2mat(refs(rows,4)).';
  spec=lamb.models.rayleigh_lamb.core.rlMakeBranchSpec(family+"0",mat,g);f=om*mat.CT/(2*pi*g.halfThickness);
  [cp,res]=lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch(f,spec,o);k=om.*mat.CT./cp;
  assert(all(isfinite(cp)) && all(abs(k-expected)<=16*eps(expected)));
  assert(all(res<=16*eps));
  for K=[2 2*sqrt(spec.r2)]
   [F,FK,FO,M]=lamb.models.rayleigh_lamb.equations.rlBoundaryEquation(2,K,nu,family);
   assert(all(isfinite([F FK FO M(:).'])));
  end
 end
 % Locate and traverse the actual S0 Q=0 point with regular equations.
 oq=fzero(@(om)lamb.models.rayleigh_lamb.equations.rlBoundaryEquation(om,om,nu,"S"),[3.8 4.1]);
 spec=lamb.models.rayleigh_lamb.core.rlMakeBranchSpec("S0",mat,g);
 f=oq*[1-1e-6 1 1+1e-6]*mat.CT/(2*pi*g.halfThickness);
 cp=lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch(f,spec,o);
 assert(all(isfinite(cp)) && abs(cp(2)-mat.CT)<=32*eps(mat.CT));
end
p.mu=25e3;p.nu=.4999;p.thickness=1e-3;p.frequencySpacing="explicit";p.frequencyVector_Hz=[10 6166.45601805833 16000];p.fmin=10;p.fmax=16000;o.computeS0=true;
r=lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(p,o);assert(abs(r.modes.S0.phaseVelocity_mps(2)-4.83137673339218)<2e-13);
ex=struct('frequency_Hz',[1000;2000],'Cp_mps',[1;2],'validMask',[true;true]);
cfg=struct('freeParams',"mu",'fixedParams',struct('nu',.48));
mustError(@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem(ex,cfg),'lamb:rl:UnsupportedPoissonRatio');
mustError(@()lamb.fitting.mrlfe.mrlfeBuildFitProblem(ex,cfg),'mrlfe:UnsupportedPoissonRatio');
cfg=struct('freeParams',"nu",'bounds',struct('nu',[.48 .49999]));
mustError(@()lamb.fitting.rayleigh_lamb.rlBuildFitProblem(ex,cfg),'lamb:rl:UnsupportedPoissonRatio');
mustError(@()lamb.fitting.mrlfe.mrlfeBuildFitProblem(ex,cfg),'mrlfe:UnsupportedPoissonRatio');
p=lamb.models.rayleigh_lamb.rlDefaultParams();p.nu=.49;eval=@(q)lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(q,ex.frequency_Hz,"A0",o);
[S,info]=lamb.fitting.estimateLocalSensitivity(eval,p,"nu",ex);
assert(all(isnan(S)) && ~info.coverageAccepted && isequal(info.validMask,ex.validMask));
root=testRepositoryRoot(mfilename('fullpath'));files=dir(fullfile(root,'src','+lamb','+models','+rayleigh_lamb','**','*.m'));assert(numel(files)<=17);
fprintf('Near-incompressible RL domain, regular roots, anchors, Q=0, pathology and sensitivity passed.\n');
end
function verifyProfileInvariance()
% Same 100-digit roots and existing 16-ULP root budget for every profile.
refs=rlNearIncompressibleReferences();profiles=["Fast" "Balanced" "Robust"];
maxOracle=0;maxSpread=0;
for nu=[.49 .499 .4999]
 p=lamb.models.rayleigh_lamb.rlDefaultParams();p.nu=nu;
 mat=lamb.models.rayleigh_lamb.core.rlComputeMaterial(p);
 g=lamb.models.rayleigh_lamb.core.rlComputeGeometry(p);
 for family=["A" "S"]
  rows=cell2mat(refs(:,1))==nu & string(refs(:,3))==family;
  om=cell2mat(refs(rows,2)).';expected=cell2mat(refs(rows,4)).';
  spec=lamb.models.rayleigh_lamb.core.rlMakeBranchSpec(family+"0",mat,g);
  f=om*mat.CT/(2*pi*g.halfThickness);roots=nan(3,numel(f));
  for j=1:3
   options=lamb.models.rayleigh_lamb.rlDefaultOptions(profiles(j));
   cp=lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch(f,spec,options);
   roots(j,:)=om.*mat.CT./cp;
   oracleError=abs(roots(j,:)-expected)./eps(expected);
   fprintf('Profile %s nu=%.4g %s: finite=%d/%d, oracle=%.3g ULP\n',profiles(j),nu,family,nnz(isfinite(cp)),numel(cp),max(oracleError));
   assert(all(isfinite(cp)), 'Execution profile lost reference-root coverage.');
   assert(all(oracleError<=16), 'Execution profile disagrees with independent fundamental root.');
   maxOracle=max(maxOracle,max(oracleError));
  end
  % Two results within the existing oracle budget differ by at most 32 ULP.
  spread=(max(roots,[],1)-min(roots,[],1))./eps(expected);
  assert(all(spread<=32));maxSpread=max(maxSpread,max(spread));
 end
end
p.mu=25e3;p.nu=.4999;p.thickness=1e-3;p.frequencySpacing="explicit";
p.frequencyVector_Hz=[10 6166.45601805833 16000];p.fmin=10;p.fmax=16000;
pathology=nan(3,3);
for j=1:3
 options=lamb.models.rayleigh_lamb.rlDefaultOptions(profiles(j));options.computeS0=true;
 result=lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(p,options);
 pathology(j,:)=result.modes.S0.phaseVelocity_mps(:).';
 % Existing independently certified pathology reference and error budget.
 assert(all(isfinite(pathology(j,:))) && abs(pathology(j,2)-4.83137673339218)<2e-13);
end
assert(all(max(pathology,[],1)-min(pathology,[],1)<=32*eps(pathology(1,:))));
fprintf('Profile invariance: maximum oracle %.3g ULP, spread %.3g ULP; pathology spread %.3g m/s.\n',maxOracle,maxSpread,max(max(pathology,[],1)-min(pathology,[],1)));
end
function mustError(fn,id)
try,fn();catch ME,assert(strcmp(ME.identifier,id),ME.message);return;end
error('Expected error %s.',id);
end
