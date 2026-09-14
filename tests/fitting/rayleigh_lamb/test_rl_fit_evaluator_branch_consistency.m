function test_rl_fit_evaluator_branch_consistency()
% Public output and fixed objective predictions share one model-owned identity.
p=lamb.models.rayleigh_lamb.rlDefaultParams();p.mu=90e3;
o=lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
objective=[900 1500 2600 4500 7000 9000 12000].';
contexts={objective,sort([objective;linspace(1111,11111,10).']),sort([objective;linspace(222,11999,38).'])};
for branch=["A0","S0"]
 reference=[];
 for j=1:3
  f=contexts{j};[cp,raw]=lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(p,f,branch,o);
  q=p;q.frequencySpacing="explicit";q.frequencyVector_Hz=f;q.fmin=f(1);q.fmax=f(end);
  op=o;op.computeA0=branch=="A0";op.computeS0=branch=="S0";
  r=lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(q,op);
  assert(isequal(cp,r.modes.(branch).phaseVelocity_mps));
  assert(raw.trackingMode=="canonical_public_solver" && ~raw.reliability.SelectionFallbackUsed);
  [~,ix]=ismember(objective,f);if j==1,reference=cp(ix);end
  assert(isequal(reference,cp(ix)) && all(raw.validMask));
  ex=struct('frequency_Hz',f,'Cp_mps',cp,'validMask',ismember(f,objective));
  [~,info]=lamb.fitting.computeDispersionFitResiduals(cp,ex,struct());
  assert(nnz(info.validMask)==7 && isequal(info.validMask,ex.validMask));
 end
end
fprintf('RL canonical public/fitting equality and 7/17/45 fixed observations passed.\n');
end
