function ModelResultsPlot(filename, version, varargin)

args = parseInputs(varargin);

fileName = setFilename(filename, version);
comparisonFilename = setFilename(args.comparisonFilename, args.comparisonVersion);

data = jsonread(fileName);
xRange = data.xRange;
xLabel = data.xLabel;
yLabel = data.yLabel;
labels = data.labels;
xTicks = data.xTicks;
plotVarErrorBarsInd = data.plotVarErrorBarsInd;

matrix = data.matrix;
errorMatrix = data.errorMatrix;

matrix = reshape(matrix, args.reshapeSize);
errorMatrix = reshape(errorMatrix, args.reshapeSize);
xTicks = reshape(xTicks, args.reshapeSize(1:2));

nNoiseLevels = size(matrix, 2);
nModels = size(matrix, 3);

maxNoiseLvl = 10;
minNoiseLvl = 8;

if args.showAllModels
  repError = data.repError;
  repError = reshape(repError, args.reshapeSize);

  % Plot model results for each noise level
  for m = 1:nModels
    figure();
    for n = 1:maxNoiseLvl
      x = squeeze(xTicks(:, n));
      y = squeeze(matrix(:, n, m));
      err = squeeze(repError(:, n, m));

      y(x > 0) = -y(x > 0);

      errorbar(x, y, err, '-o');
      hold on;
    end
    hold off;

    title("Effect of noise level ("+ labels(m) + ")");

    ylim([-30, 60]);

    % change tick label size
    ax = gca;
    ax.FontSize = 20;

    % Make colors discriminatable
    ax.ColorOrder = distinguishable_colors(size(matrix, 2));

    le = legend(string(1:10), "FontSize", 20, 'Orientation', 'Horizontal');
  end
end


% Plot average impact of noise for each heading
if args.showModelAvg
  x = squeeze(xTicks(:, 1));
  matrixMean = squeeze(mean(matrix(:, minNoiseLvl:maxNoiseLvl, :), 2));
  noiseErrorMean = squeeze(std(matrix(:, minNoiseLvl:maxNoiseLvl, :), [], 2));

  matrixMean(x > 0, :) = -matrixMean(x > 0, :);

  fig = figure();

  % Apply scale factor
  scaleF = 1.5;
  currSizeParams = get(0,'defaultfigureposition');
  fig.Position = [0.5, 0.5, args.figureScaleXY(1), args.figureScaleXY(2)] .* currSizeParams;

  hold on;
  for m = 1:nModels
    errorbar(x, matrixMean(:, m), noiseErrorMean(:, m), '-o', "LineWidth", 1, "MarkerSize", 10);
  end

  % Zero line
  plot(linspace(min(x), max(x)), zeros(100, 1), ".", 'Color', [0.7, 0.7, 0.7]);
  hold off;

  title('Influence of noise on MSTd models');
  xlabel("Heading (" + char(176) + ")");
  ylabel("Heading bias {\alpha} (" + char(176) + ")");

  ylim(args.ylim);

  % Set the xticks
  if ~isempty(args.xticks)
    xTicks = args.xticks(:);
    xticks(xTicks(:));
  end

  if ~isempty(args.yticks)
    yticks(args.yticks);
  end

  % change tick label size
  ax = gca;
  ax.FontSize = 20;

  % Make colors maximally discriminatable
  ax.ColorOrder = distinguishable_colors(nModels);

  labels = string(cellfun(@(s) strrep(s, 'eta}', '\gamma}'), labels, 'UniformOutput', false));

  if ~isempty(args.legendLabels)
    labels = args.legendLabels;
  end

  le = legend(labels, "FontSize", 20, 'Orientation', 'Horizontal', 'NumColumns', 4, 'Location', 'north');

  % inset
  if args.showModelMeanComparison
    % Create mini plot on bottom right showing MAE
    axes('Position', args.insetPosition);
    box on;

    % Get baseline predictions from each model and heading
    compData = jsonread(comparisonFilename);
    basePreds = compData.matrix;

    % Create copy of noise predictions for bias
    noisePreds = matrix;

    % Get heading angles
    x = squeeze(xTicks(:, 1));

    % Convert to bias
    basePreds(x > 0, :) = -basePreds(x > 0, :);
    noisePreds(x > 0, :, :) = -noisePreds(x > 0, :, :);

    meanBasePreds = squeeze(mean(abs(noisePreds(:, 1, :))));
    meanNoisePreds = squeeze(mean(abs(noisePreds(:, minNoiseLvl:maxNoiseLvl, :)), [1, 2]));

    stdBasePreds = squeeze(std(abs(basePreds)));
    stdNoisePreds = squeeze(std(mean(abs(noisePreds), 2), 1));

    % Extract model numeric labels
    modelStrs = regexp(args.xticklabels, '\d+\.*\d*', 'match');
    modelStrs = [modelStrs{:}];
    modelLabels = double(string(modelStrs));

    plot(1:numel(meanBasePreds), meanBasePreds, '-s', 'MarkerSize', 10, "LineWidth", 1);
    hold on;
    plot(1:numel(meanBasePreds), meanNoisePreds, '-^', 'MarkerSize', 10, "LineWidth", 1);
    hold off;

    if ~isempty(args.inset_xticks)
      xticks(args.inset_xticks);
    else
      xticks(1:numel(meanBasePreds));
    end

    if ~isempty(args.inset_xticklabels)
      xticklabels(args.inset_xticklabels);
    else
      xticklabels(modelLabels);
    end


    %     title('');
    xlabel('MSTd Model');
    ylabel("Mean absolute bias (" + char(176) + ")");

    ylim([0, 20])

    labels = ["No noise", "Noise"];
    le = legend(labels, 'Orientation', 'Horizontal', 'NumColumns', 2, 'Location', 'southeast');

    % change tick label size
    ax = gca;
    ax.FontSize = 16;
  end

  % Set page area appropriately
  h = gcf;
  set(h,'PaperUnits','normalized');
  set(h,'PaperPosition', [0 0 1 1]);
  if args.figureScaleXY(1) > args.figureScaleXY(2)
    set(h, 'PaperOrientation', 'landscape');
  end
  print(gcf, '-dpdf', args.exportPDFName);
