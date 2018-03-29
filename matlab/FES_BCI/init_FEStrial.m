function init_FEStrial(FEStrialmsgh, msgh, si)
sendEvent('FES_trial', si);
set(msgh,'string',FEStrialmsgh,'visible','on');drawnow;

end