%***********************************DDG ver 2.00**************************
%Author: Danial Yazdani
%Last Edited: December 14, 2023
%Title:
% --------
%Refrence:
%
%
% --------
% License:
% This program is to be used under the terms of the GNU General Public License
% (http://www.gnu.org/copyleft/gpl.html).
% Author: Danial Yazdani
% e-mail: danial DOT yazdani AT gmail DOT com
% Copyright notice: (c) 2023 Danial Yazdani
%**************************************************************************
function [result,DDG] = ClusteringEvaluation(X,DDG)
[SolutionNumber,~] = size(X);
result = NaN(SolutionNumber,1);
for ii=1 : SolutionNumber
    if DDG.FE>DDG.MaxEvals
        return; % Termination criterion has been met
    end
    x = X(ii,:);
    ClusterCenterPosition = reshape(x', [DDG.NumberOfVariables, DDG.ClusterNumber])';
    Distances = pdist2(DDG.Data.Dataset, ClusterCenterPosition,'euclidean');
    [~, closestClusterIndices] = min(Distances, [], 2);
    selectedDistances = diag(Distances(:, closestClusterIndices));
    result(ii) = sum(selectedDistances);% Sum of intra-cluster distances
    DDG.FE = DDG.FE+1;
    %% For performance measurement
    if result(ii)<DDG.CurrentBestSolutionValue %for minimization
        DDG.CurrentBestSolution      = x;
        DDG.CurrentBestSolutionValue = result(ii);
    end
    DDG.BestValueAtEachFE(DDG.FE) = DDG.CurrentBestSolutionValue;
    %% changes in the landscape and dataset
    RecentLargeChangeFlag = 0;
    for jj=1 : DDG.RGCNumber
        if rand(DDG.Rng)<DDG.RGC(jj).LocalChangeLikelihood
            [DDG] = EnvironmentalChangeGenerator(DDG,jj);% local change for DGC jj, the change code is a positive integer
        end
    end
    if rand(DDG.Rng)<DDG.GlobalChangeLikelihood
        [DDG] = EnvironmentalChangeGenerator(DDG,0);% 0 is the change code for the global severe changes in DGCs' parameters
        RecentLargeChangeFlag = 1;
    end
    if rand(DDG.Rng)<DDG.RGCNumberChangeLikelihood
        [DDG] = EnvironmentalChangeGenerator(DDG,-1);% -1 is the change code for change in the number of DGCs
        RecentLargeChangeFlag = 1;
    end
    if rand(DDG.Rng)<DDG.VariableNumberChangeLikelihood
        [DDG] = EnvironmentalChangeGenerator(DDG,-2);% -2 is the change code for change in the number of variables
        RecentLargeChangeFlag = 1;
    end
    if rand(DDG.Rng)<DDG.ClusterNumberChangeLikelihood
        [DDG] = EnvironmentalChangeGenerator(DDG,-3);% -3 is the change code for change in the number of cluster centers
        RecentLargeChangeFlag = 1;
    end
    %% Sampling
    if RecentLargeChangeFlag == 1% Sample all dataset from the updated landscape
        DDG = DataGeneration(DDG.Data.SampleSize,DDG);
        DDG.CurrentBestSolutionValue = CurrentSolutionEvaluation(DDG.CurrentBestSolution,DDG);%Reevaluate the best clustering solution based on the updated dataset for the performance evaluation
    end
    if mod(DDG.FE, DDG.Data.IncrementalSamplingFrequency) == 0% Incremental sampling based on the fixed frequency DDG.Data.IncrementalSamplingFrequency
        DDG = DataGeneration(DDG.Data.IncrementalSamplingSize,DDG);
        DDG.CurrentBestSolutionValue = CurrentSolutionEvaluation(DDG.CurrentBestSolution,DDG);%Reevaluate the best clustering solution based on the updated dataset for the performance evaluation
    end
end