function [u,w,xx,zz,xz] = rlModeFieldComponents(O,K,nu,family,a,b,t,terms)
%RLMODEFIELDCOMPONENTS Regular potentials in the real traction gauge.
% Physical Ux=i*u, Uz=w, sigma_xz=i*xz. Shared by sampled reconstruction and
% certified interval integration. Complex coefficients are allowed in double.
if nargin<9,terms=100;end
family=validatestring(family,{'A','S'});
r2=(1-2*nu)/(2*(1-nu));x=r2*O^2-K^2;y=O^2-K^2;
[cx,sx]=lamb.models.rayleigh_lamb.equations.rlEntireCS(x*t.^2,terms);
[cy,sy]=lamb.models.rayleigh_lamb.equations.rlEntireCS(y*t.^2,terms);
if strcmp(family,'S')
    phi=a*cx;dp=-a*x*t.*sx;psi=b*t.*sy;ds=b*cy;
else
    phi=a*t.*sx;dp=a*cx;psi=b*cy;ds=-b*y*t.*sy;
end
u=K*phi-ds;w=dp-K*psi;D=O^2-2*K^2;
zz=-D*phi-2*K*ds;xz=2*K*dp+D*psi;
xx=-(O^2-2*r2*O^2+2*K^2)*phi+2*K*ds;
end
