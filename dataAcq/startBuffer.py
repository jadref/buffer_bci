#!/usr/bin/python
# -*- coding: iso-8859-1 -*-

import Tkinter 
#from Tkinter import ttk
import  tkFileDialog
import time
import os

root = Tkinter.Tk()
root.title("Choose saving location")

subject = Tkinter.StringVar()
subject.set('test')
experiment = Tkinter.StringVar()
experiment.set('expt')
dataroot= Tkinter.StringVar()
dataroot.set('~/output')
saveloc = Tkinter.StringVar()
saveloc.set('')
session = Tkinter.StringVar()
session.set(os.path.normpath(time.strftime("%y%m%d/%H%M")))

def updateSaveLoc(ignored=None):
    saveloc.set(os.path.join(os.path.expanduser(os.path.normpath(dataroot.get())),experiment.get(),subject.get(),session.get()))

def pickDir():
    dnm=tkFileDialog.askdirectory(initialdir=dataroot.get(),title="Choose saving directory root")
    if not dnm==None: 
        dataroot.set(dnm)
        updateSaveLoc()

mainframe = Tkinter.Frame(root)
mainframe.grid(column=0, row=0, sticky=(Tkinter.N, Tkinter.W, Tkinter.E, Tkinter.S))

Tkinter.Label(mainframe, text="Experiment :").grid(column=1, row=1, sticky=Tkinter.W)
expt_entry = Tkinter.Entry(mainframe, width=30, textvariable=experiment)
expt_entry.grid(column=2, row=1, sticky=Tkinter.W)
expt_entry.bind("<Return>",updateSaveLoc)

Tkinter.Label(mainframe, text="Subject :").grid(column=1, row=2, sticky=Tkinter.W)
subject_entry = Tkinter.Entry(mainframe, width=30, textvariable=subject)
subject_entry.grid(column=2, row=2, sticky=Tkinter.W)
subject_entry.bind("<Return>",updateSaveLoc)

Tkinter.Label(mainframe, text="Data Root :").grid(column=1, row=3, sticky=Tkinter.W)
Tkinter.Button(mainframe, text="browse", command=pickDir).grid(column=2, row=3, sticky=Tkinter.E)
Tkinter.Label(mainframe, textvariable=dataroot).grid(column=1, columnspan=2, row=4, sticky=Tkinter.W)

Tkinter.Label(mainframe, text="Save location :").grid(column=1, row=5, sticky=Tkinter.W)
Tkinter.Label(mainframe, textvariable=saveloc).grid(column=1, columnspan=2, row=6, sticky=Tkinter.W)

Tkinter.Button(mainframe, text="Cancel", command=quit).grid(column=1, row=7, sticky=Tkinter.W)
Tkinter.Button(mainframe, text="OK", command=mainframe.quit).grid(column=2, row=7, sticky=Tkinter.E)

subject_entry.focus()
updateSaveLoc()
root.mainloop()

updateSaveLoc()
outpath=os.path.expanduser(saveloc.get())
if not os.path.exists(outpath):
    os.makedirs(outpath)
print outpath
