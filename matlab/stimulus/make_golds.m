function all_code=make_golds(n, bitpattern1, bitpattern2, bitshift)
% Inputs:
%   n - number of bits of internal state
%   bitpattern1, bittpattern2 -- two bit patterns to combine to make the final code
%   shift - set of shifts of code 2 to combine with code1 to make the output code

if ( nargin<4 || isempty(bitshift) ) bitshift=(1:2^n-1)'; end;
all_code=[];

code1=pseudo_random_ruisgenerator(n, bitpattern1);
code2=pseudo_random_ruisgenerator(n, bitpattern2);
all_code=zeros(numel(code2),numel(bitshift));
for si=1:numel(bitshift);
    all_code(:,si)=mod(code1+circshift(code2,bitshift(si)),2);
end
return

function result = pseudo_random_ruisgenerator(n, bitpattern)
% Inputs:
%   n          - number of bits in the internal state
%   bitpattern - set of taps to use in the noise generator
state=zeros(n,1);
state(1)=1;
result=zeros(2^n-1,1);
for i=1:2^n-1
    result(i)=state(n);
    inputs=state(bitpattern);
    output= mod(sum(inputs),2); 
    state=circshift(state,1);
    state(1)=output;
end


