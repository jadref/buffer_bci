function [imageDB] = loadImages(imgDir)
files = dir(imgDir);
nTargets = 1;
for fi=1:numel(files);
    filei = files(fi);
    if (filei.isdir) continue;
    else
        fprintf('Loading :%s...',filei.name);
        try
            img=imread(fullfile(imgDir,filei.name));
            fprintf('OK.\n',filei.name);
        catch
            fprintf('Failed!\n',filei.name);
            continue;
        end
        [ans,imageDB(nTargets).name] = fileparts(filei.name);
		imageDB(nTargets).image      = img;
        nTargets=nTargets+1;
    end
end
        