# puts the 'src' directory in os.path
# include this at the top of scripts in the 'bin' directory

import sys
import os.path
modellingsrcpath = os.path.realpath(os.path.dirname(__file__) + '/../src')
sys.path.append(modellingsrcpath)

importingsrcpath = os.path.realpath(os.path.dirname(__file__) + '/../../importing/edgar_importing')
sys.path.append(importingsrcpath)
