function test_rl_dimensional_certification()
%TEST_RL_DIMENSIONAL_CERTIFICATION Full physical-to-root-to-physical inclusion.
cases=rlDimensionalRootReferences();
for j=1:size(cases,1)
    p=struct('mu',hex2num(cases{j,1}),'rho',hex2num(cases{j,2}), ...
        'nu',hex2num(cases{j,3}),'thickness',hex2num(cases{j,4}), ...
        'frequency',hex2num(cases{j,5}));
    seed=hex2num(cases{j,7});bracket=seed+[-1,1]*1e-10*max(1,abs(seed));
    options=struct('precision',50,'terms',48,'integrationCells',64);
    r=lamb.models.rayleigh_lamb.equations.rlCertifyDimensionalRoot(p,cases{j,6},bracket,options);
    assert(r.certified,'Dimensional case %d: %s',j,r.reason);
    assert(r.KInterval.contains(cases{j,8}));
    assert(r.kInterval.contains(cases{j,9}));
    assert(r.CpInterval.contains(cases{j,10}));
    if r.kCorrectlyRounded,assert(r.k==str2double(cases{j,9}));else,assert(isnan(r.k));end
    if r.CpCorrectlyRounded,assert(r.Cp==str2double(cases{j,10}));else,assert(isnan(r.Cp));end
    fprintf('Dimensional certified case %d: K/k/Cp inclusions; rounding k=%d Cp=%d\n',j,r.kCorrectlyRounded,r.CpCorrectlyRounded);
end
fprintf('RL dimensional certification contracts passed.\n');
end
