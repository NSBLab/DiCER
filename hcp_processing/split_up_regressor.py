# A way to calculate motion parameters, will have to get this from 
# the unzipped files .. gah!

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning) 
warnings.filterwarnings("ignore", category=FutureWarning) 

from argparse import ArgumentParser
import numpy as np
import os


def split_up_regressor(reg,folder):

    regressor_all=np.loadtxt(reg)
    dirpath = os.path.split(os.path.realpath(__file__))[0]
    

    task_stopPoints=np.loadtxt(dirpath+'/taskStopPoints.tsv')

    # All the task names
    task_nm = []
    task_nm.append('EMOTION_LR')
    task_nm.append('EMOTION_RL')
    task_nm.append('GAMBLING_LR')
    task_nm.append('GAMBLING_RL')
    task_nm.append('LANGUAGE_LR')
    task_nm.append('LANGUAGE_RL')
    task_nm.append('MOTOR_LR')
    task_nm.append('MOTOR_RL')
    task_nm.append('RELATIONAL_LR')
    task_nm.append('RELATIONAL_RL')
    task_nm.append('SOCIAL_LR')
    task_nm.append('SOCIAL_RL')
    task_nm.append('WM_LR')
    task_nm.append('WM_RL')

    # import pdb;pdb.set_trace()
    # For each of these now save it all..
    # import pdb;pdb.set_trace()
    shape_vec=regressor_all.shape
    for ind in range(0,14):
    	regressor_inds=np.where(task_stopPoints[:,ind]==1)
     	if(len(shape_vec)==1):
     		regressor=regressor_all[regressor_inds[0]]
     	else:
     		regressor=regressor_all[regressor_inds[0],:]
    	np.savetxt(folder+task_nm[ind]+'.tsv',regressor)


def main(raw_args=None):

    # Parse in inputs    
    parser = ArgumentParser(epilog="split_up_regressor.py -- A function to split up the task DiCER regressors so that there is one for each task. Kevin Aquino 2019 BMH")
    parser.add_argument("-reg", dest="reg",
        help="Task regressor", metavar="DiCER_regressor.tsv")
    parser.add_argument("-folderBase", dest="out",
        help="The basename with path for the regressor files", metavar="~/preproMethod")

    args = parser.parse_args(raw_args)

    # Setting the arguments
    reg = args.reg
    out = args.out

    # Calculate FD here.
    split_up_regressor(reg,out)

if __name__ == '__main__':
    main()


