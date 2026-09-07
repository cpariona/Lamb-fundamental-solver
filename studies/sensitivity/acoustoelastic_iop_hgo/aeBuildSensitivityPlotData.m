function plotData = aeBuildSensitivityPlotData(sweepResult)
%AEBUILDSENSITIVITYPLOTDATA Build AE sweep plot data through the shared renderer owner.

plotData = buildParametricSweepPlotData( ...
    sweepResult, "AcoustoelasticIOPHGO", "atlasA0");
end
