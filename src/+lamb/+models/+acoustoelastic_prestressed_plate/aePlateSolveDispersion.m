function mode = aePlateSolveDispersion(frequency_Hz, physical)
%AEPLATESOLVEDISPERSION Free elastic membrane A0 dispersion at requested frequencies.
%   PHYSICAL contains alpha_Pa, gamma_Pa, density_kgpm3, thickness_m.
%   thickness_m is CURRENT FULL thickness (2*h), never reference thickness.
%   Supports alpha >= gamma > 0: tensile or unstressed stable membranes.
%   Frequencies are finite nonnegative Hz; zero returns the long-wave limit.
%   Result vectors are columns, in input order, including duplicates.
%   Initially isotropic, incompressible, moderate-strain approximation with
%   2*beta=alpha+gamma, principal propagation and traction-free faces only.
%   No fluid loading, viscosity or intrinsic anisotropy is modelled.

validateattributes(frequency_Hz, {'double'}, ...
    {'real', 'vector', 'nonempty', 'finite', 'nonnegative'}, mfilename, 'frequency_Hz');
validateattributes(physical, {'struct'}, {'scalar'}, mfilename, 'physical');
for name = ["alpha_Pa", "gamma_Pa", "density_kgpm3", "thickness_m"]
    validateattributes(physical.(name), {'double'}, ...
        {'real', 'scalar', 'finite', 'positive'}, mfilename, char(name));
end
if physical.alpha_Pa < physical.gamma_Pa
    error('lamb:aePlate:UnsupportedCompression', ...
        'Forward prediction requires alpha_Pa >= gamma_Pa.');
end
frequency_Hz = frequency_Hz(:);
omega = 2*pi*frequency_Hz;
h = physical.thickness_m/2;
target = omega*h;
if any(~isfinite(omega) | ~isfinite(target)) || h == 0 || ...
        any(frequency_Hz > 0 & target == 0)
    error('lamb:aePlate:NumericalRange', 'Frequency/thickness conversion exceeds numerical range.');
end
rho = physical.density_kgpm3;
gamma = physical.gamma_Pa;
stressDifference = physical.alpha_Pa-gamma;
limit = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(Inf);
cInfinity = sqrt((stressDifference+gamma*limit.oneMinusEtaSquared)/rho);
if ~isfinite(cInfinity) || cInfinity == 0
    error('lamb:aePlate:NumericalRange', 'Limiting speed exceeds numerical range.');
end
q = zeros(size(frequency_Hz));
cp = repmat(sqrt(stressDifference/rho), size(frequency_Hz));
for i = 1:numel(q)
    if target(i) == 0
        continue;
    end
    % Solve in log(q); absolute root tolerances must not erase tiny kh.
    lower = log(target(i))-log(cInfinity);
    upper = max(0, lower)+log(2);
    residual = @(logq) frequencyResidual(logq, target(i), stressDifference, gamma, rho);
    while residual(upper) < 0
        upper = upper+log(2);
    end
    % Roundoff at the high-frequency limiting speed can put the lower
    % endpoint just above the root. Moving it down also gives a strict bracket.
    lower = lower-log(2);
    logq = fzero(residual, [lower, upper]);
    q(i) = exp(logq);
    curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q(i));
    cp(i) = sqrt((stressDifference+gamma*curve.oneMinusEtaSquared)/rho);
end
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
mode = struct('frequency_Hz', frequency_Hz, 'angularFrequency_radps', omega, ...
    'phaseVelocity_mps', cp, 'wavenumber_radpm', q/h, ...
    'wavenumberThickness', q, 'etaSquared', curve.etaSquared, ...
    'oneMinusEtaSquared', curve.oneMinusEtaSquared, ...
    'validMask', isfinite(cp) & isfinite(q/h));
if ~all(mode.validMask)
    error('lamb:aePlate:NumericalRange', 'Requested dispersion exceeds numerical range.');
end
end

function value = frequencyResidual(logq, target, stressDifference, gamma, rho)
q = exp(logq);
curve = lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
cp = sqrt((stressDifference+gamma*curve.oneMinusEtaSquared)/rho);
value = q*(cp/target)-1;
end
