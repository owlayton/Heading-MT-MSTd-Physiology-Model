classdef MSTdLayer < handle
  
  properties
    mtMSTDirTuning
    mtMSTDists
    config
    centerX
    centerY
    response
    numMSTdCells
    
    debug % to be used in the plot
    
  end
  
  methods
    
    function obj = MSTdLayer(params, MTLayer)
      obj.config = params;
      obj.numMSTdCells = obj.config.numberMSTdCells;
      
      % DESIGN: the data is held in a vector
      obj.response = zeros(obj.numMSTdCells, 1);
      obj.centerX = zeros(obj.numMSTdCells,1);
      obj.centerY = zeros(obj.numMSTdCells,1);
      
      % INITIALIZE CENTERS: "grid", "circular", or "random"
      for i = 1:obj.numMSTdCells
        if obj.config.samplingMethod == "grid" % GRID initialization
          gridCell = obj.numMSTdCells ^ .5;
          
          gridUnit = obj.config.resolution / (gridCell + 1);
          grid = gridUnit:gridUnit:obj.config.resolution - gridUnit;
          [gridX, gridY] = meshgrid(grid, grid);
          
          obj.centerX(i) = gridX(i);
          obj.centerY(i) = gridY(i);
          
        elseif obj.config.samplingMethod == "circular" % CIRCULAR initialization
          
          direction = 360 / obj.numMSTdCells * (i-1);
          maxDistance = (obj.config.resolution / 2) * obj.config.circularPlacementMaxDistanceCoeff;
          
          distance = maxDistance*rand() ^ obj.config.circularPlacementWeight;
          newX = distance * cosd(direction);
          newY = distance * sind(direction);
          
          while obj.config.allowCenter == 0 && newX == 0 && newY ==0
            distance = maxDistance*sind(randi([0 90])) ^ obj.config.circularPlacementWeight;
            newX = distance * cosd(direction);
            newY = distance * sind(direction);
          end
          
          obj.centerX(i) = newX + (obj.config.resolution / 2); % offset is center
          obj.centerY(i) = newY + (obj.config.resolution / 2);
          
        elseif obj.config.samplingMethod == "random" %RANDOM initialization
          
          obj.centerX(i) = rand() * obj.config.resolution;
          obj.centerY(i) = rand() * obj.config.resolution;
        end
      end
      numMTCells = MTLayer.config.numberOfCells;
      
      % COLUMNS: MTCells
      % ROWS: MSTdCells
      filterVectors = zeros(obj.numMSTdCells, numMTCells, 2);
      
      for MSTdCell_i = 1:obj.numMSTdCells
        for MTCell_i = 1:numMTCells
          u = MTLayer.cellX(MTCell_i) - obj.centerX(MSTdCell_i);
          v = MTLayer.cellY(MTCell_i) - obj.centerY(MSTdCell_i);
          magnitude = ((u.^2)+(v.^2)).^0.5;
          if magnitude == 0
            u = 0;
            v = 0;
          else
            u = u/magnitude;
            v = v/magnitude;
          end
          
          filterVectors(MSTdCell_i, MTCell_i,:) = [u,v];
          
        end
      end
      % Angles between each MT cell and each MSTd cell
      mstdTheta = atan2d(filterVectors(:,:,2), filterVectors(:,:,1));
      
      % Try doing dot product via cosine so that we can control the sharpness of the match score curve
      mtMstDot = cosd(MTLayer.cellPrefDirection' - mstdTheta);
      
      % How sharply do we want non-exact direction matches to be discounted?
      if mod(obj.config.cosTuningExp, 2) == 1
        % Odd power preserves sign
        obj.mtMSTDirTuning = mtMstDot.^obj.config.cosTuningExp;
      else
        % Even sign makes everything positive. Need to redistribute between [-1, +1]
        obj.mtMSTDirTuning = 2*mtMstDot.^obj.config.cosTuningExp - 1;
      end
      
      % Distances between MT and MSTd cells
      obj.mtMSTDists = (obj.centerX - MTLayer.cellX').^2 + (obj.centerY - MTLayer.cellY').^2;
    end
    
    function step(obj, MTCells)
      % Weight Mt-MSTd direction compatibility with actual MT cell activation
      MTStimulus = obj.mtMSTDirTuning .* MTCells.cellResponse';
      
      % Vectorized version of scaling by inverse MT-MSTd distance: 2x faster than loop
      sqrt2pi = sqrt(2*pi);
      dist_wt_sigma = obj.config.resolution * obj.config.distWtSigmaModifier;
      MTStimulus = MTStimulus .* exp(-0.5*obj.mtMSTDists / dist_wt_sigma^2);
      MTStimulus = (1/(sqrt2pi*dist_wt_sigma)) * MTStimulus;
      
      % Average across MT inputs
      MTStimulus = mean(MTStimulus, 2);
      
      % Take + inputs to MSTd
      MTStimulusExcit = MTStimulus .* (MTStimulus > 0);
      
      excitoryFactor = (obj.config.responseUpperBound - obj.response) .* MTStimulusExcit;
      decayFactor = obj.config.decayRate*obj.response;
      
      % Threshold negative activations
      obj.response(obj.response < 0) = 0;
      
      % multiply excitory and inhibitory factors by their
      % corresponding coefficients
      excitoryFactor = excitoryFactor .* obj.config.excitFactorCoeff;
      
      % update MSTd response
      delta_response = excitoryFactor - decayFactor;
      obj.debug = delta_response;
      obj.response = obj.response + 0.1*delta_response ;
    end
    
    function plotData(obj)
      recSz =15000;
      mid = recSz/2;
      clf;
      hold on;
      
      xlim([0 obj.config.resolution]);
      ylim([0 obj.config.resolution]);
      
      for i = 1:obj.numMSTdCells
        if obj.response(i) > 0
          %                     text(obj.centerX(i), obj.centerY(i), num2str(obj.debug(i)))
          rectangle('Curvature', 1, ...
            'Position', [obj.centerX(i) - obj.response(i)*mid, obj.centerY(i) - obj.response(i)*mid, ...
            obj.response(i)*recSz, obj.response(i)*recSz]);
        end
      end
      
      hold off;
      drawnow;
      figure(5);
      plot(obj.response);
      ylim([0 obj.config.responseUpperBound]);
    end
    
    function res = data(obj)
      res = obj.response;
    end
  end
  
  
end

