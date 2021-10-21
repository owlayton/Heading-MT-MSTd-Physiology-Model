function [independentVariables] = FindIndependentVariablesFromConfig(configuration, fieldToLookFor)
%FindIndependentVariablesFromConfig

if ~exist("fieldToLookFor","var")
    fieldToLookFor = "isIndependentVariable";
end

independentVariables = recursiveSolve(configuration, {}, []);

    function independents = recursiveSolve(struct, access, independents)
        
        fields = fieldnames(struct);
        for idx = 1:length(fields)
            field = struct.(fields{idx});
            if isstruct(field)
                if isfield(field, fieldToLookFor)
                    independentVariableParams = field.independentVariableParams;
                    
                    accessorToUse = access;
                    accessorToUse{end+1} = fields{idx};
                    
                    independentVariableParams.independentVariableAccessor = accessorToUse;
                    if isfield(field, "plotting")
                        independentVariableParams.plotting = field.plotting;
                    end
                    independents{end+1} = independentVariableParams;
                    
                else
                    independents = recursiveSolve(field, [access fields{idx}], independents);
                end
            end
        end
    end


end