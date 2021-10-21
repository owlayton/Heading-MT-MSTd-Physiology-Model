function [result] = ResolveMultiConfig(ranges)
    % EXAMPLE INPUT :
    %ranges = {1:2, 3:5, 6:7, 8:10}; %cell array with N vectors to combine
	combinations = cell(1, numel(ranges)); %set up the varargout result
	[combinations{:}] = ndgrid(ranges{:});
	combinations = cellfun(@(x) x(:), combinations,'uniformoutput',false); %there may be a better way to do this
	result = transpose([combinations{:}]); % NumberOfCombinations by N matrix. Each row is unique.
end