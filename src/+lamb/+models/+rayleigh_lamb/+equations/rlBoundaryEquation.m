function [F, FK, FO, M, MO, MK] = rlBoundaryEquation(O, K, nu, family)
%RLBOUNDARYEQUATION Regular RL equation with the static Omega^2 factor removed.
% O=omega*h/CT, K=k*h; h is HALF the physical thickness. C(x) and S(x)
% are entire cos(sqrt(x)) and sin(sqrt(x))/sqrt(x). No tangent poles occur.
% The divided difference avoids subtracting the static gauge terms at low O.
r2 = (1-2*nu)/(2*(1-nu));
x = r2*O^2-K^2; y = O^2-K^2;
[cx,sx,dx] = entire(x); [cy,sy,dy] = entire(y);
[w,wx,wy] = divided(x,y,cx,sx,dx,cy,sy,dy);
xo=2*r2*O; yo=2*O; xk=-2*K; yk=xk;
u=sx*cy; ux=dx*cy; uy=-sx*sy/2;
v=cx*sy; vx=-sx*sy/2; vy=cx*dy;
wo=wx*xo+wy*yo; wk=wx*xk+wy*yk;
t=4*(1-r2);
if family == "A"
    F=O^2*u-t*K^2*y*w;
    FO=2*O*u+O^2*(ux*xo+uy*yo)-t*K^2*(yo*w+y*wo);
    FK=O^2*(ux*xk+uy*yk)-t*(2*K*y*w+K^2*(yk*w+y*wk));
else
    z=u-y*w;
    F=O^2*v-t*K^2*z;
    FO=2*O*v+O^2*(vx*xo+vy*yo)-t*K^2*(ux*xo+uy*yo-yo*w-y*wo);
    FK=O^2*(vx*xk+vy*yk)-t*(2*K*z+K^2*(ux*xk+uy*yk-yk*w-y*wk));
end
if nargout < 4, return; end
D=O^2-2*K^2;
if family == "A"
    M=[-D*sx,2*K*y*sy;2*K*cx,D*cy];
    MO=[-2*O*sx-D*dx*xo,2*K*yo*(sy+y*dy);-K*sx*xo,2*O*cy-D*sy*yo/2];
    MK=[4*K*sx-D*dx*xk,2*y*sy+2*K*yk*(sy+y*dy);2*cx-K*sx*xk,-4*K*cy-D*sy*yk/2];
else
    M=[-D*cx,-2*K*cy;-2*K*x*sx,D*sy];
    MO=[-2*O*cx+D*sx*xo/2,K*sy*yo;-2*K*xo*(sx+x*dx),2*O*sy+D*dy*yo];
    MK=[4*K*cx+D*sx*xk/2,-2*cy+K*sy*yk;-2*x*sx-2*K*xk*(sx+x*dx),-4*K*sy+D*dy*yk];
end
end

function [c,s,ds] = entire(x)
persistent cc ss dd
if isempty(cc)
    j=9:-1:0;cc=(-1).^j./factorial(2*j);ss=(-1).^j./factorial(2*j+1);
    dd=j(1:end-1).*ss(1:end-1);
end
if abs(x) < 1
    % Degree 9 leaves less than 1/20! in C on this interval.
    c=polyval(cc,x);s=polyval(ss,x);ds=polyval(dd,x);
else
    if x>0,q=sqrt(x);c=cos(q);s=sin(q)/q;
    else,q=sqrt(-x);c=cosh(q);s=sinh(q)/q;end
    ds=(c-s)/(2*x);
end
end

function [w,wx,wy] = divided(x,y,cx,sx,dx,cy,sy,dy)
% (C(x)S(y)-S(x)C(y))/(x-y), continued analytically at x=y.
persistent aa px py
if isempty(aa)
    aa=[];px=[];py=[];
    for i=1:9
        for j=0:i-1
            a=(-1)^(i+j)*(1/(factorial(2*i)*factorial(2*j+1))-1/(factorial(2*i+1)*factorial(2*j)));
            for k=0:i-j-1
                aa(end+1)=a;px(end+1)=i-1-k;py(end+1)=j+k;
            end
        end
    end
end
if max(abs([x y])) < 1
    w=sum(aa.*x.^px.*y.^py);
    wx=sum(aa.*px.*x.^max(px-1,0).*y.^py);
    wy=sum(aa.*py.*x.^px.*y.^max(py-1,0));
else
    d=x-y;w=(cx*sy-sx*cy)/d;
    wx=(-sx*sy/2-dx*cy-w)/d;
    wy=(cx*dy+sx*sy/2+w)/d;
end
end
