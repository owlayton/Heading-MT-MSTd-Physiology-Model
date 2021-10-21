function ProcessPlotData(filename)
% TAKES .MAT FILE, PROCESSES IT TO A .JSON FILE, TO BE USED BY 
% ONE OF THE PLOTTING FUNCTIONS

    if exist("filename","var")
        loadfrom = filename;
    else
        loadfrom = 'lastPlotCache.mat';
    end
   
    load(loadfrom);
    
    jsonData = struct();
    
    %================= PROCESSING =================%
    
    if configuration.plotMetric == "delDegX"
        metric = delDegXs; yLabel = "delta degrees (x-axis)";
    elseif configuration.plotMetric == "accuracy"
        metric = results; yLabel = "accuracy (mean of Euclidean distance from true heading)";
    elseif configuration.plotMetric == "time"
        metric = times; yLabel = "time (in seconds)";
    end
    
    % plotting happens here
    if hasPlot
        
        curvesRange = independentVariableRanges{plotVarCurvesInd};
        numCurves = size(curvesRange,2);
        
        configs = configurationCombinations;
        pointsPerCurve = size(configs(:,1),1)/size(curvesRange,2);
        if plotVarRepeatedInd ~= -1
            pointsPerCurve = pointsPerCurve / size(independentVariableRanges{plotVarRepeatedInd},2);
        end
        xRange = 1:1:pointsPerCurve;
        
        [~, xTickIndices, ~] = unique(configurationCombinations(:,plotVarIndependentInd), 'rows');
        
        if plotVarRepeatedInd ~= -1
            
            % we'll find unique rows without the repeated value among
            % configCombinations.
            % Then, take a mean (common to both methods)
            % then, calculate error bars, if it's in the config
            columns = 1:size(independentVariables,2);
            columns = columns(columns~=plotVarRepeatedInd);
            [uniqueRows, ia, ~] = unique(configurationCombinations(:,columns), 'rows');
            finalMetric = zeros(size(ia,1),1);
            errorStds = zeros(size(ia,1),1);
            for uniqueRowI = 1:size(uniqueRows,1)
                uniqueRow = uniqueRows(uniqueRowI,:);
                indices = all(configurationCombinations(:, columns) == uniqueRow, 2);
                dataInRow = metric(indices);
                finalMetric(uniqueRowI) = mean(dataInRow);
                errorStds(uniqueRowI) = std(dataInRow);
                
            end
            
            % update configurationCombinations so that the repeated axis is
            % not repeated anymore
            configurationCombinations = configurationCombinations(ia,:);
            
        else
            % if we have a repeated variable, this will be set already
            % otherwise, initiate it here
            finalMetric = metric;
            ia = xRange;
        end
        
        matrix = zeros(pointsPerCurve,numCurves);
        errorMatrix = zeros(pointsPerCurve,numCurves);
        labels = strings(1,numCurves);
        for j = 1:numCurves
            % if there is a repeated ind, take only unique rows
            if plotVarRepeatedInd ~= -1
                matrix(:,j) = finalMetric(configs(ia,plotVarCurvesInd) == curvesRange(j),:);
            else
                matrix(:,j) = finalMetric(configs(:,plotVarCurvesInd) == curvesRange(j),:);
            end
            
            if plotVarErrorBarsInd ~= -1
                errorMatrix(:,j) = errorStds(configs(ia,plotVarCurvesInd) == curvesRange(j),:);
            end
            
            indVariable = independentVariables{plotVarCurvesInd};
            
            if isfield(independentVariables{plotVarCurvesInd}.plotting, "customName")
                labelPre = independentVariables{plotVarCurvesInd}.plotting.customName + " = ";
            else
                labelPre = strcat(strjoin(independentVariables{plotVarCurvesInd}.independentVariableAccessor,"-"), " : ");
            end
            
            if isfield(indVariable, "indVarType") && indVariable.indVarType == "array"
                if iscell(indVariable.array) % cell array
                    labelPost = indVariable.array{j};
                else % matrix. it is a number so convert value to a string
                    labelPost = num2str(indVariable.array(j));
                end
            else
                labelPost = num2str(curvesRange(j));
            end
            labels(j) = strcat(labelPre, labelPost);
            labels(j) = strrep(labels(j), "\", "\\");
        end
        
        
        if xTicksType ~= "undefined" && xTicksType == "useHeading"
            xTicks = headings(xTickIndices);
        else
            xTicks = 1:size(xRange,2);
            xTicks = xTicks';
        end
        
        jsonData.xTicks = xTicks;
        jsonData.matrix = matrix;
        if plotVarErrorBarsInd ~= -1
            jsonData.errorMatrix = errorMatrix;
        end
        jsonData.plotVarErrorBarsInd = plotVarErrorBarsInd;
        jsonData.xRange = xRange;
        jsonData.xLabel = xLabel;
        jsonData.yLabel = yLabel;
        jsonData.labels = labels;
        if isfield(configuration, "title")
            jsonData.title = configuration.title;
        end
        
        % find file name (with version)
        
        if strcmp(loadfrom, 'lastPlotCache.mat')
            savefilename = "results/processed/lastPlotCache.json";
        else
            savefilename = strrep(strrep(loadfrom, ".mat", ".json"),"/raw/","/processed/");
        end
        
        fid = fopen(savefilename,'wt');
        fprintf(fid, jsonencode(jsonData));
        fclose(fid);
    
end

