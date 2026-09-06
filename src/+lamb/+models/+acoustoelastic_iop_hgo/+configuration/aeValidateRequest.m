function aeValidateRequest(params, varargin)
%AEVALIDATEREQUEST Validate maintained AE request fields without tightening shapes.

p = inputParser;
addParameter(p, 'Context', "iopSolver", @(x)ischar(x) || isstring(x));
addParameter(p, 'Frequency', [], @isnumeric);
parse(p, varargin{:});

switch string(p.Results.Context)
    case "iopSolver"
        required = {'IOP', 'R', 'thickness', 'mu', 'k1', 'k2', ...
            'rho', 'rhoF', 'fluidBulkModulus', 'frequency'};
        for i = 1:numel(required)
            if ~isfield(params, required{i})
                error('Missing required acoustoelastic IOP/HGO atlas parameter: %s', required{i});
            end
        end
    case "directAtlas"
        required = {'alpha','beta','gamma','thickness','rho','rhoF', ...
            'fluidBulkModulus','frequency'};
        for i = 1:numel(required)
            if ~isfield(params, required{i})
                error('Missing required Acoustoelastic IOP/HGO atlas-branch parameter: %s', required{i});
            end
        end
    case "fitting"
        frequency = p.Results.Frequency;
        if isempty(frequency) || any(~isfinite(frequency)) || any(frequency <= 0)
            error('frequency_Hz must contain positive finite values.');
        end
        required = {'IOP', 'R', 'thickness', 'mu', 'k1', 'k2', ...
            'rho', 'rhoF', 'fluidBulkModulus'};
        for i = 1:numel(required)
            if ~isfield(params, required{i})
                error('Missing AE IOP/HGO fitting parameter: %s.', required{i});
            end
        end
    otherwise
        error('lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest:InvalidContext', ...
            'Unknown AE validation context "%s".', string(p.Results.Context));
end
end
