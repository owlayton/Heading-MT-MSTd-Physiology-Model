function PaperExperiments(varargin)
  %%PAPEREXPERIMENTS - Front-end to the experiments used in the paper Yumurtaci & Layton (2021) eNeuro.
  % Example Usage:
  % PaperExperiments('mode', "plot", 'figures', 1)
  % PaperExperiments('mode', "plot", 'figures', 1:2)
  % PaperExperiments('mode', "run", 'figures', 3)
  % PaperExperiments('mode', "both", 'figures', 4)
  %
  % Parameters:
  % 'mode': one of "run", "plot", or "both"
  % 'figures': List of figures to run/plot.
  %
  % NOTE: This does 1 run of noise experiments, in the paper we did 10 (each time with a different set of stimuli).
  
  args = parseInputs(varargin);
  
  if args.mode == "run"
    run = 1;
    plot = 0;
  elseif args.mode == "plot"
    run = 0;
    plot = 1;
  elseif args.mode == "both"
    run = 1;
    plot = 1;
  end
  
  currFig = 1;
  
  % ======================================================================= %
  % MSTd: Heading tuning experiments
  % ======================================================================= %
  % 1) Figure 5: MSTd heading distribution
  if run && any(currFig == args.figures)
    RunModel('fileNames', "paper/MSTd_circularWeight");
  end
  if plot && any(currFig == args.figures)
    labels = string(arrayfun(@(x) "{\gamma} = " + x, [0.1, 0.2, 0.5, 1, 2, 5, 10], 'UniformOutput', false));
    GeneratePlots("paper__MSTd_circularWeight", 'version', args.version, 'legendNumCols', 4, 'ylim', [-40, 60], ...
      'figureScaleXY', [1.5, 1], ...
      'showLegend', true, ...
      'xticks', -50:10:50, ...
      'legendLabels', labels, ...
      'legendLocation', 'north', ...
      'ylim', [-55, 60], ...
      'figureScaleXY', [1, 1], ...
      'exportPDFName', 'Figure05_1.pdf');
    GeneratePlots("paper__MSTd_circularWeight", 'version', args.version, 'plotError', true, 'showZeroLine', false, ...
      'showLegend', false, ...
      'figureScaleXY', [1.5, 1], ...
      'xticks', -50:10:50, ...
      'legendLabels', labels, ...
      'figureScaleXY', [1, 1], ...
      'exportPDFName', 'Figure05_2.pdf');
  end
  
  currFig = currFig + 1;
  % ======================================================================= %
  
  % 2) Figure 5-1: MT sampling experiment
  if run && any(currFig == args.figures)
    RunModel('fileNames', ["paper/Supp/MT_samplingMethod"]);
  end
  if plot && any(currFig == args.figures)
    GeneratePlots("paper__MT_samplingMethod", 'version', [0 1], 'ylim', [-5, 30], ...
      'xticks', -50:10:50, ...
      'figureScaleXY', [1, 2], ...
      'legendLabels', ["MT-samplingMethod: random", "MT-samplingMethod: grid"], ...
      'exportPDFName', 'Figure05-1.pdf', ...
      'legendNumCols', 2)
  end
  currFig = currFig + 1;
  % ======================================================================= %
  
  % 3) Figure 6: MSTd heading distribution noise
  if run && any(currFig == args.figures)
    RunModel('fileNames', ["paper/MSTd_circularWeight_noise"]);
  end
  
  if plot && any(currFig == args.figures)
    modelLabels = "{\gamma} = " + string([0.1, 0.2, 0.5, 1, 2, 5, 10]);
    xLabels = arrayfun(@(x) ['$\gamma$ = ', num2str(x)], [0.1, 0.2, 0.5, 1, 2, 5, 10], 'UniformOutput', false);
    ModelResultsPlot("paper__MSTd_circularWeight_noise", -1, ...
      'showModelNoiseComparison', true, ...
      'comparisonFilename',  "paper__MSTd_circularWeight", ...
      'comparisonVersion', -1, ...
      'xticklabels', xLabels, ...
      'xticks', -50:10:50, ...
      'ylim', [-55, 50], ...
      'legendLabels', modelLabels, ...
      'insetPosition', [0.64, 0.16, 0.25, 0.2], ...
      'reshapeSize', [21, 11, 7], ...
      'figureScaleXY', [1.3, 1], ...
      'exportPDFName', 'Figure06_0.pdf');
    
    ModelResultsPlot("paper__MSTd_circularWeight_noise", -1, ...
      'showModelAvg', true, ...
      'showModelMeanComparison', true, ...
      'comparisonFilename',  "paper__MSTd_circularWeight", ...
      'comparisonVersion', -1, ...
      'xticklabels', modelLabels, ...
      'xticks', -50:10:50, ...
      'yticks', -60:20:60, ...
      'ylim', [-55, 60], ...
      'legendLabels', modelLabels, ...
      'insetPosition', [0.64, 0.2, 0.25, 0.25], ...
      'reshapeSize', [21, 11, 7], ...
      'figureScaleXY', [1.3, 1], ...
      'exportPDFName', 'Figure06_1.pdf');
    
    
  end
  currFig = currFig + 1;
  % ======================================================================= %
  
  % ======================================================================= %
  % MSTd: RF size experiments
  % ======================================================================= %
  % 4) Figure 7: MSTd RF size
  if run && any(currFig == args.figures)
    RunModel('fileNames', "paper/distWtSigmaModifier");
  end
  if plot && any(currFig == args.figures)
    GeneratePlots("paper__distWtSigmaModifier", 'version', [0 1], ...
      'legendLocation', 'north', ...
      'legendPanel', 2, ...
      'legendLabels', "MSTd-RF-size: " + string([127 116 100 77 44 23]), ...
      'showZeroLine', false, ...
      'legendNumCols', 5, ...
      'xticks', -50:10:50, ...
      'figureScaleXY', [1, 2], ...
      'ylim', [-5, 70], ...
      'exportPDFName', 'Figure07_0.pdf')
    
    GeneratePlots("paper__distWtSigmaModifier", 'version', [0 1], 'plotError', true, ...
      'ylim', [0, 8], ...
      'legendLocation', 'north', ...
      'legendPanel', 2, ...
      'legendLabels', "MSTd-RF-size: " + string([127 116 100 77 44 23]), ...
      'showZeroLine', false, ...
      'legendNumCols', 5, ...
      'xticks', -50:10:50, ...
      'figureScaleXY', [1, 2], ...
      'exportPDFName', 'Figure07_1.pdf')
  end
  currFig = currFig + 1;
  % ======================================================================= %
  
  % 5) Figure 7: MSTd RF size noise
  if run && any(currFig == args.figures)
    RunModel('fileNames', ["paper/distWtSigmaModifier_noise"]);
  end
  if plot && any(currFig == args.figures)
    % 0.5 model
    ModelResultsPlot("paper__distWtSigmaModifier_noise", 0, ...
      'showNoiseError', true, ...
      'figureScaleXY', [1, 1], ...
      'xticks', -50:10:50, ...
      'xticklabels', string(-50:10:50), ...
      'ylim', [-5, 50], ...
      'reshapeSize', [21, 11, 6], ...
      'legendNumCols', 3, ...
      'legendLabels', "MSTd-RF-size: " + string([127 116 100 77 44 23]), ...
      'showLegend', false, ...
      'insetPosition', [0.6, 0.55, 0.3, 0.33], ...
      'inset_xticks', [127 116 100 77 44 23], ...
      'inset_xticklabels', string(["23" "44" "77" "100" "" "127"]), ...
      'inset_ylim', [0, 10], ...
      'exportPDFName', 'Figure07_2.pdf');
    
    % 2.0 model
    ModelResultsPlot("paper__distWtSigmaModifier_noise", 1, ...
      'showNoiseError', true, ...
      'figureScaleXY', [1, 1], ...
      'xticks', -50:10:50, ...
      'xticklabels', string(-50:10:50), ...
      'ylim', [-5, 50], ...
      'reshapeSize', [21, 11, 6], ...
      'legendNumCols', 3, ...
      'legendLabels', "MSTd-RF-size: " + string([127 116 100 77 44 23]), ...
      'showLegend', false, ...
      'legendLocation', 'northwest', ...
      'insetPosition', [0.6, 0.55, 0.3, 0.33], ...
      'inset_ylim', [0, 10], ...
      'inset_xticks', [127 116 100 77 44 23], ...
      'inset_xticklabels', string(["23" "44" "77" "100" "" "127"]), ...
      'exportPDFName', 'Figure07_3.pdf');
  end
  currFig = currFig + 1;
  % ======================================================================= %
  
  % ======================================================================= %
  % MSTd: direction tuning experiments
  % ======================================================================= %
  % 6 ) Figure 8: MSTd direction tuning (cosine exp experiment)
  if run && any(currFig == args.figures)
    RunModel('fileNames', "paper/MSTd_cosineTuning");
  end
  if plot && any(currFig == args.figures)
    GeneratePlots("paper__MSTd_cosineTuning", 'version', [0 1], ...
      'legendLocation', 'north', ...
      'legendPanel', 2, ...
      'legendLabels', "MSTd-Cos-Exp-q: " + string([1 2]), ...
      'showZeroLine', true, ...
      'legendNumCols', 5, ...
      'xticks', -50:10:50, ...
      'figureScaleXY', [1, 2], ...
      'ylim', [-5, 50], ...
      'exportPDFName', 'Figure07_0.pdf')
    
  end
  currFig = currFig + 1;
  
  % ======================================================================= %
  % MT: Direction experiments
  % ======================================================================= %
  % 7) Figure 9: MT direction variation
  if run && any(currFig == args.figures)
    RunModel('fileNames', "paper/MT_directionVariance");
  end
  if plot && any(currFig == args.figures)
    GeneratePlots("paper__MT_directionVariance", 'version', [0 1], 'legendNumCols', 5, 'ylim', [-5, 50], ...
      'legendLocation', 'north', ...
      'legendLabels', "MT-{\sigma_d}: " + string(0:60:360), ...
      'xticks', -50:10:50, ...
      'figureScaleXY', [1, 2], ...
      'legendPanel', 2, ...
      'ylim', [-5, 60], ...
      'exportPDFName', 'Figure09_0.pdf')
  end
  currFig = currFig + 1;
  % ======================================================================= %
  
  % 8) Figure 9: MT direction variation noise influence
  if run && any(currFig == args.figures)
    RunModel('fileNames', ["paper/MT_directionVariance_noise"]);
  end
  if plot && any(currFig == args.figures)
    % 0.5 model
    ModelResultsPlot("paper__MT_directionVariance_noise", 0, ...
      'showNoiseError', true, ...
      'xticks', -50:10:50, ...
      'xticklabels', string(-50:10:50), ...
      'ylim', [-40, 20], ...
      'reshapeSize', [21, 11, 7], ...
      'legendLabels', "MT-{\sigma_d}: " + string(0:60:360), ...
      'legendNumCols', 7, ...
      'showLegend', false, ...
      'insetPosition', [0.6, 0.31, 0.3, 0.3], ...
      'inset_ylim', [0, 12], ...
      'exportPDFName', 'Figure09_1.pdf');
    
    % 2.0 model
    ModelResultsPlot("paper__MT_directionVariance_noise", 1, ...
      'showNoiseError', true, ...
      'xticks', -50:10:50, ...
      'xticklabels', string(-50:10:50), ...
      'ylim', [-40, 20], ...
      'reshapeSize', [21, 11, 7], ...
      'legendLabels', "MT-{\sigma_d}: " + string(0:60:360), ...
      'showLegend', false, ...
      'legendNumCols', 7, ...
      'insetPosition', [0.6, 0.31, 0.3, 0.3], ...
      'inset_ylim', [0, 12], ...
      'exportPDFName', 'Figure09_2.pdf');
  end
  currFig = currFig + 1;
  % ======================================================================= %
  
  % ======================================================================= %
  % MT: Speed experiments
  % ======================================================================= %
  % 9) Figure 10: Speed type variations: The actual experiment
  if run && any(currFig == args.figures)
    RunModel('fileNames', "paper/MT_speedType");
  end
  if plot && any(currFig == args.figures)
    GeneratePlots("paper__MT_speedType", 'version', [0, 1], 'legendLocation', 'north', ...
      'xticks', -50:10:50, ...
      'figureScaleXY', [1, 2], ...
      'legendPanel', 1, ...
      'legendLabels', "MT-speedType: " + string(0:3), ...
      'ylim', [-15, 40], ...
      'legendNumCols', 4, ...
      'exportPDFName', 'Figure10_0.pdf');
  end
  currFig = currFig + 1;
  % ======================================================================= %
  
  
  % 10) Figure 10: MT speed type: influence of noise
  if run && any(currFig == args.figures)
    RunModel('fileNames', ["paper/MT_speedType_noise"]);
  end
  if plot && any(currFig == args.figures)
    % 0.5 model
    ModelResultsPlot("paper__MT_speedType_noise", 0, ...
      'showNoiseError', true, ...
      'xticks', -50:10:50, ...
      'xticklabels', string(-50:10:50), ...
      'ylim', [-5, 40], ...
      'reshapeSize', [21, 11, 4], ...
      'legendNumCols', 5, ...
      'legendLabels', "MT-speed-type: " + string(0:3), ...
      'showLegend', false, ...
      'inset_ylim', [0, 10], ...
      'insetPosition', [0.58, 0.55, 0.3, 0.3], ...
      'exportPDFName', 'Figure10_1.pdf');
    
    % 2.0 model
    ModelResultsPlot("paper__MT_speedType_noise", 1, ...
      'showNoiseError', true, ...
      'xticks', -50:10:50, ...
      'xticklabels', string(-50:10:50), ...
      'ylim', [-5, 40], ...
      'reshapeSize', [21, 11, 4], ...
      'legendLabels', "MT-speed-type: " + string(0:3), ...
      'showLegend', false, ...
      'legendNumCols', 5, ...
      'inset_ylim', [0, 10], ...
      'insetPosition', [0.58, 0.55, 0.3, 0.3], ...
      'exportPDFName', 'Figure10_2.pdf');
  end
  % ======================================================================= %
end

function argStruct = parseInputs(argCell)
  %parseInputs handle parameter overrides and defaults
  
  % How many figures could we make in total?
  numFigs = 10;
  
  % Handle parsing args and setting param defaults...
  args = inputParser;
  addOptional(args, 'mode', "plot", @isstring);
  addOptional(args, 'version', -1, @(x) isnumeric(x) && isscalar(x));
  addOptional(args, 'testNum', 1, @(x) isnumeric(x) && isscalar(x));
  addOptional(args, 'figures', 1:numFigs, @(x) isnumeric(x) && ~isempty(x));
  parse(args, argCell{:});
  
  % Get the struct containing the results of the param parsing
  argStruct = args.Results;
end

