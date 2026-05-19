function LambA0_GUI
% Interactive GUI to compute and plot the A0 Lamb wave mode
% https://github.com/franciscorotea/Lamb-Wave-Dispersion/blob/master/README.md
    %% Default parameters
    params.model_type = "YoungPoissonFixedCL";

    % Young/Poisson + fixed CL model
    params.E = 475e3;                 % Young's modulus [Pa]
    params.rho = 1070;                % Density [kg/m^3]
    params.total_thickness = 0.50e-3; % Total thickness [m]
    params.CL = 1500;                 % Fixed longitudinal bulk speed [m/s]
    params.nu = 0.4999;               % Poisson's ratio [-]

    % Lame model
    params.lambda = 2.40e9;           % First Lame parameter [Pa]
    params.mu = 158e3;                % Second Lame parameter / shear modulus [Pa]

    % Frequency settings
    params.fmin = 10;                 % Minimum frequency [Hz]
    params.fmax = 8000;               % Maximum frequency [Hz]
    params.Nf = 250;                  % Number of frequency points

    % Numerical settings
    params.grid_points_initial = 3000;
    params.grid_points_tracking = 600;
    params.res_tol = 1e-5;
    params.jump_tol = 0.35;

    %% Create main figure
    fig = uifigure( ...
        'Name', 'A0 Lamb Wave Phase Velocity Calculator', ...
        'Position', [100 100 1320 760]);

    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth = {390, '1x'};
    mainGrid.RowHeight = {'1x'};

    %% Left panel with tabs
    panel = uipanel(mainGrid, 'Title', 'Input parameters');
    panel.Layout.Row = 1;
    panel.Layout.Column = 1;
    
    leftGrid = uigridlayout(panel, [2 1]);
    leftGrid.RowHeight = {'1x', 210};
    leftGrid.ColumnWidth = {'1x'};
    leftGrid.Padding = [5 5 5 5];
    leftGrid.RowSpacing = 8;
    
    tabGroup = uitabgroup(leftGrid);
    tabGroup.Layout.Row = 1;
    tabGroup.Layout.Column = 1;
    
    %% ------------------------------------------------------------------------
    % Tab 1: Material model
    % -------------------------------------------------------------------------
    materialTab = uitab(tabGroup, 'Title', 'Material');
    
    materialGrid = uigridlayout(materialTab, [12 2]);
    materialGrid.ColumnWidth = {150, '1x'};
    materialGrid.RowHeight = repmat({32}, 1, 12);
    materialGrid.Padding = [12 12 12 12];
    materialGrid.RowSpacing = 8;
    
    uilabel(materialGrid, ...
        'Text', 'Elastic model', ...
        'FontWeight', 'bold');
    dummyLabel = uilabel(materialGrid, 'Text', '');
    dummyLabel.Layout.Column = 2;
    
    uilabel(materialGrid, 'Text', 'Input model');
    modelDropDown = uidropdown(materialGrid, ...
        'Items', {'Young/Poisson + fixed CL', 'Lame parameters'}, ...
        'ItemsData', {'YoungPoissonFixedCL', 'LameParameters'}, ...
        'Value', 'YoungPoissonFixedCL', ...
        'ValueChangedFcn', @(~, ~) updateInputVisibility());
    
    uilabel(materialGrid, 'Text', 'Density [kg/m^3]');
    rhoField = uieditfield(materialGrid, 'numeric', ...
        'Value', params.rho, ...
        'Limits', [0 Inf]);
    
    uilabel(materialGrid, ...
        'Text', 'Young / Poisson model', ...
        'FontWeight', 'bold');
    dummyLabel = uilabel(materialGrid, 'Text', '');
    dummyLabel.Layout.Column = 2;
    
    ELabel = uilabel(materialGrid, 'Text', 'E [kPa]');
    EField = uieditfield(materialGrid, 'numeric', ...
        'Value', params.E / 1e3, ...
        'Limits', [0 Inf]);
    
    nuLabel = uilabel(materialGrid, 'Text', 'nu [-]');
    nuField = uieditfield(materialGrid, 'numeric', ...
        'Value', params.nu, ...
        'Limits', [0 0.5]);
    
    CLLabel = uilabel(materialGrid, 'Text', 'Fixed CL [m/s]');
    CLField = uieditfield(materialGrid, 'numeric', ...
        'Value', params.CL, ...
        'Limits', [0 Inf]);
    
    uilabel(materialGrid, ...
        'Text', 'Lame model', ...
        'FontWeight', 'bold');
    dummyLabel = uilabel(materialGrid, 'Text', '');
    dummyLabel.Layout.Column = 2;
    
    lambdaLabel = uilabel(materialGrid, 'Text', 'lambda [MPa]');
    lambdaField = uieditfield(materialGrid, 'numeric', ...
        'Value', params.lambda / 1e6, ...
        'Limits', [0 Inf]);
    
    muLabel = uilabel(materialGrid, 'Text', 'mu [kPa]');
    muField = uieditfield(materialGrid, 'numeric', ...
        'Value', params.mu / 1e3, ...
        'Limits', [0 Inf]);
    
    %% ------------------------------------------------------------------------
    % Tab 2: Geometry and frequency
    % -------------------------------------------------------------------------
    geometryFreqTab = uitab(tabGroup, 'Title', 'Geometry / Frequency');
    
    geoFreqGrid = uigridlayout(geometryFreqTab, [11 2]);
    geoFreqGrid.ColumnWidth = {150, '1x'};
    geoFreqGrid.RowHeight = repmat({32}, 1, 11);
    geoFreqGrid.Padding = [12 12 12 12];
    geoFreqGrid.RowSpacing = 8;
    
    uilabel(geoFreqGrid, ...
        'Text', 'Geometry', ...
        'FontWeight', 'bold');
    dummyLabel = uilabel(geoFreqGrid, 'Text', '');
    dummyLabel.Layout.Column = 2;
    
    uilabel(geoFreqGrid, 'Text', 'Total thickness [mm]');
    thicknessField = uieditfield(geoFreqGrid, 'numeric', ...
        'Value', params.total_thickness * 1e3, ...
        'Limits', [0 Inf]);
    
    thicknessInfoLabel = uilabel(geoFreqGrid, ...
        'Text', 'h = total thickness / 2', ...
        'FontAngle', 'italic');
    thicknessInfoLabel.Layout.Column = [1 2];
    
    uilabel(geoFreqGrid, ...
        'Text', 'Frequency settings', ...
        'FontWeight', 'bold');
    dummyLabel = uilabel(geoFreqGrid, 'Text', '');
    dummyLabel.Layout.Column = 2;
    
    uilabel(geoFreqGrid, 'Text', 'f min [Hz]');
    fminField = uieditfield(geoFreqGrid, 'numeric', ...
        'Value', params.fmin, ...
        'Limits', [eps Inf]);
    
    uilabel(geoFreqGrid, 'Text', 'f max [Hz]');
    fmaxField = uieditfield(geoFreqGrid, 'numeric', ...
        'Value', params.fmax, ...
        'Limits', [eps Inf]);
    
    uilabel(geoFreqGrid, 'Text', 'N freq points');
    NfField = uieditfield(geoFreqGrid, 'numeric', ...
        'Value', params.Nf, ...
        'RoundFractionalValues', 'on', ...
        'Limits', [10 5000]);
    
    uilabel(geoFreqGrid, 'Text', 'Frequency scale');
    scaleDropDown = uidropdown(geoFreqGrid, ...
        'Items', {'logspace', 'linspace'}, ...
        'Value', 'logspace');
    
    %% ------------------------------------------------------------------------
    % Tab 3: Numerical settings
    % -------------------------------------------------------------------------
    numericalTab = uitab(tabGroup, 'Title', 'Numerical');
    
    numericalGrid = uigridlayout(numericalTab, [8 2]);
    numericalGrid.ColumnWidth = {150, '1x'};
    numericalGrid.RowHeight = repmat({32}, 1, 8);
    numericalGrid.Padding = [12 12 12 12];
    numericalGrid.RowSpacing = 8;
    
    uilabel(numericalGrid, ...
        'Text', 'Root tracking', ...
        'FontWeight', 'bold');
    dummyLabel = uilabel(numericalGrid, 'Text', '');
    dummyLabel.Layout.Column = 2;
    
    uilabel(numericalGrid, 'Text', 'Jump tol');
    jumpTolField = uieditfield(numericalGrid, 'numeric', ...
        'Value', params.jump_tol, ...
        'Limits', [0.01 5]);
    
    uilabel(numericalGrid, 'Text', 'Residual tol');
    resTolField = uieditfield(numericalGrid, 'numeric', ...
        'Value', params.res_tol, ...
        'Limits', [eps Inf]);
    
    uilabel(numericalGrid, 'Text', 'Initial grid');
    initialGridField = uieditfield(numericalGrid, 'numeric', ...
        'Value', params.grid_points_initial, ...
        'RoundFractionalValues', 'on', ...
        'Limits', [100 50000]);
    
    uilabel(numericalGrid, 'Text', 'Tracking grid');
    trackingGridField = uieditfield(numericalGrid, 'numeric', ...
        'Value', params.grid_points_tracking, ...
        'RoundFractionalValues', 'on', ...
        'Limits', [100 50000]);
    
    %% ------------------------------------------------------------------------
    % Fixed Run / Export section
    % -------------------------------------------------------------------------
    actionPanel = uipanel(leftGrid, 'Title', 'Run / Export');
    actionPanel.Layout.Row = 2;
    actionPanel.Layout.Column = 1;
    
    actionGrid = uigridlayout(actionPanel, [5 1]);
    actionGrid.RowHeight = {34, 34, 74, '1x', 24};
    actionGrid.ColumnWidth = {'1x'};
    actionGrid.Padding = [10 10 10 10];
    actionGrid.RowSpacing = 6;
    
    calcButton = uibutton(actionGrid, ...
        'Text', 'Recalculate A0', ...
        'ButtonPushedFcn', @(~, ~) recalculate());
    
    exportButton = uibutton(actionGrid, ...
        'Text', 'Export data to workspace', ...
        'ButtonPushedFcn', @(~, ~) exportData());
    
    materialInfoLabel = uilabel(actionGrid, ...
        'Text', 'Material info will appear here.', ...
        'WordWrap', 'on');
    
    statusLabel = uilabel(actionGrid, ...
        'Text', 'Ready.', ...
        'WordWrap', 'on');
    %% Right panel with plots
    plotGrid = uigridlayout(mainGrid, [2 1]);
    plotGrid.Layout.Row = 1;
    plotGrid.Layout.Column = 2;
    plotGrid.RowHeight = {'2x', '1x'};
    plotGrid.ColumnWidth = {'1x'};

    axCp = uiaxes(plotGrid);
    axCp.Layout.Row = 1;
    axCp.Layout.Column = 1;
    grid(axCp, 'on');
    xlabel(axCp, 'Frequency [Hz]');
    ylabel(axCp, 'Phase velocity C_p [m/s]');
    title(axCp, 'Antisymmetric Lamb wave mode A0');

    axResidual = uiaxes(plotGrid);
    axResidual.Layout.Row = 2;
    axResidual.Layout.Column = 1;
    grid(axResidual, 'on');
    xlabel(axResidual, 'Frequency [Hz]');
    ylabel(axResidual, 'Normalized residual');
    title(axResidual, 'A0 Rayleigh-Lamb residual');
    axResidual.YScale = 'log';

    %% Data storage
    last.freq = [];
    last.Cp_A0 = [];
    last.residual_A0 = [];
    last.derived = [];
    last.params = params;

    %% Initialize interface
    updateInputVisibility();
    recalculate();

    %% Callback: show/hide elastic inputs
    function updateInputVisibility()

        modelType = string(modelDropDown.Value);

        if modelType == "YoungPoissonFixedCL"
            ELabel.Enable = 'on';
            EField.Enable = 'on';
            nuLabel.Enable = 'on';
            nuField.Enable = 'on';
            CLLabel.Enable = 'on';
            CLField.Enable = 'on';

            lambdaLabel.Enable = 'off';
            lambdaField.Enable = 'off';
            muLabel.Enable = 'off';
            muField.Enable = 'off';

        elseif modelType == "LameParameters"
            ELabel.Enable = 'off';
            EField.Enable = 'off';
            nuLabel.Enable = 'off';
            nuField.Enable = 'off';
            CLLabel.Enable = 'off';
            CLField.Enable = 'off';

            lambdaLabel.Enable = 'on';
            lambdaField.Enable = 'on';
            muLabel.Enable = 'on';
            muField.Enable = 'on';
        end
    end

    %% Callback: recalculate curve
    function recalculate()

        try
            statusLabel.Text = 'Calculating...';
            drawnow;

            % Read GUI parameters
            p.model_type = string(modelDropDown.Value);

            p.rho = rhoField.Value;
            p.total_thickness = thicknessField.Value * 1e-3; % mm to m

            % Young/Poisson + fixed CL model
            p.E = EField.Value * 1e3;       % kPa to Pa
            p.nu = nuField.Value;
            p.CL = CLField.Value;

            % Lame model
            p.lambda = lambdaField.Value * 1e6; % MPa to Pa
            p.mu = muField.Value * 1e3;         % kPa to Pa

            % Frequency settings
            p.fmin = fminField.Value;
            p.fmax = fmaxField.Value;
            p.Nf = round(NfField.Value);

            % Numerical settings
            p.jump_tol = jumpTolField.Value;
            p.res_tol = resTolField.Value;
            p.grid_points_initial = round(initialGridField.Value);
            p.grid_points_tracking = round(trackingGridField.Value);

            % Validate inputs
            validateParameters(p);

            % Compute A0 mode
            [freq, Cp_A0, residual_A0, derived] = computeA0Mode(p, scaleDropDown.Value);

            % Store results
            last.freq = freq;
            last.Cp_A0 = Cp_A0;
            last.residual_A0 = residual_A0;
            last.derived = derived;
            last.params = p;

            % Plot phase velocity
            cla(axCp);
            plot(axCp, freq, Cp_A0, 'LineWidth', 2);
            grid(axCp, 'on');
            xlabel(axCp, 'Frequency [Hz]');
            ylabel(axCp, 'Phase velocity C_p [m/s]');
            title(axCp, 'Antisymmetric Lamb wave mode A0');

            ymax = max(Cp_A0, [], 'omitnan');
            if isfinite(ymax) && ymax > 0
                ylim(axCp, [0, 1.1 * ymax]);
            end

            % Plot residual
            cla(axResidual);
            semilogy(axResidual, freq, residual_A0, 'LineWidth', 2);
            grid(axResidual, 'on');
            xlabel(axResidual, 'Frequency [Hz]');
            ylabel(axResidual, 'Normalized residual');
            title(axResidual, 'A0 Rayleigh-Lamb residual');

            % Update material info
            materialInfoLabel.Text = sprintf([ ...
                'Model: %s\n', ...
                'E = %.4g kPa, nu = %.6f\n', ...
                'lambda = %.4g MPa, mu = %.4g kPa\n', ...
                'CL = %.4f m/s, CT = %.4f m/s'], ...
                char(derived.model_type), ...
                derived.E / 1e3, ...
                derived.nu, ...
                derived.lambda / 1e6, ...
                derived.mu / 1e3, ...
                derived.CL, ...
                derived.CT);

            % Update status
            nValid = sum(isfinite(Cp_A0));
            statusLabel.Text = sprintf( ...
                'Done. Valid points = %d / %d', ...
                nValid, numel(freq));

        catch ME
            statusLabel.Text = ['Error: ', ME.message];
            uialert(fig, ME.message, 'Calculation error');
        end
    end

    %% Callback: export data
    function exportData()

        if isempty(last.freq)
            uialert(fig, 'No data available to export.', 'Export error');
            return;
        end

        A0_data = table( ...
            last.freq(:), ...
            last.Cp_A0(:), ...
            last.residual_A0(:), ...
            'VariableNames', {'Frequency_Hz', 'Cp_A0', 'Residual'});

        A0_params = last.params;
        A0_derived = last.derived;

        assignin('base', 'A0_data', A0_data);
        assignin('base', 'A0_params', A0_params);
        assignin('base', 'A0_derived', A0_derived);

        statusLabel.Text = 'Data exported to workspace: A0_data, A0_params, A0_derived';
    end
