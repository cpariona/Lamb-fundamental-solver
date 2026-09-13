classdef rlInterval
    %RLINTERVAL Scalar outward decimal bounds for Rayleigh-Lamb certification.
    % Public Java BigDecimal operations use FLOOR/CEILING MathContexts.
    % Constructors from double preserve the exact binary value (not num2str).
    % No global rounding state, symbolic runtime, or third-party dependency.
    properties (SetAccess = private)
        lower
        upper
        precision
    end
    methods
        function a = rlInterval(lo, hi, precision)
            if nargin == 0, lo = 0; end
            if nargin < 3, precision = 80; end
            if isa(lo, 'lamb.models.rayleigh_lamb.equations.rlInterval')
                a = lo; return;
            end
            if nargin < 2 || isempty(hi), hi = lo; end
            validateattributes(precision, {'double'}, {'scalar','integer','>=',24,'<=',512});
            a.lower = decimal(lo); a.upper = decimal(hi); a.precision = precision;
            assert(a.lower.compareTo(a.upper) <= 0, 'lamb:rl:IntervalOrder', 'Reversed interval.');
        end
        function z = plus(a,b)
            [a,b] = pair(a,b); [dn,up] = contexts(a.precision);
            z = make(a.lower.add(b.lower,dn),a.upper.add(b.upper,up),a.precision);
        end
        function z = uminus(a)
            z = make(a.upper.negate(),a.lower.negate(),a.precision);
        end
        function z = minus(a,b), [a,b]=pair(a,b); z=a+(-b); end
        function z = mtimes(a,b)
            [a,b]=pair(a,b); [dn,up]=contexts(a.precision);
            % Monotonic endpoint selection is exact when signs are known.
            % Only two products are necessary; crossing-zero cases use four.
            if a.lower.signum()>=0 && b.lower.signum()>=0
                z=make(a.lower.multiply(b.lower,dn),a.upper.multiply(b.upper,up),a.precision);return;
            elseif a.upper.signum()<=0 && b.upper.signum()<=0
                z=make(a.upper.multiply(b.upper,dn),a.lower.multiply(b.lower,up),a.precision);return;
            elseif a.lower.signum()>=0 && b.upper.signum()<=0
                z=make(a.upper.multiply(b.lower,dn),a.lower.multiply(b.upper,up),a.precision);return;
            elseif a.upper.signum()<=0 && b.lower.signum()>=0
                z=make(a.lower.multiply(b.upper,dn),a.upper.multiply(b.lower,up),a.precision);return;
            end
            aa={a.lower,a.upper}; bb={b.lower,b.upper}; lo=[]; hi=[];
            for i=1:2
                for j=1:2
                    l=aa{i}.multiply(bb{j},dn); h=aa{i}.multiply(bb{j},up);
                    if isempty(lo) || l.compareTo(lo)<0, lo=l; end
                    if isempty(hi) || h.compareTo(hi)>0, hi=h; end
                end
            end
            z=make(lo,hi,a.precision);
        end
        function z = times(a,b), z=mtimes(a,b); end
        function z = mrdivide(a,b)
            [a,b]=pair(a,b); assert(sign(b)~=0,'lamb:rl:IntervalDomain','Division contains zero.');
            [dn,up]=contexts(a.precision); one=decimal(1);
            z=a*make(one.divide(b.upper,dn),one.divide(b.lower,up),a.precision);
        end
        function z = rdivide(a,b), z=mrdivide(a,b); end
        function z = mpower(a,n)
            validateattributes(n,{'double'},{'scalar','integer','nonnegative','<=',2048});
            if n==2
                [dn,up]=contexts(a.precision);
                ll=a.lower.multiply(a.lower,dn); hh=a.upper.multiply(a.upper,dn);
                lu=a.lower.multiply(a.lower,up); hu=a.upper.multiply(a.upper,up);
                if sign(a)==0, lo=decimal(0); elseif ll.compareTo(hh)<0,lo=ll;else,lo=hh;end
                if lu.compareTo(hu)>0,hi=lu;else,hi=hu;end
                z=make(lo,hi,a.precision); return;
            end
            z=make(decimal(1),decimal(1),a.precision);
            for k=1:n,z=z*a;end
        end
        function z = power(a,n), z=mpower(a,n); end
        function z = sqrt(a)
            assert(a.lower.signum()>=0,'lamb:rl:IntervalDomain','Square root contains negative values.');
            [lo,~]=sqrtPoint(a.lower,a.precision); [~,hi]=sqrtPoint(a.upper,a.precision);
            z=make(lo,hi,a.precision);
        end
        function s = sign(a)
            s=0; if a.lower.signum()>0,s=1;elseif a.upper.signum()<0,s=-1;end
        end
        function z = abs(a)
            if sign(a)>0,z=a;elseif sign(a)<0,z=-a;else
                hi=a.lower.abs().max(a.upper.abs());z=make(decimal(0),hi,a.precision);
            end
        end
        function z = midpoint(a)
            % Exact terminating decimal average; independent of context.
            m=a.lower.add(a.upper).divide(decimal(2)); z=make(m,m,a.precision);
        end
        function z = endpoint(a,which)
            if which==1,v=a.lower;else,v=a.upper;end
            z=make(v,v,a.precision);
        end
        function v = double(a), v=a.midpoint().lower.doubleValue(); end
        function [ok,v] = rounded(a)
            v=double(a); ok=false;
            if ~isfinite(v), v=NaN;return;end
            prev=javaMethod('nextAfter','java.lang.Math',v,-Inf);
            next=javaMethod('nextAfter','java.lang.Math',v,Inf);
            if ~isfinite(prev)||~isfinite(next),v=NaN;return;end
            lo=decimal(prev).add(decimal(v)).divide(decimal(2));
            hi=decimal(next).add(decimal(v)).divide(decimal(2));
            ok=a.lower.compareTo(lo)>0 && a.upper.compareTo(hi)<0;
            if ~ok,v=NaN;end
        end
        function b = bounds(a)
            b=[a.lower.doubleValue(),a.upper.doubleValue()];
            if b(1)==Inf,b(1)=realmax;end
            if b(2)==-Inf,b(2)=-realmax;end
            if isfinite(b(1)) && decimal(b(1)).compareTo(a.lower)>0
                b(1)=javaMethod('nextAfter','java.lang.Math',b(1),-Inf);
            end
            if isfinite(b(2)) && decimal(b(2)).compareTo(a.upper)<0
                b(2)=javaMethod('nextAfter','java.lang.Math',b(2),Inf);
            end
        end
        function s = decimalBounds(a), s=[string(a.lower.toString()),string(a.upper.toString())]; end
        function tf = contains(a,b)
            [a,b]=pair(a,b);tf=a.lower.compareTo(b.lower)<=0 && a.upper.compareTo(b.upper)>=0;
        end
    end
