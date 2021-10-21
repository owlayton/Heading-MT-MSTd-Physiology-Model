function GeneratePlots(filename, varargin)
  
  args = parseInputs(varargin);
  versionNumbers = args.version;
  numPlots = numel(versionNumbers);
  
  % Allow us to plot multiple "versions" (of the model) in a tiling plot
  fig = figure();
  t = tiledlayout(fig, 'flow');
  t.TileSpacing = 'compact';
  
  % Set figure size as multiples of original size (assuming vertical plot for now)
  % and make the figure a little wider
  pos = get(fig, 'position');
  set(fig, 'position', pos.*[1 1/numPlots 1.1 numPlots]);
  
  % Apply scale factor
  currSizeParams = get(0,'defaultfigureposition');
  fig.Position = [0.5, 0.5, args.figureScaleXY(1), args.figureScaleXY(2)] .* currSizeParams;
  
  for v = 1:numPlots
    nexttile;
    versionNumber = versionNumbers(v);
    
    % Data file
    if ~exist("filename", "var")
      filename = [];
    end
    fileName = setFilename(filename, versionNumber);
    
    data = jsonread(fileName);
    xRange = data.xRange;
    xLabel = data.xLabel;
    yLabel = data.yLabel;
    labels = data.labels;
    xTicks = data.xTicks;
    plotVarErrorBarsInd = data.plotVarErrorBarsInd;
    
    % Are we plotting the error (stdev) or the data?
    if args.plotError
      matrix = data.errorMatrix;
      yLabel = "variability (stdev)";
      plotVarErrorBarsInd = -1;
    else
      matrix = data.matrix;
    end
    
    if plotVarErrorBarsInd ~= -1
      errorMatrix = data.errorMatrix;
    end
    
    % Comparison data (for diff plots, if applicable)
    if ~isempty(args.diffFilename)
      diffFilename = setFilename(args.diffFilename, versionNumber);
      compFile = jsonread(diffFilename);
      compMatrix = compFile.matrix;
      compStd = compFile.errorMatrix;
      
      % Assuming diff/comp file is the comparison file. calc diff, errorbars on diff
      diffData = compMatrix - matrix;
      diffStd = sqrt(errorMatrix + compStd);
    else
      % Are we expressing heading error as center (+) or peripheral (-) bias?
      % If so, we need to negate errors positive headings
      if args.plotBias && ~args.plotError
        matrix(xTicks > 0, :) = -matrix(xTicks > 0, :);
      end
    end
    
    hold on;
    
    % plot the data
    if args.plotError
      % Regular plot without error bars (e.g. Stdev plot)
      plot(repmat(xTicks,1,size(matrix,2)), matrix, "-+", "LineWidth", 1, "MarkerSize", 15);
    elseif args.plotAvgDiffError
      avgDiffError = mean(abs(diffData));
      avgDiffStd = std(abs(diffData));
      
      errorbar(avgDiffError, avgDiffStd, '-ko','MarkerSize', 15, "LineWidth", 2);
      %       plot(avgDiffError, '-ko','MarkerSize', 15, "LineWidth", 2);
      xTicks = 1:size(diffData, 2);
      xTickLabels = labels;
      xlim([0.5, size(diffData, 2)+0.5]);
      xLabel = "";
      if args.plotBias
        yLabel = "mean object heading bias (" + char(176) + ")";
      else
        yLabel = "mean object abs heading error  (" + char(176) +")";
      end
    else
      % Line plot with error bars
      errorbar(xTicks, matrix(:, 1), errorMatrix(:, 1), '-o', "LineWidth", 1, "MarkerSize", 10);
      for m = 2:size(matrix, 2)
        errorbar(xTicks, matrix(:, m), errorMatrix(:, m), '-o', "LineWidth", 1, "MarkerSize", 10);
      end
      yLabel = "heading bias {\alpha} (" +  char(176) +")";
      disp(mean(abs(matrix), 1));
      disp(mean(errorMatrix, 1));
    end
    
    % zero line
    if args.showZeroLine
      plot(linspace(min(xTicks), max(xTicks)), zeros(size(xRange,2),1), ".", 'Color', [0.7, 0.7, 0.7]);
    end
    hold off;
    
    % Set the xticks
    if ~isempty(args.xticks)
      xTicks = args.xticks(:);
    end
    xticks(xTicks(:));
    
    
    % Override x trick labels (if specified)
    if ~isempty(args.xticklabels)
      xticklabels(args.xticklabels);
    elseif exist('xTickLabels', 'var')
      xticklabels(xTickLabels);
    else
      xticklabels(string(num2cell(xTicks)));
    end
    
    % Override x axis label (if specified)
    if ~isempty(args.xlabel)
      xLabel = args.xlabel;
    end
    xLabel = strrep(xLabel, 'deg', char(176));
    
    % change tick label size
    ax = gca;
    ax.FontSize = 20;
    
    % Make colors discriminatable
    ax.ColorOrder = distinguishable_colors(size(matrix, 2));
    
    if numPlots == 1
      xlabel(xLabel, "FontSize", 20);
      ylabel(yLabel, "FontSize", 20);
    else
      xlabel(t, xLabel, "FontSize", 20);
      ylabel(t, yLabel, "FontSize", 20);
    end
    
    if args.legendPanel == v && args.showLegend
      if strlength(args.legendLabels) > 0
        labels = args.legendLabels;
      end
      
      numLabels = getLegendLabelValues(labels);
      le = legend(numLabels, "FontSize", 20, 'Orientation', args.legendOrientation, 'NumColumns', args.legendNumCols);
      le.Title.String = getLegendTitle(labels{1});
      
      if ~isempty(args.legendLocation)
        le.Location = args.legendLocation;
      end
    end
    
    if isfield(data, "title")
      title(data.title);
    end
    
    % If user passed in ylim override
    if all(args.ylim ~= -1)
      ylim(args.ylim)
    end
  end
  
  % Set page area appropriately
  h = gcf;
  set(h, 'PaperPositionMode', 'auto');
  if args.figureScaleXY(1) > args.figureScaleXY(2)
    set(h, 'PaperOrientation', 'landscape');
  end
  %   print(gcf, '-dpdf', '-fillpage', args.exportPDFName);
  print(gcf, '-dpdf', args.exportPDFName);
  %   h = gcf;
  %   set(h, 'PaperPositionMode', 'auto');
  %   if args.figureScaleXY(1) > args.figureScaleXY(2)
  %     set(h, 'PaperOrientation', 'landscape');
  %   end
  %   print(gcf, '-dpdf', '-fillpage', args.exportPDFName);
  %   print(gcf, '-dpdf', args.exportPDFName);
