function [s1, s2, rootInfo] = computeSRoots_Li2024(alpha, beta, gamma, rho, c)
%COMPUTESROOTS_LI2024 Compute s1 and s2 for the Li 2024 acoustoelastic model.
%
% The roots are obtained from Appendix Eq. A14:
%
%   gamma*s^4 - (2*beta - rho*c^2)*s^2 + (alpha - rho*c^2) = 0.
%
% The polynomial is solved in q = s^2 and then square-rooted. The two s
% roots are sorted by abs(s) to obtain a deterministic ordering.

qCoeff = [gamma, -(2*beta - rho*c^2), (alpha - rho*c^2)];
qRoots = roots(qCoeff);

sCandidates = sqrt(complex(qRoots(:)));
[~, idx] = sort(abs(sCandidates), 'ascend');
sCandidates = sCandidates(idx);
qRoots = qRoots(idx);

s1 = sCandidates(1);
s2 = sCandidates(2);

rootInfo = struct();
rootInfo.qRoots = qRoots;
rootInfo.sCandidates = sCandidates;
rootInfo.identityResidual = (2*beta - rho*c^2) - gamma*(s1^2 + s2^2);
end
