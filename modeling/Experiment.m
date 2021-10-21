function finalAvgResults = Experiment(varargin)
% EXPERIMENT Runs the given multi-config multiple times and returns the
% average runtime and accuracy. To be used for reporting purposes where we
% want to eliminate any random noise from model metrics.

addpath tools
addpath classes

% load configuration from file
if nargin
    fileName = varargin{1};
else
    fileName = "benchmark";
end

N = 5; % how many times to run each possible config
resultMatrices = cell(N,1);
counter = 1;
for i = 1:N
    disp(["Running ", i, "/", N, " iteration of ", fileName])
    resultMatrices{i} = RunModel(fileName);
    counter = counter + 1;
end

avg_scores = zeros(size(resultMatrices{1},1),1);
avg_times = zeros(size(resultMatrices{1},1),1);
for i = 1:N
    avg_times = avg_times + resultMatrices{i}(:,size(resultMatrices{1},2));
    avg_scores = avg_scores + resultMatrices{i}(:,size(resultMatrices{1},2) - 1);
end
avg_times = avg_times / N;
avg_scores = avg_scores / N;

lim = size(resultMatrices{1},2)-2;
finalAvgResults = [resultMatrices{1}(:,1:lim) avg_scores avg_times];
disp(finalAvgResults)

end