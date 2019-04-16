function filtstate=warmupFilter(A,B,X,dim)
  % pre-warm the filter on time-reversed data
  if( nargin<4 ) dim=2; end;
  if( dim >3  ) error('Only for dim<3 for now'); end;

  % extract 100 samples of time-reversed + sign reversed data
  % make [ t x d ]
  if( dim==1 )        tmp=2*X(1,:,1)-X(min(end,500):-1:1,:,1); 
  elseif ( dim==2 )   tmp=2*X(:,1,1)-X(:,min(end,500):-1:1,1); tmp=tmp';
  end

  if( isa(X,'single') )  tmp=double(tmp); end;

  if( isempty(B) || size(A,1)>1 ) % SOS
    tmpbwd = tmp; % for odd-passes through the warmup data
    tmpfwd = tmp(end:-1:1,:);  % for even-passes through the warmup
     % apply with this to the data to get improved init-state
    filtstate=zeros([2,size(tmp,2),size(A,1)]); % [ ord-1 x d x #filt]
    % TODO: [] this is a long expensive warmup
    % do 5 passes through the data, N.B. ODD so final pass is BWD-pass
    res=[]; d=inf;
    for pass=1:ceil(100000/size(tmp,1)); 
      if( mod(pass,2)==0 ) tmp = tmpfwd; else tmp=tmpbwd; end;
      for li=1:size(A,1); % apply the filter cascade
             % N.B. lkwarmup causes problems if use to pre-warm later parts..
        if( pass==1 ) % pre-warmup
          filtstate(:,:,li)=lkwarmup(A(li,1:3),A(li,4:6),tmp,1);
        end
        [tmp,filtstate(:,:,li)]=filter(A(li,1:3),A(li,4:6),tmp,filtstate(:,:,li),1);
      end
      if( ~isempty(res) ) 
        od=d; d=sum(tmp(:)).^2; % norm filtered data
        fprintf('filterWarmup::pass %d dfX = %g\n',pass,d);
        if( abs(d-od)/od < .001 ) break; end;
      end
      res=tmp;
    end
  else % normal filter warmup
    prestate=lkwarmup(A,B,tmp,1);
    [tmp,filtstate]=filter(B,A,tmp,prestate,1);
  end  
  return;
%--------------
function testCase();
  X=ones(10000,1);
  A=[1,-2,1];
  B=[1,-1.98753,.98757];
  [fX,fs]=filter(B,A,X);
  is=warmupFilter(A,B,X);
  [ifX,ifs]=filter(B,A,X,is);

