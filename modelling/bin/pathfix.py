# puts the 'src' directory in os.path
# include this at the top of scripts in the 'bin' directory

import sys
import os.path
# Add all the nearby eggs (this really needs to be re-written...)
modellingsrcpath = os.path.realpath(os.path.dirname(__file__) + '/../src')
sys.path.append(modellingsrcpath)

importingsrcpath = os.path.realpath(os.path.dirname(__file__) + '/../../importing/edgar_importing')
sys.path.append(importingsrcpath)

for root, dirs, files in os.walk(os.path.realpath(os.path.dirname(__file__) + '/../../importing')):
    for f in files:
        fullpath = os.path.join(root, f)
        sys.path.append(fullpath)

for root, dirs, files in os.walk(os.path.realpath(os.path.dirname(__file__) + '/../../importing/eggs')):
    for f in files:
        fullpath = os.path.join(root, f)
        sys.path.append(fullpath)

for root, dirs, files in os.walk(os.path.realpath('/home/compute/Edgar/env/lib/python2.7/site-packages/')):
    for f in files:
        fullpath = os.path.join(root, f)
        sys.path.append(fullpath)