end

if args.showModelNoiseComparison
  % Get baseline predictions from each model and heading
  compData = jsonread(comparisonFilename);
  basePreds = compData.matrix;

  % Create copy of noise predictions for bias
  noisePreds = matrix;

  % Get heading angles
  x = squeeze(xTicks(:, 1));

  % Convert to bias
  basePreds(x > 0, :) = -basePreds(x > 0, :);
  noisePreds(x > 0, :, :) = -noisePreds(x > 0, :, :);

  % Compute Mean Absolute Error across headings
  noiseMae = squeeze(abs(noisePreds(:, minNoiseLvl:maxNoiseLvl, :) - noisePreds(:, 1, :)));
  noiseMae = reshape(noiseMae, [prod(size(noiseMae, [1, 2])), size(noiseMae, 3)]);
  noiseMaeRaw = squeeze(noisePreds - reshape(basePreds, [size(basePreds, 1), 1, size(basePreds, 2)]));

  fig = figure();

  % Apply scale factor
  currSizeParams = get(0,'defaultfigureposition');
  fig.Position = [0.5, 0.5, args.figureScaleXY(1), args.figureScaleXY(2)] .* currSizeParams;

  boxplot(noiseMae, "OutlierSize", 15)

  title('Noise - No Noise');
  xlabel('MSTd Model');
  ylabel("Difference in absolute bias (" + char(176) + ")");

  % change tick label size
  ax = gca;
  ax.FontSize = 20;

  if ~isempty(args.xticklabels)
    ax.TickLabelInterpreter = 'latex';
    xticklabels(args.xticklabels)
  end

  % Set page area appropriately
  h = gcf;
  set(h,'PaperUnits','normalized');
  set(h,'PaperPosition', [0 0 1 1]);
  if args.figureScaleXY(1) > args.figureScaleXY(2)
    set(h, 'PaperOrientation', 'landscape');
  end
  print(gcf, '-dpdf', args.exportPDFName);
end

