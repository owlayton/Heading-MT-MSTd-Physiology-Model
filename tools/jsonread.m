function result = jsonread(filename)
%JSONREAD reads the given json file and returns the corresponding struct
    result = jsondecode(fileread(filename));
end