end

function argStruct = parseInputs(argCell)
  %parseInputs handle parameter overrides and defaults
  
  % Handle parsing args and setting param defaults...
  args = inputParser;
  addParameter(args, 'version', -1, @isnumeric);
  addParameter(args, 'xlabel', strings(0, 1), @(x) isstring(x) || ischar(x));
  addParameter(args, 'xticklabels', strings(0, 1), @(x) isstring(x) || ischar(x));
  addParameter(args, 'xticks', [], @isnumeric);
  addParameter(args, 'ylim', -1, @(x) isnumeric(x) && length(x) == 2);
  addParameter(args, 'legendOrientation', 'vertical', @ischar);
  addParameter(args, 'legendNumCols', 1, @(x) isnumeric(x) && isscalar(x));
  addParameter(args, 'legendPanel', 1, @(x) isnumeric(x) && isscalar(x));
  addParameter(args, 'legendLocation', '', @(x) ischar(x) || isstring(x));
  addParameter(args, 'legendLabels', "", @(x) isstring(x) || ischar(x));
  addParameter(args, 'plotBias', true, @islogical);
  addParameter(args, 'plotError', false, @islogical);
  addParameter(args, 'diffFilename', '', @(x) ischar(x) || isstring(x));
  addParameter(args, 'plotAvgDiffError', false, @islogical);
  addParameter(args, 'showLegend', true, @islogical);
  addParameter(args, 'showZeroLine', true, @islogical);
  addParameter(args, 'figureScaleXY', [1, 1], @(x) isnumeric(x) && length(x) == 2);
  addParameter(args, 'exportPDFName', 'figure.pdf', @(x) isstring(x) || ischar(x));
  parse(args, argCell{:});
  
  % Get the struct containing the results of the param parsing
  argStruct = args.Results;
end

function realFilename = setFilename(filename, versionNumber)
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
  title = regexp(label, '.+:|.+=', 'match');
  title = title{1}(1:end-1);
end


function labelVals = getLegendLabelValues(labels)
  modelStrs = regexp(labels, ':.+|=.+', 'match');
  modelStrs = cellfun(@(s) s{1}(3:end), modelStrs, 'UniformOutput', false);
  labelVals = string(modelStrs);
end
