% Made by Ceci Verbaarschot
%
% Find a probe distribution for the Matsuhashi experiment with the
% following requirements:
% - Pr(probe-action == T) = 2/5 for T = [-inf,-2]
% - Pr(probe-action == T) = 2/5 for T = [-2,0]
% - Pr(probe-action == T) = 1/5 for T = [0,inf]
% - the standard deviation of the probe distribution is minimally 1.5 secs (so
% you have a minimum probe window of 3 secs wide)

function x = get_probe_distr(mu_action,sigma_action)
    x0 = [5, 1.5]; % expected probe distribution mean (x(1)) and standard deviation (x(2))
    myFunwrapper = @(x) evaluate_cost(x,mu_action,sigma_action);
    
    [x,fval] = fminunc(myFunwrapper,x0); % find the nearest to optimal probe distribution
end




