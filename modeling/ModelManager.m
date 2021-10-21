classdef ModelManager < handle
    %MODELMANAGER Summary of this class goes here
    
    properties
        config
        predictionsX
        predictionsY
    end
    
    methods
        function obj = ModelManager()
            %MODELMANAGER Construct an instance of this class
            obj.predictionsX = [];
            obj.predictionsY = [];
        end
        
        function generatePredictionFromMSTdData(obj, layerMSTd)
            MSTdData = layerMSTd.data();
            
            totalMSTdWeight = sum(sum(MSTdData));
            
            predictionX = 0;
            predictionY = 0;
            
            for i = 1:layerMSTd.numMSTdCells
                predictionX = predictionX + layerMSTd.centerX(i) * MSTdData(i);
                predictionY = predictionY + layerMSTd.centerY(i) * MSTdData(i);
            end
            
            predictionX = predictionX / totalMSTdWeight;
            predictionY = predictionY / totalMSTdWeight;
            
            obj.predictionsX(end+1) = predictionX;
            obj.predictionsY(end+1) = predictionY;
            
        end
        
        function superimpose_visualization(obj, frame)
            
            clf; % the desired figure should be activated before this function is called
            hold on;
            
            
            x = frame(:,1)';
            y = frame(:,2)';
            dx = frame(:,3)';
            dy = frame(:,4)';
            n = round(size(x,2)/976);% plot every nth vector
            
            x = x(:,n:n:end);
            y = y(:,n:n:end);
            dx = dx(:,n:n:end);
            dy = dy(:,n:n:end);
            
            quiver(x, y, dx, dy, 2);
        end
        
        function plotVectorsAndPrediction(obj, frame, MTConfig, centerX, centerY, frame_i)
            DRAW_LAST_FRAMES = 0;
            
            if size(obj.predictionsX,2) > DRAW_LAST_FRAMES
                clf;
                hold on; 
                
                x = frame(:,1)';
                y = frame(:,2)';
                dx = frame(:,3)';
                dy = frame(:,4)';
                n = round(size(x,2)/976);% plot every nth vector
                
                x = x(:,n:n:end);
                y = y(:,n:n:end);
                dx = dx(:,n:n:end);
                dy = dy(:,n:n:end);
                
                quiver(x, y, dx, dy, 2);
                
                plot(obj.predictionsX(end - DRAW_LAST_FRAMES:end), obj.predictionsY(end - DRAW_LAST_FRAMES:end),'o');
                plot(centerX, centerY,'x');
                
                axis([0 MTConfig.resolution 0 MTConfig.resolution])
                hold off;
                drawnow;
                pause(0.1);
            end
        end
        function [predX, predY, delDegX, accuracies, heading] = simulate(obj,inputConfig)
            
            
            obj.config = inputConfig;
            
            MTConfig = obj.config.MT;
            MSTdConfig = obj.config.MSTd;
            
            foldername = "optic_flow_generator/exports/"; % default, backwards compatibility
            if isfield(obj.config.Data, "folder")
                foldername = obj.config.Data.folder;
            end
            
            if obj.config.Data.framesFileName.isPartial
                finalFileName =  strcat( foldername, ...
                    obj.config.Data.framesFileName.partial.pre, ...
                    char(num2str(obj.config.Data.framesFileName.partial.mid)), ...
                    obj.config.Data.framesFileName.partial.post);
            else
                finalFileName = foldername + ...
                    obj.config.Data.framesFileName.name;
            end
            load(finalFileName);
            
            frames = simulatedScene.totalRenderedPoints;
            heading = simulatedScene.configuration.observerHeading;
            observerFocalLength = simulatedScene.configuration.observerFocalLength;
            fovHemiThres = observerFocalLength * tand(simulatedScene.configuration.observerFovAngle/2);
            centerX = (MTConfig.resolution + 1) / 2;
            centerY = (MTConfig.resolution + 1) / 2;
            
            % Compute speeds on 1st frame to help us sample MT speed preferences.
            sampleSpds = sqrt(frames{1}(:, 3).^2 + frames{1}(:, 4).^2);
            
            % Initialize MT and MSTd layers
            layerMT = MTLayer(MTConfig, sampleSpds);
            layerMSTd = MSTdLayer(MSTdConfig, layerMT);
            
            for frame_i = 1:size(frames,2)
                frame = frames{frame_i};
                
                stimulus  = layerMT.calculate_step_vars(frame, obj.config.Model.timestepsPerFrame);
                for timestep = 1:obj.config.Model.timestepsPerFrame
                    layerMT.step(stimulus, obj.config.Model.timestepsPerFrame);
                    layerMSTd.step(layerMT);
                    
                    obj.generatePredictionFromMSTdData(layerMSTd);
                    
                end
                if isfield(obj.config, "drawPlots") && obj.config.drawPlots ~= 0
                    if obj.config.verbose && frame_i == 1
                        disp(['Current true heading: ', num2str(heading)]);
                    end
                    
                    figure(1);
                    layerMSTd.plotData();
                    
                    %figure(2);
                    %layerMT.plotData();
                    
                    %figure(3);
                    %plotVectorsAndPrediction(obj, frame, MTConfig, centerX, centerY, frame_i);
                    
                    %figure(4);
                    %clf('reset')
                    %viscircles([layerMSTd.centerX layerMSTd.centerY], 5*(layerMSTd.data() - min(layerMSTd.data())));
                    %drawnow;
                end
            end
            
            % calculate variables to be returned
            % Raw pixel positions between [1, res] x [1, res]
            predX = obj.predictionsX;
            predY = obj.predictionsY;
            
            % Pixel offsets from center of the screen [res/2, res/2]
            predXCent = predX - centerX;
            predYCent = predY - centerY;
            
            % Proportion of X prediction on one side of the screen.
            predXNormPos = predXCent / (MTConfig.resolution/2);
            % How far is that on the projection plane relative to the max FOV
            predXPropFov = predXNormPos * fovHemiThres;
            
            % Determine the predicted heading based on coordinates in projection plane
            % x: predXPropFov
            % z: f
            headingPred = atand(predXPropFov / observerFocalLength);
            delDegX = headingPred - heading;
            accuracies = (predXCent.^ 2 + predYCent.^2) .^ .5;
            
            if all(isnan(delDegX))
              fprintf('WARNING: heading prediction is NaN!\n');
            end
            
            if obj.config.verbose
              disp("  Done! Estimated heading (deg) = " + headingPred(end) + " | Error (deg) = " + delDegX(end));
            end
        end
    end
end