end

%% ------------------------------------------------------------------------
% Main A0 solver
% -------------------------------------------------------------------------
function [freq, Cp_A0, residual_A0, derived] = computeA0Mode(params, freqScale)
% Compute the A0 branch using continuation

    rho = params.rho;
    total_thickness = params.total_thickness;
    h = total_thickness / 2;

    % Get elastic constants according to selected model
    derived = computeElasticConstants(params);

    CL = derived.CL;
    CT = derived.CT;

    % Frequency vector
    switch lower(freqScale)
        case 'logspace'
            freq = logspace(log10(params.fmin), log10(params.fmax), params.Nf);
        case 'linspace'
            freq = linspace(params.fmin, params.fmax, params.Nf);
        otherwise
            error('Unknown frequency scale.');
    end

    % Phase velocity limits
    Cp_min_abs = 1e-4;
    Cp_min = max(Cp_min_abs, 0.001 * CT);

    Cp_global_min = Cp_min;
    Cp_global_max = max(20 * CT, 1.0);

    % Storage
    Cp_A0 = nan(size(freq));
    residual_A0 = nan(size(freq));

    %% Step 1: initial broad scan
    f0 = freq(1);

    Cp_grid = linspace(Cp_global_min, Cp_global_max, params.grid_points_initial);
    R_grid = nan(size(Cp_grid));

    for j = 1:length(Cp_grid)
        R_grid(j) = RL_A0_residual(Cp_grid(j), f0, CL, CT, h);
    end

    valid = isfinite(R_grid) & Cp_grid > Cp_min_abs;
    Cp_grid_valid = Cp_grid(valid);
    R_grid_valid = R_grid(valid);

    if numel(Cp_grid_valid) < 5
        error('Not enough valid points in the initial scan.');
    end

    candidate_idx = findLocalMinima(R_grid_valid);

    if isempty(candidate_idx)
        error('No candidate roots were found at the first frequency.');
    end

    best_Cp = nan;
    best_R = inf;

    for idx = candidate_idx(:).'
        Cp_left = Cp_grid_valid(max(idx - 2, 1));
        Cp_right = Cp_grid_valid(min(idx + 2, length(Cp_grid_valid)));

        if Cp_right <= Cp_left
            continue;
        end

        obj = @(Cp) RL_A0_residual(Cp, f0, CL, CT, h);

        try
            Cp_candidate = fminbnd(obj, Cp_left, Cp_right);
            R_candidate = obj(Cp_candidate);

            % Choose the lowest physical A0-like root
            if Cp_candidate > Cp_min_abs && R_candidate < best_R
                best_Cp = Cp_candidate;
                best_R = R_candidate;
            end
        catch
            continue;
        end
    end

    if isnan(best_Cp)
        error('The initial A0 root could not be refined.');
    end

    Cp_A0(1) = best_Cp;
    residual_A0(1) = best_R;

    %% Step 2: continuation
    for i = 2:length(freq)

        fi = freq(i);
        Cp_prev = Cp_A0(i - 1);

        if isnan(Cp_prev)
            break;
        end

        search_factors = [
            0.75, 1.25
            0.50, 1.60
            0.30, 2.20
            0.10, 4.00
        ];

        best_Cp = nan;
        best_R = inf;

        for s = 1:size(search_factors, 1)

            Cp_low = max(Cp_global_min, search_factors(s, 1) * Cp_prev);
            Cp_high = min(Cp_global_max, search_factors(s, 2) * Cp_prev);

            if Cp_high <= Cp_low
                continue;
            end

            Cp_grid = linspace(Cp_low, Cp_high, params.grid_points_tracking);
            R_grid = nan(size(Cp_grid));

            for j = 1:length(Cp_grid)
                R_grid(j) = RL_A0_residual(Cp_grid(j), fi, CL, CT, h);
            end

            valid = isfinite(R_grid) & Cp_grid > Cp_min_abs;
            Cp_grid_valid = Cp_grid(valid);
            R_grid_valid = R_grid(valid);

            if numel(Cp_grid_valid) < 5
                continue;
            end

            candidate_idx = findLocalMinima(R_grid_valid);

            for idx = candidate_idx(:).'
                Cp_left = Cp_grid_valid(max(idx - 2, 1));
                Cp_right = Cp_grid_valid(min(idx + 2, length(Cp_grid_valid)));

                if Cp_right <= Cp_left
                    continue;
                end

                obj = @(Cp) RL_A0_residual(Cp, fi, CL, CT, h);

                try
                    Cp_candidate = fminbnd(obj, Cp_left, Cp_right);
                    R_candidate = obj(Cp_candidate);

                    rel_jump = abs(Cp_candidate - Cp_prev) / max(Cp_prev, eps);

                    % Reject null roots and mode jumps
                    if Cp_candidate > Cp_min_abs && ...
                       rel_jump < params.jump_tol && ...
                       R_candidate < best_R

                        best_Cp = Cp_candidate;
                        best_R = R_candidate;
                    end

                catch
                    continue;
                end
            end

            if ~isnan(best_Cp) && best_R < params.res_tol
                break;
            end
        end

        Cp_A0(i) = best_Cp;
        residual_A0(i) = best_R;
    end
