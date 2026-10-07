# Rayleigh-Lamb local invariants

- Production supports `0.49 <= effective nu < 0.5`, including material-derived
  effective nu. Default nu is `0.4999`; never clip or substitute material values.
- The regular boundary equation is canonical. Do not add a general negative-nu
  or nu=0 degeneracy framework to production.
- Physical low-frequency A0/S0 identity anchors request-independent continuation.
  The requested frequency grid never defines branch history.
- Prediction may seed root discovery but never become scientific output.
  Unresolved roots remain invalid.
- Fast/Balanced/Robust vary numerical effort only; preserve their continuation,
  support, and invalid-output semantics.
- Fitting and the mRLFE seed consume the public
  `lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes` route.
