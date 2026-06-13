function options = defaultAcoustoelasticIOPHGOOptions(varargin)
%DEFAULTACOUSTOELASTICIOPHGOOPTIONS Default options for the acoustoelastic IOP/HGO solver.
%
% This is the maintained author-neutral wrapper for the IOP/HGO
% acoustoelastic option set. It preserves compatibility by delegating to the
% original Li2024 options function.

options = defaultLi2024AcoustoelasticOptions(varargin{:});
end
