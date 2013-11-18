function [texels,srcRects,destRects]=mkTextureGrid(wPtr,symbs,varargin)
% convert a set of strings to a set of textures layed out on a grid
%
%  [texels,srcRects,destRects]=mkTextGrid(wPtr,symbs,varargin)
%
% N.B. to see the result use: 
%    Screen('Drawtextures',wPtr,texels,srcRects,destRects); Screen('flip',wPtr')
%
% Inputs:
%  wPtr - [int] window pointer
%  symbs - {str w x h} set of strings to display on a grid of size w x h
% Options:
%  viewPort  -- [4 x 1] LeTteRBox describing the region position on the screen
%  width_chr -- [int] max characters across before wrapping ([automatically found])
%  TextSize  -- [int] 
%  TextColor -- [3 x 1] or [4 x 1] forground color for text
%  tstStr    -- [str] test string for getting character dimensions ('Hgpq!_^')
% Outputs:
%  texels - [int numel(symbs) x 1] set of handles to the created textures
%  srcRects - [4 x numel(symbs)] source positions of the strings in the texture
%  destRects- [4 x numel(symbs)] position of the strings on the screen for grid layout
opts=struct('width_chr',[],'TextSize',32,'bgCol',0,'TextColor',[255 255 255],...
            'tstStr','Hgpq|_^','viewPort',[0 0 1 1],'AlphaBlend',1,'fullScreen',0);
opts=parseOpts(opts,varargin);
% get screen parameters
[width, height]=Screen('WindowSize', wPtr);
viewPort=opts.viewPort;
if ( isempty(viewPort) ) viewPort=[0 0 1 1]; end;
if ( all(viewPort<=1) && all(viewPort>=0) ) viewPort=viewPort.*[width height width height]; end;
if ( isempty(symbs) ) texels=[];srcRects=[];destRects=[]; return; end;
if ( ~iscell(symbs) ) symbs={symbs}; end;

% setup the display font
Screen('TextSize',wPtr,opts.TextSize); 
Screen('TextColor',wPtr,opts.TextColor);
Screen('TextStyle', wPtr,1);
Screen('TextFont', wPtr,'Helvetica');


% get info on the text size, fixs bug in bounding box computation which
% means the heights don't include descenders
[charwh]=Screen('TextBounds',wPtr,opts.tstStr,0,0); 
charwh=[round(charwh(3)./numel(opts.tstStr)) charwh(4)];
% Compute the max display cell size
width_chr=opts.width_chr;
if ( isempty(width_chr) )
   wh_chr = [floor(viewPort(3)./charwh(1)) floor(viewPort(4)./charwh(2))];
   width_chr = floor(wh_chr(1)./size(symbs,2));
end
   
% convert strings to textures
si=1;
Screen('FillRect',wPtr,opts.bgCol); 
for si=1:numel(symbs);
   % draw the symbol and get its bounding box
   if( isstr(symbs{si}) ) % convert the string to an image + bbox
      [ans,ans,srcRects(:,si)]=DrawFormattedText(wPtr,symbs{si},'center',0,opts.TextColor,width_chr);
      srcRects(4,si)=ceil(srcRects(4,si)./charwh(2))*charwh(2);
      texel=Screen('GetImage',wPtr,srcRects(:,si),'backBuffer');%extract image, back buffer
      % set the alpha map
      if(opts.AlphaBlend)  end;
      srcRects([1,3],si)=srcRects([1,3],si)-srcRects(1,si);  % set L edge to 0
   elseif( isnumeric(symbs{si}) ) % is an image to show
      texel=symbs{si}; 
      srcRects(:,si)=[0 0 size(symbs{si},2) size(symbs{si},1)];
   end
   if( opts.AlphaBlend && ( size(texel,3)==3 || size(texel,3)==1 ) )      
      texel=cat(3,texel,max(texel,[],3));%*255./(ndims(texel)*255));
   end
   texels(si)    = Screen('MakeTexture',wPtr,texel);  % make texture
   Screen('FillRect',wPtr,opts.bgCol); % blank background
end

% compute where to put the symbols on the screen
destRects=srcRects;
symwh=[max(srcRects(3,:)) max(srcRects(4,:))]; % largest symbol width and height
if ( size(symbs,2)==1 ) xs=mean(viewPort([1 3]));
else                    
   xs=linspace(viewPort(1),viewPort(3),size(symbs,2)+1); xs=(xs(1:end-1)+xs(2:end))/2; 
end
if ( size(symbs,1)==1 ) ys=mean(viewPort([2 4]));
else                    
   ys=linspace(viewPort(2),viewPort(4),size(symbs,1)+1); ys=(ys(1:end-1)+ys(2:end))/2; 
end
[xs ys]=meshgrid(xs,ys);
destRects(1,:)=xs(:)-srcRects(3,:)'/2; % center in the range
destRects(2,:)=ys(:)-srcRects(4,:)'/2; 
destRects(3,:)=destRects(1,:)+srcRects(3,:); destRects(4,:)=destRects(2,:)+srcRects(4,:);
if ( opts.fullScreen ) destRects=repmat(opts.viewPort(:),1,numel(texels)); end;
return;

%------------------------------------------------------------
function testCase();
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1)
Screen('Preference', 'VBLTimestampingMode', 0)
screenNumber=max(Screen('Screens'));
wPtr=Screen('OpenWindow',screenNumber,0,[1024 0 1024+512 0+512]);

% text tst
symbs={'hello' 'there' 'is' 'anybody' 'there?'}';
[texels,srcRects,destRects]=mkTextGrid(wPtr,symbs);
Screen('Drawtextures',wPtr,texels,srcRects,destRects); Screen('flip',wPtr')

% image test
im=imread('theif.jpg');
symbs={'hello' 'you'
       'theif' im};
[texels,srcRects,destRects]=mkTextGrid(wPtr,symbs);
Screen('Drawtextures',wPtr,texels,srcRects,destRects); Screen('flip',wPtr')

