function [C,S,dC,dS] = rlEntireCS(x,terms)
%RLENTIRECS Entire cos(sqrt(x)), sin(sqrt(x))/sqrt(x), and x derivatives.
% Interval Taylor sums include an explicit geometric bound on all omitted
% terms. The budget is arithmetic effort, never a physical acceptance gate.
if nargin<2,terms=100;end
validateattributes(terms,{'double'},{'scalar','integer','>=',4,'<=',400});
if isa(x,'lamb.models.rayleigh_lamb.equations.rlInterval')
    I=@(v) lamb.models.rayleigh_lamb.equations.rlInterval(v,[],x.precision);
    C=I(1);S=I(1);ct=I(1);st=I(1);dS=I(-1)/6;dt=dS;
    for n=1:terms
        ct=ct*(-x)/((2*n-1)*2*n);st=st*(-x)/(2*n*(2*n+1));C=C+ct;S=S+st;
        if nargout>=4 && n>1,dt=dt*(-x)*n/((n-1)*2*n*(2*n+1));dS=dS+dt;end
    end
    X=abs(x).endpoint(2);q=X/((2*terms+3)*(2*terms+4));
    qd=X*(terms+2)/((terms+1)*(2*terms+4)*(2*terms+5));
    assert(sign(1-q)>0 && sign(1-qd)>0,'lamb:rl:SeriesBudget','Taylor tail ratio not below one.');
    first=I(1);
    for n=1:terms+1,first=first*X/((2*n-1)*2*n);end
    tail=first/(1-q);C=C+symmetric(tail);S=S+symmetric(tail/(2*terms+3));
    if nargout>=4
        firstD=I(terms+1);
        for n=1:terms,firstD=firstD*X;end
        for n=2:2*terms+3,firstD=firstD/n;end
        dS=dS+symmetric(firstD/(1-qd));
    end
    dC=-S/2;
else
    validateattributes(x,{'double'},{'real','finite'});
    z=sqrt(complex(x));C=real(cos(z));S=ones(size(x));dS=zeros(size(x));
    near=abs(x)<1e-4;far=~near;
    S(far)=real(sin(z(far))./z(far));dS(far)=(C(far)-S(far))./(2*x(far));
    t=x(near);S(near)=1-t/6+t.^2/120-t.^3/5040+t.^4/362880;
    dS(near)=-1/6+t/60-t.^2/1680+t.^3/90720-t.^4/7983360;
    dC=-S/2;
end
end
function y=symmetric(x)
y=lamb.models.rayleigh_lamb.equations.rlInterval(x.upper.negate(),x.upper,x.precision);
end
