classdef MTLayer < handle
  %MTLAYER new MTLayer with a matrix based implementation (instead of OOP)
  
  properties
    config
    numberOfCells
    
    cellX
    cellY
    cellRadius
    cellCenterDist
    
    cellResponse
    
    cellPrefDirection
    cellPrefSpeed
  end
  
  methods
    function obj = MTLayer(params, spdSamples)
      obj.config = params;
      obj.numberOfCells = params.numberOfCells;
      
      obj.cellX = zeros(obj.numberOfCells,1);
      obj.cellY = zeros(obj.numberOfCells,1);
      obj.cellRadius = zeros(obj.numberOfCells,1);
      obj.cellResponse = zeros(obj.numberOfCells,1);
      obj.cellPrefDirection = zeros(obj.numberOfCells,1);
      obj.cellPrefSpeed = zeros(obj.numberOfCells,1);
      
      obj.initializeCells(spdSamples);
      
    end
    
    function initializeCells(obj, spdSamples)
      
      if obj.config.samplingMethod == "random"
        
        obj.cellX = randi([1, obj.config.resolution],obj.numberOfCells,1);
        obj.cellY = randi([1, obj.config.resolution],obj.numberOfCells,1);
        
      elseif obj.config.samplingMethod == "grid"
        
        gridCell = obj.numberOfCells ^ .5;
        
        gridUnit = obj.config.resolution / (gridCell + 1);
        grid = gridUnit:gridUnit:obj.config.resolution - gridUnit;
        
        [gridX, gridY] = meshgrid(grid, grid);
        
        obj.cellX = gridX(:);
        obj.cellY = gridY(:);
      end
      
      mid = obj.config.resolution / 2;
      obj.cellCenterDist = (((obj.cellX-mid) .^ 2 + (obj.cellY - mid) .^ 2) .^ .5);
      
      % Speed Type 3 = RF size that increases with eccentricity.
      if obj.config.speed.speedType == 3
        rfBaseRad = obj.config.radius.baseRadiusSpdType3;
        rfDistModifier = obj.config.radius.distanceModifierSpdType3;
        rfRandVar = obj.config.radius.randomVarianceSpdType3;
      else
        rfBaseRad = obj.config.radius.baseRadius;
        rfDistModifier = obj.config.radius.distanceModifier;
        rfRandVar = obj.config.radius.randomVariance;
      end
      
      obj.cellRadius = getRadii(...
        obj.cellCenterDist, ...
        rfBaseRad, ...
        rfDistModifier, ...
        obj.numberOfCells, ...
        rfRandVar);
      
      obj.cellPrefDirection = ...
        atan2d(obj.cellY - mid, obj.cellX - mid) + ...
        (rand(obj.numberOfCells,1) - .5) * obj.config.directionPreferenceVarianceFromCenter;
      obj.cellPrefDirection = mod(obj.cellPrefDirection, 360);
      obj.cellPrefDirection(obj.cellPrefDirection>180) = obj.cellPrefDirection(obj.cellPrefDirection>180) - 360;
      
      
      % SPEED
      obj.cellPrefSpeed = zeros(obj.numberOfCells, 1);
      
      % We support 4 types of speed sampling
      % 0) No speed / doesn't factor into MT responses
      % 1) Uniform random speed sampling (doDistScaling = false)
      % 2+3) Speed prefs proportional to distance to center of the screen
      %   e.g. could be faster/slow/no bias as you go farther out from the center
      
      % no speed
      if obj.config.speed.speedType == 0
        
        % uniform
      elseif obj.config.speed.speedType == 1
        % Uniform sampling in valid speed range
        obj.cellPrefSpeed = max(spdSamples)*rand(obj.numberOfCells, 1);
        
        % speed pref is a function of distance to center in types 2+3
        % Type 2 = constant RF size.
        % Type 3 = RF size that increases with eccentricity. (latter handled above this conditional statement)
      elseif obj.config.speed.speedType == 2 || obj.config.speed.speedType == 3
        % Normalize distance: 0-1
        betaMu = (sqrt(2)/2) * obj.cellCenterDist / mid;
        % Weight normalized dist via gamma function (e.g. w/ exp 1/10 -> 10)
        % This gives biased values which are the means of a beta distribution.
        % I think it makes sense to specify either the numerator or denominator as
        % ints. Whichever you you specify, the other one should be set to 1. Based on the histrograms, reasonable
        % ranges are (1/10) to (10/1). So the numerator/denominator should be varied/analyzed separately 1 to ~10.
        %                 betaMu = normCentDist .^(obj.config.speed.type2betaMuExpNumer/obj.config.speed.type2betaMuExpDenom);
        % Remove extreme values at edges
        betaMu(betaMu > 0.99) = 0.99;
        betaMu(betaMu < 0.01) = 0.01;
        
        % Flip a,b parameters depending on where mean is
        leftInds = find(betaMu < 0.5);
        rightInds = find(betaMu >= 0.5);
        
        % We fix either a or b and modify the other. We need a default value for the one we dont solve for.
        % Larger values give us more degrees of freedom to adjust the beta shape
        % Should be >= 1
        abConst = obj.config.speed.type2abConst;
        
        a = zeros(obj.numberOfCells, 1);
        b = zeros(obj.numberOfCells, 1);
        % Mu < 1/2 --> a < b
        a(leftInds) = abConst .* betaMu(leftInds) ./ (1 - betaMu(leftInds));
        b(leftInds) = abConst;
        
        % Mu >= 1/2 --> a > b
        a(rightInds) = abConst;
        b(rightInds) = abConst.* ((1./betaMu(rightInds)) - 1);
        
        % Now will numberOfCells (a, b) pairs, sample variates from each distribution. These are bounded (0, 1).
        normSpeed = zeros(obj.numberOfCells, 1);
        for i = 1:obj.numberOfCells
          normSpeed(i) = betarnd(a(i), b(i));
        end
        
        % Scale the normalized values back to the valid speed range
        obj.cellPrefSpeed = normSpeed*range(spdSamples) + min(spdSamples);
        % speed pref is a function of the optic flow speed statistics
      elseif obj.config.speed.speedType == 4
        normCentDist = (sqrt(2)/2) * obj.cellCenterDist / mid;
        p = min(normCentDist, 0.999);
        obj.cellPrefSpeed = quantile(spdSamples, p);
      end
      
      % parametrized for performance during experiments
      if obj.config.speed.plotHist
        figure(11);
        clf;
        histogram(obj.cellPrefSpeed);
      end
      
    end
    
    function plotData(obj)
      clf;
      x = obj.cellX;
      y = obj.cellY;
      
      u = cosd(obj.cellPrefDirection) .* obj.cellResponse .* 100;
      v = sind(obj.cellPrefDirection) .* obj.cellResponse .* 100;
      quiver(x, y, u, v);
      
      hold on;
      
      xlim([-max(obj.cellRadius) obj.config.resolution + max(obj.cellRadius)]);
      ylim([-max(obj.cellRadius) obj.config.resolution + max(obj.cellRadius)]);
      
      % draw rectangle to clarify the bounds of the screen
      rectangle('Position',[0 0 obj.config.resolution obj.config.resolution], 'LineWidth', 2);
      
      for i = 1:obj.numberOfCells
        th = 0:pi/50:2*pi;
        
        xunit = obj.cellRadius(i) * cos(th) + x(i);
        yunit = obj.cellRadius(i) * sin(th) + y(i);
        plot(xunit, yunit);
      end
      hold off;
      drawnow;
    end
    
    function stimulus = calculate_step_vars (obj,frame, timestepsPerFrame)
      % DISTANCES
      distances = gaussian2D(frame(:,1) - obj.cellX', frame(:,2) - obj.cellY', obj.cellRadius');
      
      % DIRECTIONS
      dirDiff = atan2d(frame(:,4), frame(:,3)) - obj.cellPrefDirection';
      directions = gaussian(dirDiff, obj.config.directionSigma);
      
      % SPEEDS
      if ~obj.config.speed.speedType == 0
        % Compute actual image speed - cell preferred speed, then draw from Gaussian to get weighted response
        speedDiff = sqrt((frame(:,3) .^ 2) + (frame(:,4) .^ 2)) - obj.cellPrefSpeed';%%%%%%%%%%%%%%%%%%%%%%%%%%%
        speeds = gaussian(speedDiff, obj.config.speed.sigma);
        modifier = distances .* directions .* speeds;%%%%%%%%%%%%%%%%%%%%%%%%%%%
      else
        modifier = distances .* directions;%%%%%%%%%%%%%%%%%%%%%%%%%%%
      end
      
      % Compute MT cell netInput: Each cell averages across all N inputs
      stimulus = mean(modifier);%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    
    function step(obj, stimulus, timestepsPerFrame)
      % Compute MT cell responses (leaky integrator with shunting excitation) using Euler's Method.
      deltaResponse = -obj.config.decayRate .* obj.cellResponse + ...
        (obj.config.responseUpperBound - obj.cellResponse).*stimulus';
      obj.cellResponse = obj.cellResponse + (1/timestepsPerFrame) * deltaResponse;
      
      obj.cellResponse(obj.cellResponse > 1) = 1;
      
    end
  end
end

function radii = getRadii(dist2cent, baseRadius, distModifier, numCells, randVar)
  radii = baseRadius + distModifier*dist2cent + 2*randVar*(rand(numCells, 1) - .5);
  radii(radii < 1) = 1; % cap to 1
end

function fxy = gaussian2D(diffX, diffY, sigma)
  fxy = exp(-(diffX .^ 2 + diffY .^ 2) ./ (2*sigma.^2));
end

function fx = gaussian(diffX, sigma)
  fx = exp(-(diffX .^ 2) ./ (2*sigma.^2));
end
