function test_mrlfe_seed_refinement_stability()
% A separately computed 80-digit root constrains seed-dependent refinement.
req=struct('branch',"A0Like",'frequency_Hz',(1000:50:1400).', ...
 'material',struct('mu_Pa',75e3,'etaS_Pas',0,'rho_kgm3',1000,'nu',.4999), ...
 'geometry',struct('thickness_m',.5e-3), ...
 'fluid',struct('density_kgm3',1000,'soundSpeed_mps',1500), ...
 'numerics',struct('preset',"fast"),'selection',struct('strategy',"adaptive"), ...
 'termination',struct('policy',"physicalTail"),'fallback',struct('policy',"none"));
c=lamb.models.mrlfe.configuration.mrlfeResolveConfiguration(req);p=lamb.models.mrlfe.core.mrlfeBuildProblem(c);
seed=lamb.models.mrlfe.tracking.mrlfeBuildSeed(p,c);o=c.internalOptions;mp=o.mrlfeParams;mp.etaS=0;mp.etaL=0;mp.useComplexLambda=false;mp.solveComplexK=false;
% det of the original 5x5 boundary matrix, exact production-rounded inputs.
reference=3.107674790102625983913928098138884924757708382480460860893333449895814;
cp=[];
for perturbation=[-1e-5 -1e-6 0 1e-6 1e-5]
 s=seed;s.Cp=s.Cp*(1+perturbation);s.k=s.omega./s.Cp;s.kThickness=s.k*p.geometry.thickness;
 b=lamb.models.mrlfe.tracking.mrlfeTrackBranchRobustStart(p,s,c,mp,o);
 assert(b.validCp(1) && b.candidateRank(1)==1 && b.candidateType(1)=="localMinimum");
 cp(end+1)=b.Cp(1);
end
assert(all(abs(cp-reference)<1e-8) && range(cp)<1e-8);
fprintf('mRLFE selected-root refinement is stable against controlled seed perturbations.\n');
end
