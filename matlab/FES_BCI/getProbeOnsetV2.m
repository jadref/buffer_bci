function [t_FES,muProbe, sigmaProbe, probeOnset] = getProbeOnsetV2(human_stats,calcDistribution)
meanAT = human_stats.mu; % get mean action time
stdAT = sqrt(human_stats.var); % get standard deviation action time
if(calcDistribution)
    x = get_probe_distr(meanAT,stdAT);
    muProbe = x(1)
    sigmaProbe = x(2)
end
probeOnset = normrnd(muProbe,sigmaProbe,1,1);

if probeOnset <= 3 
    probeOnset = 3;
elseif probeOnset >= 12 
    probeOnset = 12;
end
t_FES=probeOnset;








