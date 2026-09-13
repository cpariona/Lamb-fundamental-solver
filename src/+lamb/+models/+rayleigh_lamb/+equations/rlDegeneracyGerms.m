function result = rlDegeneracyGerms(event,basis)
%RLDEGENERACYGERMS Analytically specified nullity-two event, not rank snapping.
% event = struct(type='finite' or 'cutoff',family='S' or 'A',m,n).
% Integer phase conditions define the exact event; returned doubles approximate
% that event and MUST NOT classify a nearby numerical request as degenerate.
% Signed K continuation at cutoffs is intentional. No global mode is selected.
if nargin<2,basis=eye(2);end
family=validatestring(event.family,{'A','S'});kind=validatestring(event.type,{'finite','cutoff'});
validateattributes(event.m,{'double'},{'scalar','integer','nonnegative','<=',1000});
validateattributes(event.n,{'double'},{'scalar','integer','nonnegative','<=',1000});
validateattributes(basis,{'double'},{'size',[2,2],'finite'});
assert(det(basis)~=0,'lamb:rl:DegeneracyBasis','Basis must be invertible.');
m=event.m;n=event.n;
if strcmp(kind,'finite')
    if strcmp(family,'S'),K=(m+.5)*pi;P=n*pi;else,K=m*pi;P=(n+.5)*pi;end
    assert(K>0 && (P/K)^2<.5,'lamb:rl:DegeneracyDomain','Event outside physical material domain.');
    b2=(P/K)^2;nu=-b2/(1-b2);O=sqrt(2)*K;r2=(1+b2)/2;
    if P==0
        slopes=[1/sqrt(2);sqrt(2)*(K^2-1)/(K^2-2)];
    else
        slopes=sort(roots([K^2-4,sqrt(2)*(4-(1+r2)*K^2),2*(r2*K^2-1)]));
    end
else
    if strcmp(family,'S'),O=m*pi;P=(n+.5)*pi;else,O=(m+.5)*pi;P=n*pi;end
    assert(O>0 && P>0 && (P/O)^2<.75,'lamb:rl:DegeneracyDomain','Event outside physical material domain.');
    r2=(P/O)^2;nu=(1-2*r2)/(2*(1-r2));K=0;slopes=[-O/2;O/2];
end
[~,MO,MK]=lamb.models.rayleigh_lamb.equations.rlBoundaryMatrix(O,K,nu,family);
fields=cell(2,1);vectors=zeros(2,2);
for j=1:2
    % Slopes originate in the analytic phase conditions, not a rank tolerance.
    % SVD only reconstructs the finite-precision limiting field representation.
    [~,~,V]=svd((MO+slopes(j)*MK)*basis);v=V(:,end);vectors(:,j)=v;
    fields{j}=lamb.models.rayleigh_lamb.equations.rlReconstructModeField(O,K,nu,family,v,[],basis);
end
result=struct('event',event,'classification',"analytic integer phase conditions", ...
    'Omega',O,'K',K,'nu',nu,'matrixNullity',2,'slopes',slopes, ...
    'MO',MO,'MK',MK,'coefficients',vectors,'fields',{fields}, ...
    'isNumericalPointClassifier',false);
end
