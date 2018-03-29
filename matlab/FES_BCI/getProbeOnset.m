% Made by Ceci Verbaarschot
% eigen functie bouwen. kijk naar de mean en variance roep deze functie aan
% in experiment.
function [muProbe, sigmaProbe, probeOnset] = getProbeOnset(ats,sequenceNr,calcDistribution)

if (sequenceNr == 3 || sequenceNr == 6) % only for test blocks
    meanAT = median(ats); % get mean action time
    stdAT = std(ats); % get variance action time
end
    
if(calcDistribution)
    x = get_probe_distr(meanAT,stdAT);
    muProbe = x(1)
    sigmaProbe = x(2)
else
    muProbe = 7
    sigmaProbe = 2
end
probeOnset = normrnd(muProbe,sigmaProbe,1,1)





