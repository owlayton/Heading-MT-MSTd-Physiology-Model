function DiffErrorPlot(baseFile, compFile, versionNumber)
%DIFFERRORPLOT takes in the name of a plot result CSV exported, compares it
%against comp version and outputs a plot of the result.

if ~exist("versionNumber", "var") || versionNumber < 0
    versionNumber = FindLatestVersion("results/processed/" + baseFile, ".json");
end

baseFileName = "results" + filesep + "processed" + filesep + baseFile + "-" + sprintf('%03d',versionNumber) + ".json";
compFileName = "results" + filesep + "processed" + filesep + compFile + "-" + sprintf('%03d',versionNumber) + ".json";

baseFile = jsonread(baseFileName);
compFile = jsonread(compFileName);

% get data
baseMatrix = baseFile.matrix;
compMatrix = compFile.matrix;
baseStd = baseFile.errorMatrix;
compStd = compFile.errorMatrix;

% get labels
labels = baseFile.labels;


% calc diff, errorbars on diff
diffData = baseMatrix- compMatrix;
diffStd = sqrt( baseStd + compStd );

% draw plot
figure;
b = bar(baseFile.xTicks, diffData);

% check if error bars are to be drawn
if baseFile.plotVarErrorBarsInd ~= -1
    % get the x and y positions of the bars for the error bar
    xb = bsxfun(@plus, b(1).XData, [b.XOffset]');
    yb = cat(1, b.YData);
    
    hold on;
    for ii = 1:length(xb(:))
        % plot([xb(ii), xb(ii)], [yb(ii)-diffStd(ii) yb(ii)+diffStd(ii)], 'xk-')
        er = errorbar(xb(ii), yb(ii),diffStd(ii));
        er.Color = [0 0 0];                            
        er.LineStyle = 'none';  
    end
    hold off;

end
legend(labels, "FontSize", 20)

% displays average error and average absolute error per parameter for
% simplified reporting, scalar comparing of parameters.
for ii = 1:size(diffData,2)
    data = diffData(:,ii);
    disp(labels{ii})
    disp([mean(data) mean(abs(data))])
end

% average abs error bar plot
figure;
plot(mean(abs(diffData)),'-ko','MarkerSize',12);
xticks(1:size(diffData));
xticklabels(labels);
title("mean abs error")

end




