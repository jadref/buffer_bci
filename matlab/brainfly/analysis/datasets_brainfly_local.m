% experiment name / directory
expt='own_experiments/motor_imagery/brainfly';
stripFrom='raw_buffer'; % when saving ignore after this string in dataset directory

% dataset format: cell-array of cell-arrays.  1 sub-cell array per subject.  First entry is subject ID, rest of the entries are the subject sessions.
datasets={};
datasets{1}={'s1'
             '0606di/1233/raw_buffer/0001'
             '0907do/1235/raw_buffer/0001'
             '0911ma/1002/raw_buffer/0001'
             '0912di/1624/raw_buffer/0001'
             '170925/1015AM/raw_buffer/0001'
             '170926/0424PM/raw_buffer/0001'
             '171002/1038AM/raw_buffer/0001'
             '171003/0353PM/raw_buffer/0001'
             '171009/1055AM/raw_buffer/0001'
             '171023/1103AM/raw_buffer/0001'
             '171030/1015AM/raw_buffer/0001'
             '171031/0345PM/raw_buffer/0001'
             '171107/0356PM/raw_buffer/0001'
             '171110/1044AM/raw_buffer/0001'
             '171115/1011am/raw_buffer/0001'
            };
% example to add new subject datasets
%datasets{end+1}={'s2' }
%datasets{3}={'s3' }
%datasets{4}={'s4' }
