function test_rl_interval_primitives()
%TEST_RL_INTERVAL_PRIMITIVES Public Java directed bounds and entire tails.
I=@lamb.models.rayleigh_lamb.equations.rlInterval;
assert(I(.1).contains('0.1000000000000000055511151231257827021181583404541015625'));
r=I(1)/3;assert(r.contains('0.3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333'));
r=sqrt(I(2));assert(r.contains('1.4142135623730950488016887242096980785696718753769480731766797379907324784621070388503875343276415727350138'));
p=lamb.models.rayleigh_lamb.equations.rlPiInterval();
assert(p.contains('3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821481'));
references=rlEntireFunctionReferences();
for j=1:3:size(references,1)
    [c,s,~,ds]=lamb.models.rayleigh_lamb.equations.rlEntireCS(I(references{j,1}));
    assert(c.contains(references{j,3}));assert(s.contains(references{j+1,3}));
    assert(ds.contains(references{j+2,3}));
end
% Independent 100-digit references, computed symbolically outside production.
[c,s,dc,ds]=lamb.models.rayleigh_lamb.equations.rlEntireCS(I(-200));
assert(c.contains('693140.8076477517856896784819911677131367377551679127544259369190928322395462715214053538720157731531'));
assert(s.contains('49012.45654043355743809114380953696638360018849835139942876738011715914224117388452754512230357842244'));
assert(ds.contains('-1610.320877768295570628968345454076866882843916673903387492923847439182743262744092194521874280487'));
assert(dc.contains('-24506.22827021677871904557190476848319180009424917569971438369005857957112058694226377256115178921122'));
[c,s,dc,ds]=lamb.models.rayleigh_lamb.equations.rlEntireCS(I(0));
assert(c.contains(1)&&s.contains(1)&&dc.contains(-.5));r=ds*6;assert(r.contains(-1));
x=I(-2,3);r=x^2;assert(r.contains(I(0,9)));r=x-I(1);assert(r.contains(I(-3,2)));
failed=false;try,I(1)/x;catch ex,failed=strcmp(ex.identifier,'lamb:rl:IntervalDomain');end;assert(failed);
assert(I(1).rounded());[ok,v]=I(1,2).rounded();assert(~ok&&isnan(v));
% Exact power-of-two neighbors protect subnormals and binade boundaries.
for x=[0,realmin,1,2,-1]
    [ok,v]=I(x).rounded();assert(ok&&v==x);
end
fprintf('RL directed interval primitive contracts passed.\n');
end