end

%% ------------------------------------------------------------------------
% Elastic constants
% -------------------------------------------------------------------------
function derived = computeElasticConstants(params)
% Compute E, nu, lambda, mu, CL and CT

    rho = params.rho;
    modelType = string(params.model_type);

    switch modelType

        case "YoungPoissonFixedCL"
            E = params.E;
            nu = params.nu;
            CL = params.CL;

            mu = E / (2 * (1 + nu));
            lambda = E * nu / ((1 + nu) * (1 - 2 * nu));

            CT = sqrt(mu / rho);

        case "LameParameters"
            lambda = params.lambda;
            mu = params.mu;

            % Elastic constants from Lame parameters
            E = mu * (3 * lambda + 2 * mu) / (lambda + mu);
            nu = lambda / (2 * (lambda + mu));

            % Bulk wave speeds from Lame parameters
            CL = sqrt((lambda + 2 * mu) / rho);
            CT = sqrt(mu / rho);

        otherwise
            error('Unknown elastic model.');
    end

    derived.model_type = modelType;
    derived.E = E;
    derived.nu = nu;
    derived.lambda = lambda;
    derived.mu = mu;
    derived.CL = CL;
    derived.CT = CT;
end

%% ------------------------------------------------------------------------
% Residual function
% -------------------------------------------------------------------------
function R = RL_A0_residual(Cp, f, CL, CT, h)
% Normalized residual for the antisymmetric Rayleigh-Lamb equation

    if Cp <= 0 || f <= 0
        R = inf;
        return;
    end

    omega = 2 * pi * f;
    k = omega / Cp;

    % Avoid singular or non-physical zero wavenumber
    if abs(k) < eps
        R = inf;
        return;
    end

    % Complex square roots are allowed
    p = sqrt(complex((omega / CL)^2 - k^2));
    q = sqrt(complex((omega / CT)^2 - k^2));

    % Avoid null roots related to p or q
    if abs(p) < 1e-12 || abs(q) < 1e-12
        R = inf;
        return;
    end

    % Antisymmetric Rayleigh-Lamb equation
    F = 4 * k^2 * p * q * tan(q * h) + ...
        (q^2 - k^2)^2 * tan(p * h);

    % Normalize to reduce scaling issues
    scale = abs(4 * k^2 * p * q) + abs((q^2 - k^2)^2) + eps;

    R = abs(F) / scale;

    % Reject numerical singularities
    if ~isfinite(R) || isnan(R)
        R = inf;
    end
