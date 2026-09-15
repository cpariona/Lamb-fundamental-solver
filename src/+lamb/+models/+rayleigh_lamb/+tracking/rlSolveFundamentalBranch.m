function [Cp, residual, trace] = rlSolveFundamentalBranch(frequency, spec, options)
%RLSOLVEFUNDAMENTALBRANCH Continue the physical low-frequency fundamental.
% Requested frequencies consume support; predictions never become outputs.
O=2*pi*frequency(:).'*spec.h/spec.CT;
Cp=nan(size(O));residual=nan(size(O));
family=extractBefore(spec.name,2);nu=spec.nu;
eq=@(o,k)lamb.models.rayleigh_lamb.equations.rlBoundaryEquation(o,k,nu,family);
start=1e-5;
% Existing profile density controls continuation effort, not root identity.
maxStep=.04*300/options.gridPointsTracking;
if family=="A",seed=sqrt(start)/(4/3*(1-spec.r2))^.25;
else,seed=start/(2*sqrt(1-spec.r2));end
[k,sl,ok]=correct(eq,start,seed,.1*seed);
os=start;ks=k;slopes=sl;steps=0;
while ok && os(end)<max(O) && steps<100000
    a=os(end);ka=ks(end);sa=slopes(end);
    h=min(maxStep,.15*a);accepted=false;
    for attempt=1:40
        pred=ka+h*sa;radius=max(abs(h*sa),eps(ka))*.2;
        [kb,sb,good]=correct(eq,a+h,pred,radius);
        % Tangent consistency bounds each continuation step; never rerank.
        if good && abs(sb-sa)*h<=.2*max(abs(kb-ka),eps(ka))
            accepted=true;break;
        end
        h=h/2;
        if h<32*eps(a),break;end
    end
    if ~accepted,break;end
    os(end+1)=a+h;ks(end+1)=kb;slopes(end+1)=sb;steps=steps+1;
end
for j=1:numel(O)
    if ~ok || O(j)>os(end),continue;end
    if O(j)<start
        if family=="A",pred=sqrt(O(j))/(4/3*(1-spec.r2))^.25;
        else,pred=O(j)/(2*sqrt(1-spec.r2));end
        radius=.1*pred;
    else
        ix=find(os<=O(j),1,'last');d=O(j)-os(ix);
        pred=ks(ix)+d*slopes(ix);
        radius=max(.2*abs(d*slopes(ix)),64*eps(ks(ix)));
    end
    [root,~,good,err]=correct(eq,O(j),pred,radius);
    if good,Cp(j)=spec.CT*O(j)/root;residual(j)=err;end
end
trace=struct('Omega',os,'K',ks,'slope',slopes,'identity',"low-frequency analytic continuation");
end

function [k,slope,ok,errorEstimate]=correct(eq,O,seed,radius)
k=seed;slope=nan;ok=false;errorEstimate=nan;
for iteration=1:16
    [f,fk,fo]=eq(O,k);
    if ~all(isfinite([f fk fo])) || fk==0,return;end
    change=f/fk;
    if abs(change)<=8*eps(k)
        slope=-fo/fk;errorEstimate=abs(change)/max(abs(k),realmin);
        ok=k>0;return;
    end
    next=k-change;
    if next<=0 || abs(next-seed)>radius,return;end
    k=next;
end
end
