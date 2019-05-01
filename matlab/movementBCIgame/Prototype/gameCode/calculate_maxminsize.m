% Determine the maximum size of the circle.
function [maxsize, startsize] =calculate_maxminsize(max_range, start_range)
    maxnr=randi(length(max_range)); %pick a random number from the range above
    maxsize=max_range(maxnr); %calculate the max size
    startnr=randi(length(start_range));
    startsize=start_range(startnr);
end