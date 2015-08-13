#!/usr/bin/python
# -*- coding: utf-8 -*-
try:
    # for Python2
    from Tkinter import *   ## notice capitalized T in Tkinter 
    import tkFileDialog
except ImportError:
    # for Python3
    from tkinter import *   ## notice here too
    from tkinter import filedialog
import time
import os

root = Tk()
root.title("Choose saving location")

subject = StringVar()
subject.set('test')
experiment = StringVar()
experiment.set('expt')
dataroot= StringVar()
dataroot.set('~/output')
saveloc = StringVar()
saveloc.set('')
session = StringVar()
session.set(os.path.normpath(time.strftime("%y%m%d/%H%M")))

def updateSaveLoc(ignored=None):
    saveloc.set(os.path.join(os.path.expanduser(os.path.normpath(dataroot.get())),experiment.get(),subject.get(),session.get()))

def pickDir():
    try: # for Python2
        dnm=tkFileDialog.askdirectory(initialdir=dataroot.get(),title="Choose saving directory root")
    except NameError: # for Python3
        dnm=filedialog.askdirectory(initialdir=dataroot.get(),title="Choose saving directory root")

    if not dnm==None: 
        dataroot.set(dnm)
        updateSaveLoc()

mainframe = Frame(root)
mainframe.grid(column=0, row=0, sticky=(N, W, E, S))

Label(mainframe, text="Experiment :").grid(column=1, row=1, sticky=W)
expt_entry = Entry(mainframe, width=30, textvariable=experiment)
expt_entry.grid(column=2, row=1, sticky=W)
expt_entry.bind("<Return>",updateSaveLoc)

Label(mainframe, text="Subject :").grid(column=1, row=2, sticky=W)
subject_entry = Entry(mainframe, width=30, textvariable=subject)
subject_entry.grid(column=2, row=2, sticky=W)
subject_entry.bind("<Return>",updateSaveLoc)

Label(mainframe, text="Data Root :").grid(column=1, row=3, sticky=W)
Button(mainframe, text="browse", command=pickDir).grid(column=2, row=3, sticky=E)
Label(mainframe, textvariable=dataroot).grid(column=1, columnspan=2, row=4, sticky=W)

Label(mainframe, text="Save location :").grid(column=1, row=5, sticky=W)
Label(mainframe, textvariable=saveloc).grid(column=1, columnspan=2, row=6, sticky=W)

Button(mainframe, text="Cancel", command=quit).grid(column=1, row=7, sticky=W)
Button(mainframe, text="OK", command=mainframe.quit).grid(column=2, row=7, sticky=E)

subject_entry.focus()
updateSaveLoc()
root.mainloop()

updateSaveLoc()
outpath=os.path.expanduser(saveloc.get())
if not os.path.exists(outpath):
    os.makedirs(outpath)
print(outpath)
