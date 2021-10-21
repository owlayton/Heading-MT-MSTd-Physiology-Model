function resultsMatrixFinal = RunModel(varargin)
  args = parseInputs(varargin);
  
  for fileNameCell = args.fileNames
    fileName = fileNameCell(1);
    
    fileToRead = "modeling/parameters_json/" + fileName + ".json";
    configuration = jsonread(fileToRead);
    
    % difference between variations and independent variables:
    % variations are run while the config is being resolved (baseConfigs etc)
    % independent variables are run after the config is resolved.
    
    % handle the case where there aren't any variations natively by
    % creating a singleton array with the configuration in it
    configurations = {configuration};
    
    % loop that will resolve this configuration and all of its child
    % configurations that might have been generated through variations.
    % resolving means handling all variation independent variables as well
    % as handling all baseconfigs with as many levels of recursion as
    % required.
    configuration_i = 1;
    while configuration_i <= size(configurations,2)
      curr_config = configurations{configuration_i};
      % get variations that exist in this configuration instance
      variations = FindIndependentVariablesFromConfig(curr_config, "isVariationVariable");
      
      % if there are subvariations, resolve it, put it in the variations
      % and go there again. don't forget to remove the current variation
      % variable so that it is only processed once
      if size(variations, 1) > 0
        variation = variations{1};
        if variation.indVarType == "array"
          variation_range = 1:size( variation.array,1);
        else % range variable
          variation_range = variation.rangeStart:variation.rangeStep:variation.rangeEnd;
        end
        
        for variation_i = variation_range
          if variation.indVarType == "array"
            
            variationAccessor = variation.independentVariableAccessor;
            if iscell(variation.array)
              fieldValue = variation.array{variation_i};
            else
              fieldValue = variation.array(variation_i);
            end
          else % range variable
            fieldValue = variation_range(variation_i);
          end
          
          new_config = setfield(curr_config,variationAccessor{:},fieldValue);
          configurations{end+1} = new_config;
        end
        
        % remove the current configuration from variations
        configurations(configuration_i) = [];
        
        % continue so that we dont process the base config in this one
        continue;
        
      elseif isfield(curr_config, "baseConfig")
        % if there is a baseConfig in this variations, resolve one
        % level, update current config with that one, don't move to the
        % next variation yet.
        baseConfig = jsonread("modeling/parameters_json/" + curr_config.baseConfig);
        curr_config = rmfield(curr_config, "baseConfig");
        curr_config = BuildFromBaseConfig(baseConfig, curr_config);
        configurations{configuration_i} = curr_config;
      else
        % we only increment the index if we haven't updated the list.
        % this allows us to recursively resolve (i.e. multiple
        % baseConfigs) as well as prevent jumping over configurations
        % if we have deleted any configurations.
        
        % it is implicated that this for loop resolves one level of
        % variation or one level of baseConfig per iteration, and it
        % can take multiple iterations to resolve the same config, each
        % time resolving the next level of complexity created by the
        % previous resolution. iterations work on the same
        % configurations until there are no iterations to work on, at
        % which point the index is incremented and the iterations start
        % work on the following configuration. once the last
        % configuration is fully resolved, this while-loop will exit
        % by incrementing the index over the size of configurations
        configuration_i = configuration_i + 1;
      end
      
    end
    
    % configurations is now a list of fully resolved configuration
    % we will loop over each configurations and execute it.
    
    for config = configurations
      configuration = config{1};
      independentVariables = FindIndependentVariablesFromConfig(configuration);
      
      % multi-config, resolve it and populate configurationCombinations
      if size(independentVariables) > 0
        
        labels = {};
        for indVariable = independentVariables
          labels{end+1} = indVariable{1}.independentVariableAccessor{end};
        end
        
        independentVariableRanges = cell(0);
        
        for index = 1:size(independentVariables, 2)
          indVariable = independentVariables{index};
          % check if field exists for backwards compatibility
          if isfield(indVariable, "indVarType") && indVariable.indVarType == "array"
            % if we are using an array independent variable, put
            % indices to the range. we don't use the actual values so
            % that the code works with arrays of non-numbers (i.e.
            % strings). The actual value will be fetched from the array
            % during resolution.
            independentVariableRanges{index} = 1:size(indVariable.array,1);
          else
            independentVariableRanges{index} = indVariable.rangeStart:indVariable.rangeStep:indVariable.rangeEnd;
          end
        end
        
        configurationCombinations = ResolveMultiConfig(independentVariableRanges);
        
        processedConfigurations = cell(0);
        for configurationCombination = configurationCombinations
          currConfiguration = configuration; % copy over
          % change name
          currConfiguration.configurationName = currConfiguration.configurationName + "-";% + combinationCounter;
          configurationDisplayLabel = "";
          for index = 1:size(independentVariables, 2)
            independentVariableAccessor = independentVariables{index}.independentVariableAccessor;
            indVariable = independentVariables{index};
            if isfield(indVariable, "indVarType") && indVariable.indVarType == "array"
              if iscell(indVariable.array)
                configFieldValue = indVariable.array{configurationCombination(index)};
              else
                configFieldValue = indVariable.array(configurationCombination(index));
              end
            else % old ind. var. type (range)
              configFieldValue = configurationCombination(index);
            end
            currConfiguration = setfield(currConfiguration,independentVariableAccessor{:},configFieldValue);
            
            configurationLabelName = append(independentVariableAccessor{:});
            configurationDisplayLabel = append(configurationDisplayLabel, ", ",configurationLabelName,  ": ", num2str(configurationCombination(index)));
          end
          currConfiguration.configurationDisplayLabel = configurationDisplayLabel;
          processedConfigurations{end+1} = currConfiguration;
        end
      else % just a single-config, put the original config into the array to be run
        processedConfigurations = {configuration};
        configurationCombinations = [0];
      end
      
      %%% initialize these values up here because we need to know whether there
      %%% is a repeated dimension or not for stable random seeding
      hasPlot = false;
      plotVarIndependentInd = -1;
      plotVarErrorBarsInd = -1;
      plotVarRepeatedInd = -1;
      plotVarCurvesInd = -1;
      xLabel = "undefined";
      yLabel = "undefined";
      xTicksType = "undefined";
      for i = 1:size(independentVariables, 2)
        if isfield(independentVariables{i}, "plotting")
          hasPlot = true;
          % x-axis variable
          if independentVariables{i}.plotting.variable == "independent"
            plotVarIndependentInd = i;
            
            if isfield(independentVariables{i}.plotting, "xlabel")
              xLabel = independentVariables{i}.plotting.xlabel;
            else
              xLabel = strjoin(independentVariables{i}.independentVariableAccessor,"-");
            end
            
            if isfield(independentVariables{i}.plotting, "useHeading") && independentVariables{i}.plotting.useHeading == 1
              xTicksType = "useHeading";
            end
          end
          % calculate and draw error bars across this variable
          if independentVariables{i}.plotting.variable == "repeatedError"
            plotVarRepeatedInd = i;
            plotVarErrorBarsInd = i;
          end
          % take the mean across this variable
          if independentVariables{i}.plotting.variable == "repeatedMean"
            plotVarRepeatedInd = i;
            plotVarMeanInd = i;
          end
          % the variable that is "curved"
          if independentVariables{i}.plotting.variable == "curve"
            plotVarCurvesInd = i;
          end
        end
      end
      
      
      % keep the random seed stable for debugging.
      stableRandom = 4242;
      
      if args.runParallel
        [results, delDegXs, times, headings] = runParallel(processedConfigurations);
      else
        [results, delDegXs, times, headings] = runSerial(processedConfigurations);
      end
      
      if plotVarRepeatedInd == -1
        rng(stableRandom);
      end
      
      
      
      configurationCombinations = configurationCombinations';
      resultsMatrixFinal = [configurationCombinations results delDegXs times];
      
      
      
      
      %%%%%%%%%%%%%%   SAVE DATA    %%%%%%%%%%%%%%%%%%
      
      % assumption: processed data for this variation number ("00x") doesn't
      % exist. in the future, this problem can be fixed by modifying behavior
      % for overwriting in ProcessPlotData()
      
      if isfield(configuration.Model, "exportFinalData")
        
        basefilename = "results/raw/" + strrep(configuration.configurationName,"/","__") + "-";
        fileindex = 0;
        filename = basefilename + sprintf('%03d',fileindex) + ".mat";
        while isfile(filename)
          fileindex = fileindex + 1;
          filename = basefilename + sprintf('%03d',fileindex) + ".mat";
        end
        
        save(filename);
        ProcessPlotData(filename);
        
      end
      
      %%%%%%%%%%%%% PROCESS THE DATA %%%%%%%%%%%%%%%%%
      
      
      %%%%%%%%%%%%%% GENERATE PLOTS %%%%%%%%%%%%%%%%%%
      % even if didn't export, this will make sure the plots are generated
      save("lastPlotCache.mat");
      ProcessPlotData();
      
      % dirty workaround to skip generateplots if there is noise, since it
      % doesn't work with it.
      if ~contains(filename, "noise")
        GeneratePlots();
      end
      
    end
  end
