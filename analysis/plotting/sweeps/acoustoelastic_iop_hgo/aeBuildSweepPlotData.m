function plotData = aeBuildSweepPlotData(sweepResult)
%AEBUILDSWEEPPLOTDATA Build AE sweep plot data through the shared owner.

plotData = buildParametricSweepPlotData( ...
    sweepResult, "AcoustoelasticIOPHGO", "atlasA0");
end
