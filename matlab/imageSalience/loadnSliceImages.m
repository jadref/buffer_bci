function [imageDB]=loadnSliceImages(imgDir)
files = dir(imgDir); % get all files
nTargets=1;
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
		  if (size(img,3)==1 ) img=repmat(img,[1 1 3]); end; % make RGB to enforce color display
		  [ans,imageDB(nTargets).name] = fileparts(filei.name);
		  imageDB(nTargets).image      = img;
		  % cut into pieces and store the bits
		  h=3; w=3; if ( size(img,2)>size(img,1)*1.5 ) w=4; end; % decide for 3x3 or 3x4 pieces
		  ys = round(linspace(1,size(img,1),h+1));
		  xs = round(linspace(1,size(img,2),w+1));
		  for i=1:w;
				for j=1:h;
					 imageDB(nTargets).pieces{j,i} = img(ys(j):ys(j+1),xs(i):xs(i+1),:);
					 % position rectangle in [L R W H] for this piece
					 imageDB(nTargets).pieceX{j,i} = xs(i):xs(i+1);
					 imageDB(nTargets).pieceY{j,i} = ys(j):ys(j+1);
				end
		  end
		  nTargets=nTargets+1;
	 end
end
