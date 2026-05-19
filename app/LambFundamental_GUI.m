function LambFundamental_GUI
% Simplified GUI shell for fundamental Lamb modes (Cp only).

fig = uifigure('Name', 'Fundamental Lamb Modes (A0/S0)', 'Position', [120 120 1000 620]);
mainLayout = uigridlayout(fig, [1 2]);
mainLayout.ColumnWidth = {320, '1x'};

left = uipanel(mainLayout, 'Title', 'Inputs'); left.Layout.Column = 1;
lg = uigridlayout(left, [16 2]); lg.RowHeight = repmat({28}, 1, 16); lg.ColumnWidth = {155, '1x'};

uilabel(lg,'Text','Model'); model = uidropdown(lg,'Items',{'YoungPoissonFixedCL','LameParameters'},'Value','YoungPoissonFixedCL');
uilabel(lg,'Text','rho [kg/m^3]'); rho = uieditfield(lg,'numeric','Value',1070);
uilabel(lg,'Text','E [kPa]'); E = uieditfield(lg,'numeric','Value',475);
uilabel(lg,'Text','nu [-]'); nu = uieditfield(lg,'numeric','Value',0.4999);
uilabel(lg,'Text','CL [m/s]'); CL = uieditfield(lg,'numeric','Value',1500);
uilabel(lg,'Text','lambda [MPa]'); lambda = uieditfield(lg,'numeric','Value',2400);
uilabel(lg,'Text','mu [kPa]'); mu = uieditfield(lg,'numeric','Value',158);
uilabel(lg,'Text','thickness [mm]'); thickness = uieditfield(lg,'numeric','Value',0.5);
uilabel(lg,'Text','fmin [Hz]'); fmin = uieditfield(lg,'numeric','Value',10);
uilabel(lg,'Text','fmax [Hz]'); fmax = uieditfield(lg,'numeric','Value',8000);
uilabel(lg,'Text','N freq'); nfreq = uieditfield(lg,'numeric','Value',250,'RoundFractionalValues','on');
uilabel(lg,'Text','freq spacing'); spacing = uidropdown(lg,'Items',{'logspace','linspace'},'Value','logspace');
uilabel(lg,'Text','x-axis'); xaxisSel = uidropdown(lg,'Items',{'frequency','angularFrequency','wavenumber','kThickness'},'Value','frequency');
uilabel(lg,'Text','Compute A0'); a0 = uicheckbox(lg,'Value',true);
uilabel(lg,'Text','Compute S0'); s0 = uicheckbox(lg,'Value',false);
runBtn = uibutton(lg,'Text','Compute and Plot','ButtonPushedFcn',@onRun); runBtn.Layout.Column=[1 2];

ax = uiaxes(mainLayout); ax.Layout.Column = 2;
grid(ax,'on');
ylabel(ax,'Cp [m/s]');

    function onRun(~,~)
        params = struct('modelType', string(model.Value), 'rho', rho.Value, ...
            'E', E.Value*1e3, 'nu', nu.Value, 'CL', CL.Value, ...
            'lambda', lambda.Value*1e6, 'mu', mu.Value*1e3, ...
            'thickness', thickness.Value*1e-3, 'fmin', fmin.Value, 'fmax', fmax.Value, ...
            'numFrequencyPoints', round(nfreq.Value), 'frequencySpacing', string(spacing.Value));
        opts = struct('computeA0', logical(a0.Value), 'computeS0', logical(s0.Value), ...
            'gridPointsInitial', 3000, 'gridPointsTracking', 600, 'jumpTol', 0.35, 'residualTolerance', 1e-5);

        results = computeFundamentalLambModes(params, opts);
        cla(ax); hold(ax,'on');
        xData = results.grid.frequency;
        xlabelText = 'frequency [Hz]';
        if strcmp(xaxisSel.Value,'angularFrequency'), xData = results.grid.omega; xlabelText = 'angularFrequency [rad/s]'; end

        if isfield(results.modes,'A0')
            mode = results.modes.A0;
            if strcmp(xaxisSel.Value,'wavenumber'), xData = mode.k; xlabelText = 'wavenumber k [rad/m]'; end
            if strcmp(xaxisSel.Value,'kThickness'), xData = mode.kThickness; xlabelText = 'kThickness [-]'; end
            plot(ax, xData, mode.Cp, 'LineWidth', 2, 'DisplayName', 'A0');
        end
        if isfield(results.modes,'S0')
            mode = results.modes.S0;
            xDataS0 = xData;
            if strcmp(xaxisSel.Value,'wavenumber'), xDataS0 = mode.k; end
            if strcmp(xaxisSel.Value,'kThickness'), xDataS0 = mode.kThickness; end
            plot(ax, xDataS0, mode.Cp, '--', 'LineWidth', 1.5, 'DisplayName', 'S0');
        end
        xlabel(ax, xlabelText); legend(ax,'Location','best'); grid(ax,'on'); hold(ax,'off');
    end
end