end

function [results, delDegXs, times, headings] = runSerial(processedConfigurations)
  results = zeros(length(processedConfigurations),1);
  delDegXs = zeros(length(processedConfigurations),1);
  times = zeros(length(processedConfigurations),1);
  headings = zeros(length(processedConfigurations),1);
  
  for i = 1:length(processedConfigurations)
    currConfiguration = processedConfigurations{i};
    [expMovAvgAcc, expMovAvgDelX, currTime, heading] = run(currConfiguration);
    results(i) = expMovAvgAcc;
    delDegXs(i) = expMovAvgDelX;
    times(i) = currTime;
    headings(i) = heading;
    
    if currConfiguration.verbose
      fprintf("configuration #%d done\n", i)
    end
  end
end

function [results, delDegXs, times, headings] = runParallel(processedConfigurations)
  results = zeros(length(processedConfigurations),1);
  delDegXs = zeros(length(processedConfigurations),1);
  times = zeros(length(processedConfigurations),1);
  headings = zeros(length(processedConfigurations),1);
  
  parfor i = 1:length(processedConfigurations)
    currConfiguration = processedConfigurations{i};
    [expMovAvgAcc, expMovAvgDelX, currTime, heading] = run(currConfiguration);
    results(i) = expMovAvgAcc;
    delDegXs(i) = expMovAvgDelX;
    times(i) = currTime;
    headings(i) = heading;
    
    if currConfiguration.verbose
      fprintf("configuration #%d done\n", i)
    end
  end
