import numpy as np
from psychopy.visual import GratingStim

# Create two stimuli
stim1 = GratingStim(win, size=128, color=1)
stim2 = GratingStim(win, size=128, color=0)

# Alternately present the stimuli and log the timestamp after each window flip
lT = []
for i in range(100):
    stim1.draw()
    win.flip()
    lT.append(self.time())
    stim2.draw()
    win.flip()
    lT.append(self.time())

# Use numpy to determine the difference between subsequent timestamps and print
# this info to the debug window.
aT = np.array(lT)
aDiff = aT[1:] - aT[:-1]
print 'M = %.2f, SD = %.2f' % (aDiff.mean(), aDiff.std())