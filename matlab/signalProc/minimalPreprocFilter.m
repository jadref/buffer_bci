function [x,state]=minimalPreprocFilter(x,state,varargin)  
% filter functio to apply minimil (band-pass,car,subsample) pre-processing to raw input data.
%
% Options:
%  bands - [2x1] pass band for spectral filter
%  chSeln - [size(x,1),1] subset of channels to keep
%  spatialFitler - 'str', spatial filter to apply
%  subsample - [1x1] desired output sample rate.  N.B. closest integer re-sample used!
  
                                % setup the state from the options
if( isempty(state) ) 
  state=initState(x,varargin);
end
issingle=isa(x,'single');

if ( ~isempty(state.biasfilt) ) % pre-high-pas with FIR
   [x,state.biasfiltstate]=filter(state.biasfilt,1,x,state.biasfiltstate,2);
end


                                % spectral-filter
if( ~isempty(state.B) )
   % use double for internal filter processing, IIR filter is very very sensitive to precision used...
  if(issingle)   x=double(x); end;
  [x,state.spectfiltstate]=filter(state.B,state.A,x,state.spectfiltstate,2);
  if( issingle ) x=single(x); end;
elseif( ~isempty(state.sos) )
   % apply the sos filter cascade
   if(issingle)   x=double(x); end;
   for li=1:size(state.sos,1); % apply the filter cascade
      [x,state.spectfiltstate(:,:,li)]=filter(state.sos(li,1:3),state.sos(li,4:6),x,state.spectfiltstate(:,:,li),2);       
   end
   if( issingle ) x=single(x); end;
end
                                % downsample
if( ~isempty(state.subsampleStep) ) % averaging downsampler, to reduce aliasing effects
  nsubsamp = floor(size(x,2)/state.subsampleStep);
  if( nsubsamp*state.subsampleStep < size(x,2) ) % need to pad
     x = cat(2,x,repmat(x(:,end,:),[1,(nsubsamp+1)*state.subsampleStep-size(x,2),1]));
  end;
  x = mean(reshape(x,[size(x,1),state.subsampleStep,nsubsamp,size(x,3)]),2); % average samples
  x = reshape(x,[size(x,1),size(x,3),size(x,4)]); % remove averaged dim
end
                                % spatial-filter
if( ~isempty(state.R) )
  if( isnumeric(state.R) )
     x = state.R*reshape(x,size(x,1),[]);
  elseif( strcmpi(state.R,'robust') ) % median CAR
     mu = median(x,1);
     x  = x - repmat(mu,[size(x,1),1]);
  end
end
                                % channel selection
if( ~isempty(state.chseln) )
   x=x(state.chseln,:,:);
end
                                % artifact removal
if( ~isempty(state.artfiltstate) )
   ox=x;
   [x,state.artfiltstate]=artChRegress(x,state.artfiltstate);
   %mad(ox,x)
end
                                % downsample
if( 0 && ~isempty(state.subsampleStep) ) % averaging downsampler, to reduce aliasing effects
  nsubsamp = floor(size(x,2)/state.subsampleStep);
  if( nsubsamp*state.subsampleStep < size(x,2) ) % need to pad
     x = cat(2,x,repmat(x(:,end,:),[1,(nsubsamp+1)*state.subsampleStep-size(x,2),1]));
  end;
  x = mean(reshape(x,[size(x,1),state.subsampleStep,nsubsamp,size(x,3)]),2); % average samples
  x = reshape(x,[size(x,1),size(x,3),size(x,4)]); % remove averaged dim
end


return


