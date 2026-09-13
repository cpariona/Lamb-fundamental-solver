function [F,FK] = rlBoundaryDeterminant(O,K,nu,family,terms,left,right)
%RLBOUNDARYDETERMINANT Determinant and K derivative, optional real LMR gauge.
% A complex gauge is unnecessary for real-root sign isolation; physical
% complex basis invariance is tested in field reconstruction separately.
if nargin<5,terms=100;end
if nargin<6,left=eye(2);end
if nargin<7,right=eye(2);end
[M,~,B]=lamb.models.rayleigh_lamb.equations.rlBoundaryMatrix(O,K,nu,family,terms);
validateattributes(left,{'double'},{'size',[2,2],'real','finite'});
validateattributes(right,{'double'},{'size',[2,2],'real','finite'});
if ~iscell(M)
    M=left*M*right;B=left*B*right;
    F=det(M);FK=B(1,1)*M(2,2)+M(1,1)*B(2,2)-B(1,2)*M(2,1)-M(1,2)*B(2,1);return;
end
M=transform(M,left,right);B=transform(B,left,right);
F=M{1,1}*M{2,2}-M{1,2}*M{2,1};
FK=B{1,1}*M{2,2}+M{1,1}*B{2,2}-B{1,2}*M{2,1}-M{1,2}*B{2,1};
end
function B=transform(M,L,R)
B=cell(2);
for i=1:2
    for j=1:2
        v=0;
        for a=1:2
            for b=1:2,v=v+L(i,a)*M{a,b}*R(b,j);end
        end
        B{i,j}=v;
    end
end
end
