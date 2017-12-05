                                % experiment name / directory
expt='own_experiments/motor_imagery/brainfly';
stripFrom='raw_buffer'; % when saving ignore after this string in dataset directory

% dataset format: cell-array of cell-arrays.  1 sub-cell array per subject.  First entry is subject ID, rest of the entries are the subject sessions.
datasets={};
datasets{1}={'f1'
             '171205/0723AM/raw_buffer/0001'
             '171205/0931AM/raw_buffer/0001'
            };
datasets{2}={'f2'
             '0512Tue/0720AM/raw_buffer/0001'
             '0512Tue/0929AM/raw_buffer/0001'
            };
datasets{3}={'f3'
             '0512Tue/0721AM_1/raw_buffer/0001'
             '0512Tue/0929AM/raw_buffer/0001'
            };
% example to add new subject datasets
%datasets{end+1}={'s2' }
%datasets{3}={'s3' }
%datasets{4}={'s4' }
