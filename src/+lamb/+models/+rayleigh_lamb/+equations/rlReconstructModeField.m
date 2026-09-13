function result = rlReconstructModeField(O,K,nu,family,coefficients,t,basis)
%RLRECONSTRUCTMODEFIELD Physical field in the regular potential basis.
% basis maps supplied coordinates to the canonical two potentials. Gauge is
% fixed using physical displacement, never raw coefficient overlap. Stress
% norm is the in-plane xz norm, not a three-dimensional energy norm.
if nargin<6||isempty(t),t=linspace(-1,1,401)';end
if nargin<7,basis=eye(2);end
validateattributes(t,{'double'},{'column','real','finite','increasing'});
assert(numel(t)>=2 && t(1)==-1 && t(end)==1,'lamb:rl:FieldGrid','Grid must span [-1,1].');
validateattributes(coefficients,{'double'},{'column','numel',2,'finite'});
validateattributes(basis,{'double'},{'size',[2,2],'finite'});
v=basis*coefficients;assert(any(v~=0),'lamb:rl:ZeroField','Zero mode coefficients.');
v=v/max(abs(v));
[u,uz,sxx,szz,xz]=lamb.models.rayleigh_lamb.equations.rlModeFieldComponents(O,K,nu,family,v(1),v(2),t);
ux=1i*u;sxz=1i*xz;
u=[ux;uz];[~,pivot]=max(abs(u));normU=sqrt(trapz(t,abs(ux).^2+abs(uz).^2));
assert(isfinite(normU)&&normU>0,'lamb:rl:ZeroField','Nonzero finite displacement required.');
scale=conj(u(pivot)/abs(u(pivot)))/normU;
result=struct('t',t,'displacement',scale*[ux,uz],'stress',scale*[sxx,szz,sxz], ...
    'surfaceTraction',scale*[szz([1,end]),sxz([1,end])], ...
    'coefficients',scale*v,'normalization',"unit integrated displacement; physical pivot phase");
bulk=sqrt(trapz(t,abs(sxx).^2+abs(szz).^2+2*abs(sxz).^2)/2);
result.etaT=sqrt(sum(abs(szz([1,end])).^2+abs(sxz([1,end])).^2)/2)/bulk;
% etaT here is sampled diagnostic quadrature; certification owns its bounds.
end
