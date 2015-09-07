function [stimSeq,stimTime,eventSeq,colors]=mkStimSeqNoise(nSymbs,duration,isi,type)
% make a stimulus sequence / stimTim pair for a set of nSymbols
%
% [stimSeq,stimTime,eventSeq,colors]=mkStimSeqRand(nSymbs,duration,isi,type)
%
%  The stimSeq generated has the property that each symbols are are not flashed 
%  within mintti flashes of each other
%
% Inputs:
%  nSymbs -- [int] number of symbols to make the sequence for
%  duration  -- [int] duration of the stimulus in seconds
%  isi    -- [float] inter-stimulus interval in seconds                (1)
%  type   -- [str] type of noise code to make.                         ('gold')
%                  One of: 'gold','gaus'  
%  smooth -- [bool] continuous valued output                           (false)
% Outputs:
%  stimSeq  -- [bool nSymbs x nStim] logical matrix with true indicating that this symbol 
%                       should flashed at this time
%  stimTime -- [1 x nStim] time in seconds each stimulus event should take place
%  eventSeq -- {1 x nStim} cell array containing {2x1} event info which should be sent at each stimulus time.
%                   Each entry is either empty (i.e. {}) indicating no event to be sent or
%                   {type value} a cell array with the event type and value to send
if ( numel(nSymbs)>1 ) nSymbs=numel(nSymbs); end;
if ( nargin<3 || isempty(isi) ) isi=1; end;
if ( nargin<4 || isempty(type) ) type='gold'; end;
if ( nargin<5 || isempty(smooth) ) smooth=false; end;
colors=[1 1 1]';
nStim = duration/isi;
stimTime=(1:nStim)*isi(1);
eventSeq=[];

stimSeq=zeros(nSymbs,nStim); 
switch lower(type);
  case 'gold'; 
	 nBits = max(8,ceil(log2(nStim+1))); % state long enough to not repeat in nStim events
	 if ( nBits==8 ) bitpattern1=[8,7,6,5,2,1]; bitpattern2=[8,7,6,1]; % magic, special code
	 else % randomly pick the set of taps
			% N.B. this will generate sub-optimal bit sequences
		bitpattern1=find(rand(nBits,1)>.5); 
		bitpattern2=makeTaps(nBits); if( isempty(bitpattern2) ) bitpattern2=find(rand(nBits,1)>.5); end;
	 end;
	 stimSeq = make_golds(nBits, bitpattern1, bitpattern2, 0:nSymbs-1);	 
	 % set correct size etc
	 if ( 2*nSymbs+nStim<size(stimSeq,1) ) % shift away the warmup phase
		stimSeq = stimSeq(2*nSymbs+(1:nStim),1:nSymbs)'; 
	 else % use it all as normal
		stimSeq = stimSeq(1:nStim,1:nSymbs)'; 
	 end
  case 'gaus'; 
	 stimSeq = randn(size(stimSeq));
	 if ( ~smooth ) stimSeq=single(stimSeq>0); end;
otherwise ; error('Unrecognised noise type');
end
return;

%----------------------

function all_code=make_golds(n, bitpattern1, bitpattern2, shift)
% Inputs:
%   n - number of bits of internal state
%   bitpattern1, bittpattern2 -- two bit patterns to combine to make the final code
%   shift - set of shifts of code 2 to combine with code1 to make the output code
code1=pseudo_random_ruisgenerator(n, bitpattern1);
code2=pseudo_random_ruisgenerator(n, bitpattern2);
all_code=zeros(numel(code2),numel(shift));
for si=1:numel(shift); 
  all_code(:,si)=mod(code1+circshift(code2,shift(si)),2); 
end
return;

function result = pseudo_random_ruisgenerator(n, bitpattern)
% Inputs:
%   n          - number of bits in the internal state
%   bitpattern - set of taps to use in the noise generator
state=zeros(n,1);
state(1)=1;
result=zeros(2^n-1,1);
for i=1:2^n-1
    result(i)= state(n); % high order bit is the output
    inputs   = state(bitpattern);
    output   = mod (sum(inputs),2); 
    state    = circshift(state,1);
    state(1) = output;
end
return;

function [taps]=makeTaps(nbits)
  taps=[];
  switch (nbits);
	 case 4; taps=[4 3];
	 case 5; taps=[5 3];
	 case 6; taps=[6 5];
	 case 7; taps=[7 6];
	 case 8; taps=[8 6 5 4];
	 case 9; taps=[9 5];
	 case 10; taps=[10 7];
	 case 11; taps=[11 9];
	 case 12; taps=[12 11 10 4];
	 case 13; taps=[13 12 11 8];
	 case 14; taps=[14 13 12 2];
	 case 15; taps=[15 14];
	 case 16; taps=[16 14 13 11];
	 case 17; taps=[17 14];
	 case 18; taps=[18 11];
	 case 19; taps=[19 18 17 14];
	 case 31; taps=[31 28];
	 case 32; taps=[32 31 29 1];
	 otherwise; fprintf('Dont know taps for this bit width');
  end
return;



%----------------------
function testCase();
% binary
[stimSeq,stimTime]=mkStimSeqNoise(10,10,1/20,'gold');
% continuous
clf;mcplot(stimTime(1:size(stimSeq,2)),stimSeq,'lineWidth',1)
clf;playStimSeq(stimSeq,stimTime)