end

function [expMovAvgAcc, expMovAvgDelX, currTime, heading] = run(currConfiguration)
  % run with current configuration
  
  % if result contains NaN, retry the config
  results_valid = 0;
  while results_valid == 0
    model = ModelManager();
    start_time = now;
    [~, ~, delDegX, accuracies, heading] = model.simulate(currConfiguration);
    end_time = now;
    if sum(isnan(accuracies)) == 0
      results_valid = 1;
    end
    sprintf("retrying due to NaN in values");
  end
  
  time = datevec(end_time - start_time);
  
  % take the average accuracy across steps to calculate
  % frameAccuracies
  stepsPerFrame = currConfiguration.Model.timestepsPerFrame;
  numFrames = length(accuracies) / stepsPerFrame;
  frameAccuracies = zeros(1, numFrames);
  frameDelDegX = zeros(1, numFrames);
  for j = 0:numFrames-1
    startI = 1 + j * stepsPerFrame;
    endI = (j+1) * stepsPerFrame;
    frameAccuracies(j+1) = mean(accuracies(1,startI: endI));
    frameDelDegX(j+1) = mean(delDegX(1,startI: endI));
  end
  
  % use exponential moving average of frame accuracies and frame
  % delta x error to calculate a single value for each.
  expMovAvgAcc = frameAccuracies(1);
  expMovAvgDelX = frameDelDegX(1);
  
  % decay rate, alpha, of the moving averages
  expMovAvgAlpha = 0.25;
  
  for accuracy = frameAccuracies(2:end)
    expMovAvgAcc = accuracy * expMovAvgAlpha + expMovAvgAcc * (1 - expMovAvgAlpha);
  end
  
  for delX = frameDelDegX(2:end)
    expMovAvgDelX = delX * expMovAvgAlpha + expMovAvgDelX * (1 - expMovAvgAlpha);
  end
  
  currTime = time(6);
end

function argStruct = parseInputs(argCell)
  %parseInputs handle parameter overrides and defaults
  
  % Handle parsing args and setting param defaults...
  args = inputParser;
  addOptional(args, 'fileNames', "default_noise", @isstring);
  addOptional(args, 'runParallel', 1, @(x) isnumeric(x) && isscalar(x));
  parse(args, argCell{:});
  
  % Get the struct containing the results of the param parsing
  argStruct = args.Results;
end
