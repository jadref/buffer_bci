expt='~/output';
subjects={'RacingGame'};
sessions={{'17080' '17099' '17660' '17719' '17879' '17932' '18002' '18664' '19080' '21668' '22010' '22705' '22884' '22999' '23040' '23119' '23158' '23198' '23241' '23565' '23603' '23649' '23689' '23740' '23787'}};
blocks={{''}};
dtype='';
fileregexp='header$';
label='braintst';

si=1;
sessi=numel(sessions{si});
blki=1;
subj=subjects{si};
block=blocks{si}{blki};
session=sessions{si}{sessi};

filelst=findFiles(expt,subj,session,block,'dtype',dtype,'fileregexp',fileregexp);

z = raw2jf({filelst.fname},...
           'blocks',[filelst.block],'sessions',{filelst.session},...
           'expt',expt,'subj',subj,...
           'label',label,'startSet',{{'timestamp' 'stimulus'} []},'endSet',{{'timestamp' 'stimilus'} []},...
           'offset_ms',[-200 1000]);
z=jf_save(z);
oz=z;
jf_disp(z)

z=jf_retain(z,'dim','ch','vals',{'T8'});
z=jf_baseline(z,'dim','time','wght',[-200 0]);
clf;image3d(abs(z.X),1,'Xvals',z.di(1).vals,'Yvals',z.di(2).vals,'Zvals',z.di(3).vals,'disptype','image'); 
