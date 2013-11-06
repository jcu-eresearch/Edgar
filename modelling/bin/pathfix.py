# puts the 'src' directory in os.path
# include this at the top of scripts in the 'bin' directory

import sys
import os.path
modellingsrcpath = os.path.realpath(os.path.dirname(__file__) + '/../src')
sys.path.append(modellingsrcpath)

importingsrcpath = os.path.realpath(os.path.dirname(__file__) + '/../../importing/edgar_importing')
sys.path.append(importingsrcpath)

for root, dirs, files in os.walk(os.path.realpath(os.path.dirname(__file__) + '/../../importing')):
    for f in files:
        fullpath = os.path.join(root, f)
        sys.path.append(fullpath)

for root, dirs, files in os.walk(os.path.realpath('/usr/lib/python2.6/site-packages/')):
    for f in files:
        fullpath = os.path.join(root, f)
        sys.path.append(fullpath)
