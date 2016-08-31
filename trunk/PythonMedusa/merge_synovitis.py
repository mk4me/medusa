#!/usr/bin/env python

import sys
import os
import glob
import shutil
from opp import *
from contour_finder import *

DEFAULT_IN_POSTFIX='.png'
DEFAULT_OUT_POSTFIX='.png'
DEFAULT_ROOTDIR="."
DEFAULT_DATAINPUTDIR="input"
MED_DEFAULT_DATAOUTPUTDIR="_output"

currRootDir = ""
currDataInputDir = ""
currDataOutputDir = ""

def clearDataContext():
        global currRootDir, currDataInputDir, currDataOutputDir
        currRootDir = ''
        currDataInputDir = ''
        currDataOutputDir = ''

def setRootDir(rootDir):
    global currRootDir
    if (rootDir != ""):
        rootDir += '/'

    print ('setRootDir('+rootDir+')')
    currRootDir = rootDir
    
def getRootDir():
    if (currRootDir != ""):
        rootDir = currRootDir
    else:
        rootDir = DEFAULT_ROOTDIR + '/'
    return rootDir

def initRootDir():
    if (not os.path.isdir(getRootDir())):
        print ('Create', getRootDir())
        os.mkdir(getRootDir())
        
        
def setDataInputDir(inputDir):
    global currDataInputDir
    print ('setTrainDir('+inputDir+')')
    currDataInputDir = inputDir

def getDataInputDir():
    if (currDataInputDir != ""):
        dataInputDir = currDataInputDir
    else:
        dataInputDir = currRootDir + DEFAULT_DATAINPUTDIR
    
    return dataInputDir

def initDataInputDir():
    if (not os.path.isdir(getDataInputDir())):
        print ('Create', getDataInputDir())
        os.mkdir(getDataInputDir())

def setDataOutputDir(outputDir):
    global currDataOutputDir
    print ('setTrainDir('+ outputDir +')')
    currDataOutputDir = outputDir

def getDataOutputDir():
    
    if (currDataOutputDir != ""):
        dataOutputDir = currDataOutputDir
    else:
        dataOutputDir = currRootDir + MED_DEFAULT_DATAOUTPUTDIR
    
    return dataOutputDir

def initDataOutputDir():
    if (not os.path.isdir(getDataOutputDir())):
        print ('Create', getDataOutputDir())
        os.mkdir(getDataOutputDir())
    
def applyParameters(params):
    
    rootDir = oppval("RootDir", params)
    if (rootDir != None):
        setRootDir(rootDir)
    initRootDir()
    
    dataInputDir = oppval("DataInputDir", params)
    if (dataInputDir != None):
        setDataInputDir(dataInputDir)
        
    dataOutputDir = oppval("DataOutputDir", params)
    if (dataOutputDir != None):
        setDataOutputDir(dataOutputDir)
    
    initDataInputDir()
    initDataOutputDir()


def processFile(inFilePath, outFilePath, params):
    
    print "processFile: " + inFilePath
    #shutil.copy2(inFilePath, outFilePath)
    (contours, size) = find_countours(inFilePath)
    write_contours(outFilePath,contours, size)
    print "- generated: " + outFilePath
    return


def execute(command, params):

    clearDataContext()
    applyParameters(params)
    
    inPostfix = oppval('inPostfix', params)
    if (inPostfix == None):
        inPostfix = DEFAULT_IN_POSTFIX 
    print 'inPostfix:', inPostfix
    
    outPostfix = oppval('outPostfix', params)
    if (outPostfix == None):
        outPostfix = DEFAULT_OUT_POSTFIX 
    print 'outPostfix:', outPostfix
    
    print 'Read files from ', getDataInputDir()
    dir_list = glob.glob(getDataInputDir() + '/*' + inPostfix)
    
    for file in dir_list:
        print file
        fileBase = os.path.basename(file)[:-len(inPostfix)]
        outFile = getDataOutputDir() + '/' + fileBase + outPostfix
        processFile(file, outFile, params) 
    
        
def main(argv):
    
    params = ''
    if (len(argv) > 1):
        params = oppsum(params, argv[1])
    
    execute('', params)



if __name__ == "__main__":
    sys.exit(main(sys.argv))
