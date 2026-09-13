function result = rlCertifyDimensionalRoot(parameters,family,bracket,options)
%RLCERTIFYDIMENSIONALROOT Certified physical inputs through Cp and k.
% thickness is full thickness in metres; mu Pa, rho kg/m^3, frequency Hz.
% Inputs are exact supplied binary doubles, not exact decimal measurements.
% The caller supplies a dimensionless branch-local bracket; no mode selection.
if nargin<4,options=struct;end
precision=80;if isfield(options,'precision'),precision=options.precision;end
I=@(v) lamb.models.rayleigh_lamb.equations.rlInterval(v,[],precision);
for field=["mu","rho","thickness","frequency"]
    validateattributes(parameters.(field),{'double'},{'scalar','real','finite','positive'});
end
validateattributes(parameters.nu,{'double'},{'scalar','real','>',-1,'<',0.5});
mu=I(parameters.mu);rho=I(parameters.rho);nu=I(parameters.nu);
h=I(parameters.thickness)/2;CT=sqrt(mu/rho);CL=sqrt(2*mu*(1-nu)/(rho*(1-2*nu)));
piBound=lamb.models.rayleigh_lamb.equations.rlPiInterval(precision);
omega=2*piBound*I(parameters.frequency);O=omega*h/CT;
result=lamb.models.rayleigh_lamb.equations.rlCertifyModeRoot(O,nu,family,bracket,options);
result.CTInterval=CT;result.CLInterval=CL;result.halfThicknessInterval=h;
result.OmegaInterval=O;result.k=NaN;result.Cp=NaN;
result.kInterval=[];result.CpInterval=[];result.kCorrectlyRounded=false;result.CpCorrectlyRounded=false;
if ~result.certified,return;end
if sign(result.KInterval)<=0
    result.certified=false;result.status="not_certified";result.reason="positive_wavenumber_not_proved";result.K=NaN;return;
end
result.kInterval=result.KInterval/h;result.CpInterval=omega/result.kInterval;
[result.kCorrectlyRounded,result.k]=result.kInterval.rounded();
[result.CpCorrectlyRounded,result.Cp]=result.CpInterval.rounded();
% Interval evidence remains usable when either physical rounding cell is not
% yet proved. A midpoint is never returned as though it were certified Cp.
end