end

%% ------------------------------------------------------------------------
% Local minima finder
% -------------------------------------------------------------------------
function idx = findLocalMinima(y)
% Find local minima indices in a vector

    idx = [];

    if numel(y) < 3
        return;
    end

    for i = 2:numel(y)-1
        if isfinite(y(i)) && y(i) < y(i-1) && y(i) < y(i+1)
            idx(end+1) = i; %#ok<AGROW>
        end
    end

    % Use global minimum as fallback
    if isempty(idx)
        [~, idx_min] = min(y);
        idx = idx_min;
    end
end

%% ------------------------------------------------------------------------
% Parameter validation
% -------------------------------------------------------------------------
function validateParameters(p)
% Validate user inputs

    if p.rho <= 0
        error('Density must be positive.');
    end

    if p.total_thickness <= 0
        error('Total thickness must be positive.');
    end

    if p.fmin <= 0 || p.fmax <= 0
        error('Frequencies must be positive.');
    end

    if p.fmax <= p.fmin
        error('f max must be larger than f min.');
    end

    if p.Nf < 10
        error('The number of frequency points must be at least 10.');
    end

    if p.jump_tol <= 0
        error('Jump tolerance must be positive.');
    end

    if p.res_tol <= 0
        error('Residual tolerance must be positive.');
    end

    if p.grid_points_initial < 100
        error('Initial grid must be at least 100.');
    end

    if p.grid_points_tracking < 100
        error('Tracking grid must be at least 100.');
    end

    modelType = string(p.model_type);

    switch modelType

        case "YoungPoissonFixedCL"

            if p.E <= 0
                error('Young''s modulus must be positive.');
            end

            if p.nu < 0 || p.nu >= 0.5
                error('Poisson''s ratio must be in the range [0, 0.5).');
            end

            if p.CL <= 0
                error('Fixed CL must be positive.');
            end

        case "LameParameters"

            if p.lambda < 0
                error('lambda must be non-negative.');
            end

            if p.mu <= 0
                error('mu must be positive.');
            end

        otherwise
            error('Unknown elastic model.');
    end
end
