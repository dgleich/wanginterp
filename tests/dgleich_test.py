import sys
import numpy
import pylab
from numpy import zeros, ones, linspace, kron, linalg, exp, sqrt, diag, \
                  arctan, pi

sys.path.extend(['.', '..', 'tests'])
from wanginterp import Interp1D, Interp1DVG

x = numpy.array([1,2,3],dtype=float)
fx = numpy.array([1,4,9],dtype=float)
interp = Interp1D(x, fx, l=1, verbose=2)
X,E,C=interp.interp_matrices([1.5,2.5])
print X
print E
print C

