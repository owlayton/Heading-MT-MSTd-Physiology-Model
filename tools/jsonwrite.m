function result = jsonwrite(filename, data)
%JSONWRITE stores the given struct in filename in JSON
    fid=fopen(filename,'w');
    fprintf(fid, jsonencode(data, 'PrettyPrint', true));
    fclose(fid);
    result = true;
end

