function VisualizeOF(configName, resolution)
  %%VisualizeOF tool for visualizing one of the optic flow stimulus files
  % Usage:
  % >> VisualizeOF("paper1-4", 128);
  
  finalFileName = "optic_flow_generator/exports/" + configName + "-scene.mat";
  load(finalFileName, "simulatedScene");
  frames = simulatedScene.totalRenderedPoints;
  
  for frame_i = 1:size(frames,2)
    frame = frames{frame_i};
    quiver(frame(:,1), frame(:,2), frame(:,3) .* 10, frame(:,4) .* 10, 'AutoScale', 'off');
    hold on;
    plot(resolution/2, resolution/2,'x');
    axis([0 resolution 0 resolution])
    hold off;
    drawnow;
  end
  
end

