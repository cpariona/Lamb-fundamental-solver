function [M,MO,MK] = rlBoundaryMatrix(O,K,nu,family,terms)
%RLBOUNDARYMATRIX Regular real-gauge RL boundary operator, h=half thickness.
% Accepts real scalars or RL scalar intervals. Intervals return 2-by-2 cells;
% doubles return numeric matrices. The equations and derivatives are shared.
if nargin<5,terms=100;end
family=validatestring(family,{'A','S'});
if isnumeric(O),validateattributes(O,{'double'},{'scalar','real','finite','nonnegative'});end
if isnumeric(K),validateattributes(K,{'double'},{'scalar','real','finite'});end
if isnumeric(nu),validateattributes(nu,{'double'},{'scalar','real','>',-1,'<',0.5});end
r2=(1-2*nu)/(2*(1-nu));x=r2*O^2-K^2;y=O^2-K^2;D=O^2-2*K^2;
[cx,sx,dcx,dsx]=lamb.models.rayleigh_lamb.equations.rlEntireCS(x,terms);
[cy,sy,dcy,dsy]=lamb.models.rayleigh_lamb.equations.rlEntireCS(y,terms);
if strcmp(family,'S'),M={-D*cx,-2*K*cy;-2*K*x*sx,D*sy};
else,M={-D*sx,2*K*y*sy;2*K*cx,D*cy};end
MO=derivative(2*r2*O,2*O,2*O,0);MK=derivative(-2*K,-2*K,-4*K,1);
if isnumeric(x),M=cell2mat(M);MO=cell2mat(MO);MK=cell2mat(MK);end
    function B=derivative(dx,dy,dD,dK)
        if strcmp(family,'S')
            B={-dD*cx-D*dcx*dx,-2*dK*cy-2*K*dcy*dy; ...
                -2*dK*x*sx-2*K*(sx+x*dsx)*dx,dD*sy+D*dsy*dy};
        else
            B={-dD*sx-D*dsx*dx,2*dK*y*sy+2*K*(sy+y*dsy)*dy; ...
                2*dK*cx+2*K*dcx*dx,dD*cy+D*dcy*dy};
        end
    end
end
