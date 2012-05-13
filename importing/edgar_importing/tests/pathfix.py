# puts the 'src' directory in os.path
import sys
import os.path
srcpath = os.path.realpath(os.path.dirname(__file__) + '/../src')
sys.path.append(srcpath)
