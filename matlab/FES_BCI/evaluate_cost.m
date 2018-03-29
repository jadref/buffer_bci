function f = evaluate_cost(x,mu_action,sigma_action)
% Made by Ceci Verbaarschot
%
% Evaluate the 'goodness' of the current probe distribution.
% Input: x, where x(1) is the probe distribution mean and x(2) is the probe 
% distribution standard deviation.
% Output: total cost of this probe distribution.
%
% Requirements probe distribution:
% - Pr(probe-action == T) = 2/5 for T = [-inf,-2]
% - Pr(probe-action == T) = 2/5 for T = [-2,0]
% - Pr(probe-action == T) = 1/5 for T = [0,inf]
% - The standard deviation of the probe distribution is minimally 1.5 secs (so
% you have a minimum probe window of 3 secs wide)  

% Our requirements for the probe distribution are:
desired_fraction_probes_before_intention = 2/5;
desired_fraction_probes_after_action = 1/5;
min_sigma_probe = 1.5;

% Define the costs of not meeting the requirements:
C1 = 10^2; % cost fraction_probes_before_intention
C2 = 10^2; % cost fraction_probes_after_action
C3 = 10^2; % cost std_probe <= 1/5
C4 = 10^10; % cost negative std_probe

% find out the mu and sigma of the probe-action distribution:
mu_probe = x(1);
sigma_probe = x(2);
mu_delta = mu_probe - mu_action;
sigma_delta = sqrt((sigma_probe^2) + (sigma_action^2));

% how many probes are before the intention window and after action:
fraction_probes_before_intention = normcdf(-2,mu_delta,sigma_delta);
fraction_probes_after_action = normcdf(0,mu_delta,sigma_delta,'upper');

% calculate the total cost of this probe distribution
f = abs(fraction_probes_before_intention - desired_fraction_probes_before_intention)^2*C1 + ...
        abs(fraction_probes_after_action - desired_fraction_probes_after_action)^2*C2 + ...
        (x(2) < min_sigma_probe)^2*C3 + ...
        (x(2) < 0)*C4;   
end