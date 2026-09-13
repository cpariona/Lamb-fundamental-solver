function test_rl_degeneracy_germs()
%TEST_RL_DEGENERACY_GERMS Analytic event specifications and physical invariance.
events={struct('type','finite','family','S','m',0,'n',0), ...
    struct('type','cutoff','family','S','m',1,'n',0), ...
    struct('type','finite','family','S','m',1,'n',1), ...
    struct('type','finite','family','A','m',1,'n',0)};
for j=1:numel(events)
    f=lamb.models.rayleigh_lamb.equations.rlDegeneracyGerms(events{j});
    g=lamb.models.rayleigh_lamb.equations.rlDegeneracyGerms(events{j},[1,2i;-.3,2]);
    assert(~f.isNumericalPointClassifier && f.matrixNullity==2);
    assert(all(isfinite(f.slopes))&&diff(sort(f.slopes))>0);
    assert(isequal(f.slopes,g.slopes));
    for k=1:2
        assert(abs(det(f.MO+f.slopes(k)*f.MK))<1e-9*max(1,norm(f.MO,'fro')^2));
        assert(norm(f.fields{k}.displacement-g.fields{k}.displacement,'fro')<1e-10);
        pencil=f.MO+f.slopes(k)*f.MK;
        assert(norm(pencil*f.coefficients(:,k))<1e-10*max(1,norm(pencil,'fro')));
        if j==2
            t=f.fields{k}.t;
            expected=[-1i*cos(pi*t),sign(f.slopes(k))*sin(pi*t/2)];
            expected=expected/sqrt(trapz(t,sum(abs(expected).^2,2)));
            overlap=trapz(t,sum(conj(expected).*f.fields{k}.displacement,2));
            assert(abs(abs(overlap)-1)<1e-12);
        end
    end
    if j==1
        a=pi/2;expected=[1/sqrt(2);sqrt(2)*(a^2-1)/(a^2-2)];
        assert(norm(f.slopes-expected)<1e-12);
        u=f.fields{1}.displacement;assert(norm(u(:,2))<1e-12);
        assert(max(abs(u(:,1)-u(1,1)))<1e-12);
    elseif j==2
        assert(norm(f.slopes-[-pi/2;pi/2])<1e-12);
    end
end
fprintf('RL analytic degeneracy pencil contracts passed.\n');
end