end
function a=decimal(x)
if isa(x,'java.math.BigDecimal'),a=x;
elseif ischar(x)||isstring(x),a=javaObject('java.math.BigDecimal',char(x));
else
    validateattributes(x,{'double'},{'scalar','real','finite'});
    a=javaObject('java.math.BigDecimal',x);
end
end
function z=make(lo,hi,p)
z=lamb.models.rayleigh_lamb.equations.rlInterval(lo,hi,p);
end
function [a,b]=pair(a,b)
if isa(a,'lamb.models.rayleigh_lamb.equations.rlInterval'),p=a.precision;else,p=b.precision;end
if ~isa(a,'lamb.models.rayleigh_lamb.equations.rlInterval'),a=make(decimal(a),decimal(a),p);end
if ~isa(b,'lamb.models.rayleigh_lamb.equations.rlInterval'),b=make(decimal(b),decimal(b),p);end
assert(a.precision==b.precision,'lamb:rl:IntervalPrecision','Mixed arithmetic precision.');
end
function [dn,up]=contexts(p)
persistent lastPrecision floorContext ceilingContext
if isempty(lastPrecision)||lastPrecision~=p
    floorContext=javaObject('java.math.MathContext',int32(p),javaMethod('valueOf','java.math.RoundingMode','FLOOR'));
    ceilingContext=javaObject('java.math.MathContext',int32(p),javaMethod('valueOf','java.math.RoundingMode','CEILING'));
    lastPrecision=p;
end
dn=floorContext;up=ceilingContext;
end
function [lo,hi]=sqrtPoint(x,p)
% Decimal bisection, exact squares and comparisons; no floating sqrt claim.
% 10^ceil(decimalExponent/2) is an upper bound. Each midpoint terminates.
if x.signum()==0,lo=x;hi=x;return;end
e=double(x.precision())-double(x.scale());
hi=decimal(1).scaleByPowerOfTen(int32(ceil(e/2)));lo=decimal(0);
for k=1:ceil(3.322*(p+3))+8
    mid=lo.add(hi).divide(decimal(2));sq=mid.multiply(mid);
    if sq.compareTo(x)<=0,lo=mid;else,hi=mid;end
end
[dn,up]=contexts(p);lo=lo.round(dn);hi=hi.round(up);
end
