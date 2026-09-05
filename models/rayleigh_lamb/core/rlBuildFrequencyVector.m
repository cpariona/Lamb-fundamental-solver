function frequency = rlBuildFrequencyVector(params)
%RLBUILDFREQUENCYVECTOR Build the Rayleigh-Lamb frequency vector.
%
% This maintained RL entry point delegates generic grid construction to the
% neutral shared owner. Other model families must call buildFrequencyVector
% directly rather than depending on Rayleigh-Lamb infrastructure.

frequency = buildFrequencyVector(params);
end
