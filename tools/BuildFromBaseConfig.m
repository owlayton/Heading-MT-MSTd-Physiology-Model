function finalConfig = BuildFromBaseConfig(base,addition)
%BUILDFROMBASECONFIG Creates a config using a base config and adding the
%"addition" config on top of it.

finalConfig = recursiveSolve(base, addition, {});

    function struct = recursiveSolve(struct, addition, access)
        
        fields = fieldnames(addition);
        for idx = 1:length(fields)
            field = addition.(fields{idx});
            currAccess = [access fields{idx}];
            
            if isstruct(field) && (isFieldNested(struct, currAccess) && isstruct(getfield(struct, currAccess{:})))
                struct = recursiveSolve(struct, field, currAccess);
            else
                x = getfield(addition,fields{idx});
                struct = setfield(struct, currAccess{:}, x);
            end
            
        end
        
    end

    function isNested = isFieldNested(struct, accessor)
        for i = 1:length(accessor)
            if isfield(struct, accessor{i})
                if i == length(accessor)
                    isNested = 1;
                else
                    struct = getfield(struct, accessor{i});
                end
            else
                isNested = 0;
                break;
            end
        end
    end

end

