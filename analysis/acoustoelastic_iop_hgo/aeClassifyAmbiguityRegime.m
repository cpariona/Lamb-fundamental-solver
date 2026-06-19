function status = aeClassifyAmbiguityRegime(params)
%AECLASSIFYAMBIGUITYREGIME Classify known AE IOP/HGO ambiguity regimes.
%
% status = AECLASSIFYAMBIGUITYREGIME(params) returns a diagnostic status
% structure for the acoustoelastic IOP/HGO parameter regime. This helper does
% not modify solver outputs and should not be used to replace branch tracking.
%
% Required fields in params:
%   IOP       pressure in Pa, or IOP_mmHg in mmHg
%   mu        shear-like HGO matrix parameter in Pa, or Mu_kPa in kPa
%
% Optional fields used for reporting:
%   k1, k2, thickness, R
%
% Current rule:
%   The low-stiffness/high-IOP corner around IOP >= 35 mmHg and mu <= 25 kPa
%   is flagged as ambiguous because raw residual-only branch families do not
%   provide a high-coverage, low-rank identity reference in that regime.

arguments
    params struct
end

IOP_mmHg = getParam(params, 'IOP_mmHg', nan);
if isnan(IOP_mmHg)
    IOP_mmHg = getParam(params, 'IOP', nan) / 133.322;
end

Mu_kPa = getParam(params, 'Mu_kPa', nan);
if isnan(Mu_kPa)
    Mu_kPa = getParam(params, 'mu', nan) / 1e3;
end

status = struct();
status.IOP_mmHg = IOP_mmHg;
status.Mu_kPa = Mu_kPa;
status.isKnownAmbiguous = false;
status.severity = "none";
status.label = "validated_or_unclassified";
status.reason = "No documented ambiguity flag for this parameter regime.";
status.recommendedOfficialPolicy = "atlasA0";
status.allowProductionPromotionOfDiagnosticBranches = false;

if isfinite(IOP_mmHg) && isfinite(Mu_kPa) && IOP_mmHg >= 35 && Mu_kPa <= 25
    status.isKnownAmbiguous = true;
    status.severity = "high";
    status.label = "low_mu_high_iop_modal_family_ambiguity";
    status.reason = [ ...
        "Documented low-stiffness/high-IOP corner: residual-only branch-family diagnostics " + ...
        "found no family combining high coverage and low median minima rank." ...
        ];
elseif isfinite(IOP_mmHg) && isfinite(Mu_kPa) && IOP_mmHg >= 25 && Mu_kPa <= 25
    status.isKnownAmbiguous = true;
    status.severity = "moderate";
    status.label = "near_low_mu_high_iop_boundary";
    status.reason = [ ...
        "Near documented ambiguity boundary. Official atlasA0 should remain conservative; " + ...
        "diagnostic extensions require inspection before interpretation." ...
        ];
end

status.notes = [ ...
    "This diagnostic flag does not alter result.Cp or result.validCp. " + ...
    "It records known validation limits for the current residual-only branch tracking strategy." ...
    ];
end

function value = getParam(params, name, defaultValue)
if isfield(params, name)
    value = params.(name);
else
    value = defaultValue;
end
end
