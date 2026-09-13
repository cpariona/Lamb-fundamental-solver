function p = rlPiInterval(precision,terms)
%RLPIINTERVAL Machin identity, alternating rational atan tails.
if nargin<1,precision=80;end
if nargin<2,terms=100;end
validateattributes(terms,{'double'},{'scalar','integer','>=',4,'<=',1000});
I=@(v) lamb.models.rayleigh_lamb.equations.rlInterval(v,[],precision);
p=16*atanBound(I(1)/5)-4*atanBound(I(1)/239);
    function a=atanBound(x)
        a=I(0);power=x;
        for n=0:terms-1,a=a+(-1)^n*power/(2*n+1);power=power*x^2;end
        tail=power/(2*terms+1);
        if mod(terms,2)==0
            remainder=lamb.models.rayleigh_lamb.equations.rlInterval(0,tail.upper,precision);
        else
            remainder=lamb.models.rayleigh_lamb.equations.rlInterval(tail.upper.negate(),0,precision);
        end
        a=a+remainder;
    end
end
