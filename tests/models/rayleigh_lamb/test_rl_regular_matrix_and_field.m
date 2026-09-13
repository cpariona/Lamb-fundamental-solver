function test_rl_regular_matrix_and_field()
%TEST_RL_REGULAR_MATRIX_AND_FIELD Equations, parity, gauge and limiting fields.
matrix=@lamb.models.rayleigh_lamb.equations.rlBoundaryMatrix;
field=@lamb.models.rayleigh_lamb.equations.rlReconstructModeField;
for family=["A","S"]
    for nu=[-.8,0,.2,.4999]
        O=2.1;K=.7;r2=(1-2*nu)/(2*(1-nu));P=sqrt(complex(r2*O^2-K^2));Q=sqrt(complex(O^2-K^2));D=O^2-2*K^2;
        [M,MO,MK]=matrix(O,K,nu,family);
        if family=="S"
            tangent=4*K^2*P*Q*tan(P)+D^2*tan(Q);
            equivalent=-det(M)*Q/(cos(P)*cos(Q));
        else
            tangent=4*K^2*P*Q*tan(Q)+D^2*tan(P);
            equivalent=-det(M)*P/(cos(P)*cos(Q));
        end
        assert(abs(tangent-equivalent)<1e-11*max(1,abs(tangent)));
        if family=="S"
            legacy=lamb.models.rayleigh_lamb.equations.rlSResidual(O/K,O/(2*pi),1/sqrt(r2),1,1);
        else
            legacy=lamb.models.rayleigh_lamb.equations.rlAResidual(O/K,O/(2*pi),1/sqrt(r2),1,1);
        end
        residualScale=abs(4*K^2*P*Q)+abs(D^2)+eps;
        assert(abs(legacy-abs(equivalent)/residualScale)<1e-12);
        h=1e-5;
        assert(norm((matrix(O+h,K,nu,family)-matrix(O-h,K,nu,family))/(2*h)-MO,'fro')<1e-7);
        assert(norm((matrix(O,K+h,nu,family)-matrix(O,K-h,nu,family))/(2*h)-MK,'fro')<1e-7);
        for specialK=[sqrt(r2)*O,O,0]
            [m,a,b]=matrix(O,specialK,nu,family);assert(all(isfinite([m,a,b]),'all'));
        end
        v=[1;2i];f=field(O,K,nu,family,v);g=field(O,K,nu,family,v*(3-4i));
        B=[1,2i;.2,3];q=field(O,K,nu,family,B\v,[],B);
        assert(norm(f.displacement-g.displacement,'fro')<1e-12);
        assert(norm(f.surfaceTraction-g.surfaceTraction,'fro')<1e-12);
        assert(norm(f.displacement-q.displacement,'fro')<1e-12);
        parity=1;if family=="A",parity=-1;end
        assert(norm(f.displacement(:,1)-parity*flipud(f.displacement(:,1)))<1e-12);
        assert(norm(f.displacement(:,2)+parity*flipud(f.displacement(:,2)))<1e-12);
    end
end
fprintf('RL regular matrix and physical field contracts passed.\n');
end
