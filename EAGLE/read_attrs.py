import sys
import h5py

f = h5py.File(sys.argv[1], "r")
grp = f[sys.argv[2]]
attr = grp.attrs[sys.argv[3]]
f.close()

print(float(attr))
