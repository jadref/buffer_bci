% 1: test the classifier training and application
load('testTrnERSPData');

% test binary
[clsfr,res,X,Y]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',1,'badtrrm',1,'capFile',capFile,'overridechnms',overridechnms,'visualize',1);

% test 3-class
% ERsP
[clsfr,res,X,Y]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',1,'badtrrm',1,'capFile',capFile,'overridechnms',overridechnms,'visualize',1);
% test apply method
[clsfr,res,Xtrn]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',1,'badtrrm',0,'capFile',capFile,'overridechnms',overridechnms,'visualize',0);
[f,fraw,p,Xapp]=apply_ersp_clsfr(cat(3,traindata.buf),clsfr);
mad(Xtrn,Xapp)
mad(res.opt.f,fraw) % N.B. use fraw so don't do multi-class decoding
% ERP
[clsfr,res,Xtrn,Y]=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',1,'badtrrm',0,'capFile',capFile,'overridechnms',overridechnms,'visualize',1);
% test apply method
[f,fraw,Xapp]=apply_erp_clsfr(cat(3,traindata.buf),clsfr);
mad(Xtrn,Xapp)
mad(res.opt.f,fraw)

% test strings for values
for ei=1:numel(traindevents); traindevents(ei).value = sprintf('%d',traindevents(ei).value); end;
% ERsP
[clsfr,res]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',1,'badtrrm',1,'capFile',capFile,'overridechnms',overridechnms,'visualize',1);
% ERP
[clsfr,res]=buffer_train_erp_clsfr(traindata,traindevents,hdr,'spatialfilter','slap','freqband',[6 10 26 30],'badchrm',1,'badtrrm',1,'capFile',capFile,'overridechnms',overridechnms,'visualize',1);