function [state]=initState(x,varargin)
  % parse the configuration options and initialize the filter state
  state=struct('chseln',[],'R',[],'artfiltstate',[],'B',[],'A',[],'sos',[],'spectfiltstate',[],'biasfilt',[],'biasfiltstate',[],'subsampleStep',[],'hdr',[]);
                                % argument processing
  opts=struct('chseln',[],'capFile',[],'overridechnms',0,'spatialFilter',[],'artifactCh',[],'subsample',[],'bands',[],'spectfilttype',[],'spectfiltorder',[],'biasfilt',[],...
              'hdr',[],'fs',[],'ch_names','','ch_pos',[],'verb',0);
  opts=parseOpts(opts,varargin);

                                % parameter setup
  hdr=opts.hdr;
  fs=opts.fs;
  if(isempty(fs) && ~isempty(opts.hdr) )
     if(isfield(opts.hdr,'fSample')) fs=opts.hdr.fSample;
     elseif(isfield(opts.hdr,'Fs'))  fs=opts.hdr.Fs;
     end;
  end
  ch_names=opts.ch_names; if( isempty(ch_names) && ~isempty(opts.hdr) ) ch_names=opts.hdr.label; end;
  iseeg=[]; 
  if( ~isempty(opts.capFile) ) % additionally only pick channels which match capfile names     
     di = addPosInfo(ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
     ch_names(1:numel(di.vals)) = di.vals; % update channel names
     iseeg=[di.extra.iseeg];
  end
  issingle=isa(x,'single');

  % bias-remove
  if( ~isempty(opts.biasfilt) )
     len = opts.biasfilt*fs;
     state.biasfilt = -ones(len+1,1)./len; state.biasfilt(1)=1;
     state.biasfiltstate=[];
  end


                                % spatial filter
  if( ~isempty(opts.spatialFilter) )
    R=[];
                                % make the fixed spatial filter matrix
    if( any(strcmpi(opts.spatialFilter,{'robust','robustcar'})) )
      fprintf('Robust-CAR\n');
       R = 'robust';
    elseif(strcmpi(opts.spatialFilter,'car')) % common-average
      fprintf('CAR\n');
      wght=zeros(size(x,1),1); if(~isempty(iseeg)) wght(iseeg)=1; else wght(:)=1; end;
      R = eye(size(x,1)) - repmat(wght'./sum(wght),[size(x,1) 1]);
    elseif( iscell(opts.spatialFilter) ) % list channel names to use for reference
      wght=zeros(size(x,1),1); 
      for ci=1:numel(ch_names);
        if( any(strcmpi(ch_names{ci},opts.spatialFilter)) )
          fprintf('SpatialFilter: Matched %s\n',ch_names{ci});
          wght(ci)=true;          
        end;
      end
      R = eye(size(x,1)) - repmat(wght'./sum(wght),[size(x,1) 1]);
    elseif( isnumeric(opts.spatialFilter) )
      if ( size(opts.spatialFilter,2)==1 ) % set channel numbers to use as average reference
        wght=zeros(size(x,1),1); wght(opts.spatialFilter)=1;
        fprintf('SpatialFilter: Matched %s\n',sprintf('%s ',ch_names{wght>0}));
        % WARNING: watch the transpose.....
        R= eye(size(x,1)) - repmat(wght'./sum(wght),[size(x,1) 1]);
      elseif( size(opts.spatialfilter,2)==size(x,1) )
        R= opts.spatialfilter;
      else
        warning('dont understand spatial filter ');
      end
    else
      warning('spatial filter type not supported yet');
    end
    state.R=R;
    % apply
    if( isnumeric(state.R) )
       x = state.R*reshape(x,size(x,1),[]);
    elseif( strcmpi(state.R,'robust') ) % median CAR
       mu = median(x,1);
       x  = x - repmat(mu,[size(x,1),1]);
    end    
  end

                                % channel selection
  chseln=opts.chseln;
  if( ~isempty(chseln) )
     if ( isnumeric(chseln) && any(chseln>1) ) % get logical indicator of keeping channels
        tmp=chseln; chseln=false(size(x,1),1); chseln(tmp)=true; 
     elseif( iscell(chseln) )
        tmp=chseln; chseln=false(size(x,1),1); 
        for ci=1:numel(ch_names);
           if( any(strcmpi(ch_names{ci},tmp)) ) 
              chseln(ci)=true; 
           end;
        end
     elseif( strcmp(chseln,'eegonly') && ~isempty(iseeg) && any(iseeg) )
        chseln = false(size(x,1),1); 
        chseln(iseeg)=true;
     end
  end; 
  state.chseln=chseln;
  if( ~isempty(state.chseln) ) % apply the selection
     fprintf('ChannelSeln:'); fprintf('%s,',ch_names{chseln});fprintf('\n');
     x=x(state.chseln,:,:);
  end

  
                                % spectral fitler
  if( ~isempty(opts.bands) )
    bands=opts.bands;
    type =opts.spectfilttype;
    Rp=1; % max pass-band attenuation in db (1 = ~75%max)
    Rs=30;% min stop-band attenuation in db (30= ~.01%max)
    if( 1 ) 
%     if( bands(1)==0 )      type='low';  bands=bands(2);  fprintf('low-pass %gHz\n',bands); % low-pass
%     elseif( bands(2)>=fs ) type='high'; bands=bands(1);  fprintf('high-pass %gHz\n',bands);% high-pass
%     else                                                 fprintf('band-pass [%g-%g]Hz\n',bands);
%     end       
    

%     if( isempty(type) )    [B,A]=butter(4,bands*2/fs); % arg, weird bug in octave for pass
%     else                   [B,A]=butter(4,bands*2/fs,type);
%     end
%     state.B=B;
%     state.A=A;
%     % estimate an initial filter state to reduce startup artifacts
%     % From: Likhterov & Kopeika, 2003. "Hardware-efficient technique for
%             minimizing startup transients in Direct Form II digital filters"
%     kdc = sum(state.B) / sum(state.A);
%     if (abs(kdc) < inf) # neither NAN nor +/- Inf
%       si = fliplr(cumsum(fliplr(state.B - kdc * state.A)));
%     else
%       si = zeros(size(state.A)); # fall back to zero initialization
%     endif
%     si(1) = [];
%     state.spectfiltstate= si(:)*x(:,1);
%     % apply
%     if( issingle ) x=double(x); end;
%     N.B. don't update the state, as will re-run this data later...
%     x = filter(state.B,state.A,x,state.spectfiltstate,2);
%     if( issingle ) x=single(x); end;    


    % get the filter parametres we need
    Rp=1; % max pass-band attenuation in db (1 = ~75%max)
    Rs=30;% min stop-band attenuation in db (30= ~.01%max)
    ord=opts.spectfiltorder;
    if( bands(3)>=fs ) % high-pass
      if( isempty(ord) )
        [ord,wN]=buttord(bands(2)*2/fs,bands(1)*2/fs,Rp,Rs); % auto-order est
      else
        wN=bands(2)*2/fs;
      end
      type='high';  fprintf('%d order high-pass [%g-inf]Hz\n',ord,bands(2)); % high-pass
    elseif( bands(2)==0 ) % low-pass
      if( isempty(ord) )
        [ord,wN]=buttord(bands(3)*2/fs,bands(4)*2/fs,Rp,Rs);
      else
        wN=bands(3)*2/fs;
      end
      type='low';   fprintf('%d order low-pass [0-%g]Hz\n',ord,bands(3)); % low-pass
    else % pass band
      if( isempty(ord) ) 
        [ord,wN]=buttord(bands([2 3])*2/fs,bands([1 4])*2/fs,Rp,Rs); 
      else
        wN=bands(2:3)*2/fs;
      end      
      type=[];  fprintf('%d order bandpass [%g-%g]Hz\n',ord,bands(2:3)); % low-pass
    end
    % get the filter coefficients
    if( ~isempty(type) ) 
       [z,p,k]=butter(ord,wN,type); %low/high
    else
       [z,p,k]=butter(ord,wN); % pass
    end        
    state.sos = zp2sos(z,p,k); % convert to second-order-section, i.e. cascade of 2nd-order filters, representation
    % estimate the filter properties    
    %N=2024; Fs=256; mf=1; [G,Wn]=freqz(sos,N,Fs); [D]=grpdelay(sos,N,Fs); [Wn(Wn<mf), abs(G(Wn<mf)), D(Wn<mf)]

    % pre-warm the filter, by applying to time-reversed data.
    if( issingle ) x=double(x); end;
    ox=x;
    tmp=x(:,end:-1:1); % warm-up on time-reversed signal..
    [tmp,spectfiltstate]=filter(state.sos(1,1:3),state.sos(1,4:6),tmp,[],2);
    spectfiltstate=repmat(spectfiltstate,[1 1 size(state.sos,1)]);
    for li=2:size(state.sos,1); % apply the filter cascade
       [tmp,spectfiltstate(:,:,li)]=filter(state.sos(li,1:3),state.sos(li,4:6),tmp,[],2);
    end
    state.spectfiltstate=spectfiltstate;
    clear tmp

    % apply the pre-warmed sos filter cascade
    for li=1:size(state.sos,1); % apply the filter cascade
      % N.B. DONT update state as will re-do this filtering later...
       x=filter(state.sos(li,1:3),state.sos(li,4:6),x,state.spectfiltstate(:,:,li),2);       
    end
    if( issingle ) x=single(x); end;    
    end
    if( 0 ) % FIR filter
       error('Not implemented yet!');
       if( bands(3)>=fs ) % high-pass
          [ord,wN]=firpmord(bands(2)*2/fs,bands(1)*2/fs,Rp,Rs);     type='high';  fprintf('%d order high-pass [%g-inf]Hz\n',ord,bands(2)); % high-pass
       elseif( bands(2)==0 ) % low-pass
          [ord,wN]=firpmord(bands(3)*2/fs,bands(4)*2/fs,Rp,Rs);     type='low';   fprintf('%d order low-pass [0-%g]Hz\n',ord,bands(3)); % low-pass
       else % pass band
          [ord,wN]=firpmord(bands([2 3])*2/fs,bands([1 4])*2/fs,Rp,Rs); type=[];      fprintf('%d order bandpass [%g-%g]Hz\n',ord,bands(2:3)); % low-pass
       end       
    end
  end
                                  % re-sample
  ofs=fs;
  if( ~isempty(opts.subsample) )
    subsampleratio = ceil(fs/opts.subsample);    
    if( subsampleratio>1 ) % only if needed
       ofs=fs/subsampleratio;
       fprintf('Subsampling: %g -> %g hz\n',fs,ofs);
       state.subsampleStep = subsampleratio;
    end
  end

  % eog removal
  if( ~isempty(opts.artifactCh) ) 
     % N.B. needs to be fast enough to respond to transient artifacts, like eye-blinks...
     artHalfLife_s = .5; 
     artHalfLife_samp = artHalfLife_s* ofs; 
     artBands      = [.1 30];%[.2 inf];
     % initialize and apply
     [x,artfiltstate]=artChRegress(x,[],[1 2 3],opts.artifactCh,'ch_names',ch_names,'fs',ofs,'bands',artBands,'center',0,'covFilt',artHalfLife_samp);
     state.artfiltstate = artfiltstate;
  end
  

  % update the hdr info
  if(isempty(hdr)) hdr=struct('fs',ofs,'label',ch_names,'iseeg',iseeg);
  else 
     hdr.fs=ofs; 
     if(isfield(opts.hdr,'fSample')) fs=opts.hdr.fSample;
     elseif(isfield(opts.hdr,'Fs'))  fs=opts.hdr.Fs;
     end;
     hdr.label=ch_names;
  end
  state.hdr=hdr;
