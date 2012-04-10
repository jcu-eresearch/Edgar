# puts the 'src' directory in os.path
# include this at the top of scripts in the 'bin' directory

import sys
import os.path
srcpath = os.path.realpath(os.path.dirname(__file__) + '/../src')
sys.path.append(srcpath)
