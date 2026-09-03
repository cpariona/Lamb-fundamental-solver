function options = aeDefaultIdentityA0ValidationOptions(varargin)
%AEDEFAULTIDENTITYA0VALIDATIONOPTIONS Default options for identity-A0 validation diagnostics.
%
% options = aeDefaultIdentityA0ValidationOptions()
% options = aeDefaultIdentityA0ValidationOptions('AtlasBranchPolicy', value)

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasNumYPoints = 1000;
options.atlasTopNMinima = 18;

if mod(numel(varargin), 2) ~= 0
    error('Options must be provided as name-value pairs.');
end

for k = 1:2:numel(varargin)
    name = varargin{k};
    value = varargin{k+1};
    if isstring(name)
        name = char(name);
    end
    switch lower(name)
        case 'atlasbranchpolicy'
            options.atlasBranchPolicy = string(value);
        otherwise
            error('Unknown option: %s', name);
    end
end
end
