function result = rlCertifyModeRoot(O,nu,family,bracket,options)
%RLCERTIFYMODEROOT Certify a supplied local simple root; never choose identity.
% Parameter intervals prove a unique root for EVERY enclosed parameter value.
% Uncertified output has no fabricated K; an isolated interval may be valid
% even when the arithmetic/bisection budget cannot establish binary rounding.
if nargin<5,options=struct;end
p=getOption('precision',80);terms=getOption('terms',100);budget=getOption('bisections',100);
cells=getOption('integrationCells',64);L=getOption('leftBasis',eye(2));R=getOption('rightBasis',eye(2));
validateattributes(budget,{'double'},{'scalar','integer','nonnegative','<=',1000});
validateattributes(cells,{'double'},{'scalar','integer','positive','<=',4096});
I=@(v) lamb.models.rayleigh_lamb.equations.rlInterval(v,[],p);
O=I(O);nu=I(nu);
if isnumeric(bracket)
    validateattributes(bracket,{'double'},{'vector','numel',2,'real','finite'});
    bracket=lamb.models.rayleigh_lamb.equations.rlInterval(bracket(1),bracket(2),p);
end
result=struct('certified',false,'status',"not_certified",'reason',"",'K',NaN, ...
    'correctlyRounded',false,'KInterval',[],'etaTInterval',[], ...
    'nonzeroField',false,'evaluations',0,'bisections',0);
try
    if sign(O)<=0 || sign(nu+1)<=0 || sign(0.5-nu)<=0
        result.reason="parameter_domain";return;
    end
    lo=bracket.endpoint(1);hi=bracket.endpoint(2);
    fl=evaluate(lo);fh=evaluate(hi);
    if sign(fl)*sign(fh)~=-1,result.reason="existence_not_proved";return;end
    [~,derivative]=evaluate(bracket);
    if sign(derivative)==0,result.reason="uniqueness_not_proved";return;end
    % A nonzero determinant derivative implies rank one at the root. Its
    % nonzero null vector produces nonzero displacement: divergence/curl of
    % a zero displacement would force both Helmholtz potentials to vanish
    % when O>0 and 0<r^2<1. The norm bounds below concern the fixed physical
    % representative used for the traction-defect certificate.
    for n=0:budget
        interval=lamb.models.rayleigh_lamb.equations.rlInterval(lo.lower,hi.upper,p);
        [rounded,k]=interval.rounded();
        if rounded||n==budget,break;end
        mid=interval.midpoint();fm=evaluate(mid);
        % Mean-value interval Newton: every root in the current box lies in
        % mid-F(mid)/F'(box). Existence is inherited from the original sign
        % proof; shrinking does not assume rounded Newton is an exact root.
        contracted=mid-fm/derivative;
        newLo=lo.lower.max(contracted.lower);newHi=hi.upper.min(contracted.upper);
        assert(newLo.compareTo(newHi)<=0,'lamb:rl:EmptyContraction','Inconsistent root enclosure.');
        if newLo.compareTo(lo.lower)>0 || newHi.compareTo(hi.upper)<0
            lo=I(newLo);hi=I(newHi);
        elseif sign(fm)~=0
            if sign(fm)==sign(derivative),hi=mid;else,lo=mid;end
        else,break;
        end
    end
    result.bisections=n;result.KInterval=interval;result.derivativeInterval=derivative;
    fieldK=interval;
    if rounded
        binaryK=I(k);
        fieldK=lamb.models.rayleigh_lamb.equations.rlInterval( ...
            interval.lower.min(binaryK.lower),interval.upper.max(binaryK.upper),p);
    end
    result.fieldEvaluationKInterval=fieldK;
    % Coefficients are a fixed exact decimal vector from a midpoint row. Its
    % defect is certified over the full parameter/root interval, not assumed 0.
    M=lamb.models.rayleigh_lamb.equations.rlBoundaryMatrix(O.midpoint(),interval.midpoint(),nu.midpoint(),family,terms);
    if max(abs([double(M{1,1}),double(M{1,2})]))>=max(abs([double(M{2,1}),double(M{2,2})])),row=1;else,row=2;end
    a=-M{row,2}.midpoint();b=M{row,1}.midpoint();
    G=I(0);U=I(0);
    for j=0:cells-1
        t=lamb.models.rayleigh_lamb.equations.rlInterval(I(j).lower,I(j+1).upper,p)/cells;
        [u,w,xx,zz,xz]=lamb.models.rayleigh_lamb.equations.rlModeFieldComponents(O,fieldK,nu,family,a,b,t,terms);
        G=G+(xx^2+zz^2+2*xz^2)/cells;U=U+(u^2+w^2)/cells;
    end
    if sign(G)<=0||sign(U)<=0,result.reason="nonzero_field_not_proved";return;end
    [~,~,~,zz,xz]=lamb.models.rayleigh_lamb.equations.rlModeFieldComponents(O,fieldK,nu,family,a,b,I(1),terms);
    result.etaTInterval=sqrt((zz^2+xz^2)/G);
    result.nonzeroField=true;result.displacementNormSquaredInterval=U;
    result.stressNormSquaredInterval=G;result.certified=true;
    result.correctlyRounded=rounded;result.K=k;
    if rounded,result.status="certified_rounding";else,result.status="certified_interval";end
    result.reason="";
catch exception
    if startsWith(exception.identifier,'lamb:rl:')
        result.reason=string(exception.identifier);
    else
        rethrow(exception);
    end
end
    function v=getOption(name,default)
        if isfield(options,name),v=options.(name);else,v=default;end
    end
    function [f,d]=evaluate(k)
        [f,d]=lamb.models.rayleigh_lamb.equations.rlBoundaryDeterminant(O,k,nu,family,terms,L,R);
        result.evaluations=result.evaluations+1;
    end
end