if args.showNoiseError
  % Create copy of noise predictions for bias
  modelPreds = matrix;

  % Get heading angles
  x = squeeze(xTicks(:, 1));

  % Convert to bias
  modelPreds(x > 0, :, :) = -modelPreds(x > 0, :, :);

  modelMeanErrors = squeeze(mean(modelPreds(:, minNoiseLvl:maxNoiseLvl, :) - modelPreds(:, 1, :), 2));
  stdModelErrors = squeeze(std(modelPreds(:, minNoiseLvl:maxNoiseLvl, :) - modelPreds(:, 1, :), [], 2));

  fig = figure();

  % Apply scale factor
  currSizeParams = get(0,'defaultfigureposition');
  fig.Position = [0.5, 0.5, args.figureScaleXY(1), args.figureScaleXY(2)] .* currSizeParams;

  %     errorbar(modelMeanErrors, stdModelErrors, '-o', 'MarkerSize', 15, "LineWidth", 2);
  plot(x, modelMeanErrors, '-o', 'MarkerSize', 15, "LineWidth", 2);

  title(data.title);
  xlabel("Heading (" + char(176) + ")");
  ylabel("Difference in bias (" + char(176) + ")");

  if strlength(args.legendLabels) > 0
    labels = args.legendLabels;
  end

  if args.showLegend
    numLabels = getLegendLabelValues(labels);
    le = legend(numLabels, "FontSize", 20, 'Orientation', args.legendOrientation, 'NumColumns', args.legendNumCols, ...
      'Location', args.legendLocation);
    le.Title.String = getLegendTitle(labels{1});
  end

  % change tick label size
  ax = gca;
  ax.FontSize = 20;
  ax.ColorOrder = distinguishable_colors(size(matrix, 2));

  ylim(args.ylim);

  if ~isempty(args.xticks)
    xticks(args.xticks)
  end

  if ~isempty(args.xticklabels)
    xticklabels(args.xticklabels)
  end

  % Create mini plot on bottom right showing MAE
  axes('Position', args.insetPosition);
  box on;

  % Extract model numeric labels
  modelStrs = regexp(args.legendLabels, '\d+\.*\d*', 'match');
  modelLabels = double([modelStrs{:}]);

  plot(modelLabels, mean(abs(modelMeanErrors)), '-s', 'MarkerSize', 15, "LineWidth", 2);

  xlabel('Model')
  ylabel("Mean Abs Bias Diff (" + char(176) + ")")

  ylim(args.inset_ylim);

  if ~isempty(args.inset_xticks)
    xticks(sort(args.inset_xticks));
  else
    xticks(sort(modelLabels));
  end

  if ~isempty(args.inset_xticklabels)
    xticklabels(args.inset_xticklabels);
  else
    xticklabels(modelLabels);
  end


  ax = gca;
  ax.FontSize = 16;

  % Set page area appropriately
  h = gcf;
  set(h, 'PaperPositionMode', 'auto');
  if args.figureScaleXY(1) > args.figureScaleXY(2)
    set(h, 'PaperOrientation', 'landscape');
  end
  %   print(gcf, '-dpdf', '-fillpage', args.exportPDFName);
  print(gcf, '-dpdf', args.exportPDFName);
end
end

function argStruct = parseInputs(argCell)
%parseInputs handle parameter overrides and defaults

% Handle parsing args and setting param defaults...
args = inputParser;
addParameter(args, 'reshapeSize', [21, 11, 7], @isnumeric);
addParameter(args, 'showAllModels', false, @islogical);
addParameter(args, 'showModelAvg', false, @islogical);
addParameter(args, 'showModelNoiseComparison', false, @islogical);
addParameter(args, 'showModelMeanComparison', false, @islogical);
addParameter(args, 'showNoiseError', false, @islogical);
addParameter(args, 'comparisonFilename', "", @(x) isstring(x) || ischar(x) || iscell(x));
addParameter(args, 'comparisonVersion', -1, @isnumeric);
addParameter(args, 'xticklabels', strings(0, 1), @(x) isstring(x) || ischar(x) || iscell(x));
addParameter(args, 'xticks', [], @isnumeric);
addParameter(args, 'inset_xticks', [], @isnumeric);
addParameter(args, 'inset_xticklabels', '', @(x) isstring(x) || ischar(x) || iscell(x));
addParameter(args, 'yticks', [], @isnumeric);
addParameter(args, 'ylim', [-5, 20], @isnumeric);
addParameter(args, 'legendLabels', '', @(x) isstring(x) || ischar(x));
addParameter(args, 'legendNumCols', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(args, 'legendLocation', 'north', @(x) ischar(x) || isstring(x));
addParameter(args, 'legendOrientation', 'vertical', @ischar);
addParameter(args, 'showLegend', true, @islogical);
addParameter(args, 'figureScaleXY', [1, 1], @(x) isnumeric(x) && length(x) == 2);
addParameter(args, 'insetPosition', [.7 .2 .2 .2], @isnumeric);
addParameter(args, 'inset_ylim', [0, 7], @(x) isnumeric(x) && length(x) == 2);
addParameter(args, 'exportPDFName', 'figure.pdf', @(x) isstring(x) || ischar(x));
parse(args, argCell{:});

% Get the struct containing the results of the param parsing
argStruct = args.Results;
end

function realFilename = setFilename(filename, versionNumber)
if isempty(filename)
  realFilename = filename;
  return
end

if versionNumber < 0
  versionNumber = FindLatestVersion("results/processed/" + filename, ".json");
end

if ~isempty(filename)
  realFilename = "results" + filesep + "processed" + filesep + filename + "-" + sprintf('%03d',versionNumber) + ".json";
else
  realFilename = "results" + filesep + "processed" + filesep + "lastPlotCache.json";
end
end


function title = getLegendTitle(label)
title = regexp(label, '.+:', 'match');
title = title{1}(1:end-1);
end


function labelVals = getLegendLabelValues(labels)
modelStrs = regexp(labels, ':.+', 'match');
modelStrs = cellfun(@(s) s{1}(3:end), modelStrs, 'UniformOutput', false);
labelVals = string(modelStrs);
end