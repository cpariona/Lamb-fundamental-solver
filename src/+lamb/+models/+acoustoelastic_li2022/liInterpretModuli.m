function state = liInterpretModuli(alpha_Pa, gamma_Pa, kinematics)
%LIINTERPRETMODULI Principal stress difference and stretch ratio from moduli.
%   STATE = LIINTERPRETMODULI(ALPHA_PA, GAMMA_PA) returns
%   sigma_propagation-sigma_normal [Pa] and lambda_propagation/lambda_normal.
%   Propagation and thickness normal must be principal directions of an
%   initially isotropic incompressible elastic solid. An absolute principal
%   stress needs independent normal traction (zero for a free membrane).
%   KINEMATICS="uniaxial" explicitly asserts uniaxial deformation ALONG
%   propagation, lambda_normal=lambda_other=lambda_propagation^(-1/2).
%   Only then are absolute principal stretches returned. Default "principal"
%   leaves them NaN. Uniaxial transverse measurements cannot recover them.
%   These identities do not establish the validity of 2*beta=alpha+gamma.

if nargin < 3
    kinematics = "principal";
end
validateattributes(alpha_Pa, {'double'}, {'real', 'scalar', 'finite', 'positive'});
validateattributes(gamma_Pa, {'double'}, {'real', 'scalar', 'finite', 'positive'});
kinematics = string(kinematics);
if ~isscalar(kinematics) || ~any(kinematics == ["principal", "uniaxial"])
    error('lamb:li2022:InvalidKinematics', 'Choose exactly "principal" or "uniaxial".');
end
ratio = alpha_Pa/gamma_Pa;
if ~isfinite(ratio) || ratio == 0
    error('lamb:li2022:NumericalRange', 'Modulus ratio exceeds numerical range.');
end
state = struct('stressDifferencePropagationMinusNormal_Pa', alpha_Pa-gamma_Pa, ...
    'stretchRatioPropagationToNormal', sqrt(ratio), 'kinematics', kinematics, ...
    'propagationStretch', NaN, 'normalStretch', NaN, 'otherPrincipalStretch', NaN);
if kinematics == "uniaxial"
    state.propagationStretch = ratio^(1/3);
    state.normalStretch = state.propagationStretch^(-1/2);
    state.otherPrincipalStretch = state.normalStretch;
end
end
