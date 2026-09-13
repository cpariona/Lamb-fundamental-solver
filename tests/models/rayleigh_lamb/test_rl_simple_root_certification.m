function test_rl_simple_root_certification()
%TEST_RL_SIMPLE_ROOT_CERTIFICATION Isolation, reference inclusion, no fallback.
cases=rlCertifiedRootReferences();indices=[1,5,9,13];
for j=indices
    nu=hex2num(cases{j,1});O=hex2num(cases{j,2});seed=hex2num(cases{j,3});
    bracket=seed+[-1,1]*1e-10*max(1,abs(seed));
    options=struct('precision',50,'terms',48,'integrationCells',64);
    r=lamb.models.rayleigh_lamb.equations.rlCertifyModeRoot(O,nu,cases{j,4},bracket,options);
    assert(r.certified&&r.correctlyRounded&&r.nonzeroField);
    assert(r.KInterval.contains(cases{j,5}));
    assert(r.K==str2double(cases{j,5}));assert(~isempty(r.etaTInterval));
    fprintf('Simple root reference %d certified and rounded.\n',j);
    if j==9
        options.leftBasis=[1e-3,2;-.3e-3,1];options.rightBasis=[1,.2e3;-.1,1e3];
        q=lamb.models.rayleigh_lamb.equations.rlCertifyModeRoot(O,nu,cases{j,4},bracket,options);
        assert(q.certified&&q.K==r.K);
    end
end
r=lamb.models.rayleigh_lamb.equations.rlCertifyModeRoot(2,.2,'S',[0,.001]);
assert(~r.certified&&isnan(r.K)&&r.status=="not_certified");
r=lamb.models.rayleigh_lamb.equations.rlCertifyModeRoot(.02,-.9,'A',[.185,.186]);
assert(~r.certified&&r.reason=="uniqueness_not_proved"&&isnan(r.K));
fprintf('RL simple-root certification contracts passed.\n');
end
