function [hdr]=sendFakeHeader(host,port,varargin);
% send buffer a fake header so get_hdr returns
%
%   [hdr]=sendFakeHeader(host,port,varargin);
opts=struct('fsample',100,'nCh',1,'blockSize',5,'Cnames',[],'stimEventRate',100,'queueEventRate',500,'keyboardEvents',true,'verb',0);
opts=parseOpts(opts,varargin);
if ( nargin<1 ) host=[]; end;
if ( nargin<2 ) port=[]; end;

% build a set of channel names to use
if ( isempty(opts.Cnames) )
  opts.Cnames{1}='Cz';
  for i=2:opts.nCh; opts.Cnames{i}=sprintf('rand%02d',i); end;
end

hdr=struct('fsample',opts.fsample,'channel_names',{opts.Cnames},'nchans',opts.nCh,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,host,port);
