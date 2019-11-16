# A way to calculate motion parameters, will have to get this from 
# the unzipped files .. gah!

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning) 
warnings.filterwarnings("ignore", category=FutureWarning) 

from argparse import ArgumentParser
import numpy as np


def calculate_FD_Power(in_file,out_file):
    """
    Method to calculate Framewise Displacement (FD)  as per Power et al., 2012
    """

    motion_params = np.genfromtxt(in_file).T

    rotations = np.transpose(np.abs(np.diff(motion_params[0:3, :])))
    translations = np.transpose(np.abs(np.diff(motion_params[3:6, :])))

    fd = np.sum(translations, axis=1) + \
        (50 * np.pi / 180) * np.sum(rotations, axis=1)

    fd = np.insert(fd, 0, 0)
    
    np.savetxt(out_file, fd)

    return out_file


def main(raw_args=None):

    # Parse in inputs    
    parser = ArgumentParser(epilog="calculate_FD.py -- A function to calculate FD as power Power et al. 2012. Kevin Aquino 2018 BMH")
    parser.add_argument("-mov", dest="mov",
        help="Movement parameters", metavar="movement.txt")
    parser.add_argument("-out", dest="out",
        help="The saved filed name for FD", metavar="FD.txt")

    # import pdb;pdb.set_trace()
    # Here we are parsing the arguments
    args = parser.parse_args(raw_args)

    # Setting the arguments
    mov = args.mov
    out = args.out

    # Calculate FD here.
    calculate_FD_Power(mov,out)

if __name__ == '__main__':
    main()


