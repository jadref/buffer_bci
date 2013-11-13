function [hdr]=sendFakeHeader(host,port,varargin);
% send buffer a fake header so get_hdr returns
%
%   [hdr]=sendFakeHeader(host,port,varargin);
opts=struct('fsample',100,'nCh',1,'blockSize',5,'Cnames',[],'stimEventRate',100,'queueEventRate',500,'keyboardEvents',true,'verb',0);
opts=parseOpts(opts,varargin);
if ( isempty(opts.Cnames) )
  opts.Cnames{1}='Cz';
  for i=2:opts.nCh; opts.Cnames{i}=sprintf('rand%02d',i); end;
end

global ft_buff;
if ( nargin<2 || isempty(port) ) 
  if ( ~isempty(ft_buff) ) port=ft_buff.port ; else port=1972; end;
end;
if ( nargin<1 || isempty(host) ) 
  if ( ~isempty(ft_buff) ) host=ft_buff.host ; else host='localhost'; end; 
end;


hdr=struct('fsample',opts.fsample,'channel_names',{opts.Cnames},'nchans',opts.nCh,'nsamples',0,'nsamplespre',0,'ntrials',1,'nevents',0,'data_type',10);
buffer('put_hdr',hdr,host,port);
