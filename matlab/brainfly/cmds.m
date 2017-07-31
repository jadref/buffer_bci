z=jf_load('own_experiments/motor_imagery/cybathalon/imtest','S10','am_trn','170612/1330');
train_ersp_clsfr(z.X,z.Y,'capFile','cap_im_dense_subset.txt','overridechnms',0,'ch_names',z.di(1).vals,'fs',z.di(2).info.fs,'spatialfilter','car+wht','detrend',1,'freqband',[8 28],'objFn','mlr_cg','binsp',0,'spMx','1vR')
