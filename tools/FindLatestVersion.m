function [latestVersion] = FindLatestVersion(filename, extension)
%FINDLATESTVERSION finds the latest version number ("0xx") from a filename
%by trying filenames until it cant find one

        basefilename = filename + "-";
        fileindex = 0;
        filename = basefilename + sprintf('%03d',fileindex) + extension;
        while isfile(filename)
            fileindex = fileindex + 1;
            filename = basefilename + sprintf('%03d',fileindex) + extension;
        end
        
        latestVersion = fileindex-1; % minus one because we want the latest
end

