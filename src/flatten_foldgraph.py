'''
Flatten a foldgraph

Foldgraphs are obtained from a brain mesh. When that brain mesh has
spherical topology, we can flatten it by converting it into a
sphere and then into a disc (using a stereographic projection). We
use that flatten representation to flatten the mesh's foldgraph.
'''

import igl
import numpy as np
import matplotlib.pyplot as plt
from sklearn.neighbors import KDTree
import sys

_,path_base = sys.argv

def load_holes_lut(path):
  file = open(path, "r")
  arr = file.read().split("\n")
  file.close()
  lut = [int(x) for x in arr[:-1]]
  return lut

def load_skeleton_lines(path):
  file = open(path, "r")
  arr = file.read().split("\n")
  file.close()
  skel = []
  for l in arr[:-1]:
      co = l.split(" ")
      npoints = int(co[0])
      points = np.array([float(x) for x in co[1:]])
      points = np.reshape(points, (int(len(points)/3),3))
      skel.append(points)
  return skel

def load_skeleton_correspondence(path):
  file = open(path, "r")
  arr = file.read().split("\n")
  file.close()
  corr = [[float(x) for x in row.split(" ")[1:]] for row in arr[:-1]]
  return corr

path_sulcLevel0 = "%s_sulcLevel0.ply"%path_base
path_spherical = "%s_spherical.ply"%path_base
path_holes_lut = "%s_holesLUT.txt"%path_base
path_holes_vol = "%s_holesVol.ply"%path_base
path_skel = "%s_skel.cgal"%path_base
path_corresp = "%s_corresp.cgal"%path_base

# Load the original mesh
v,f = igl.read_triangle_mesh(path_sulcLevel0)

# Load the spherical deformation
s,_ = igl.read_triangle_mesh(path_spherical)

# Load the original mesh to gyral gruyère surface LUT
lut = load_holes_lut(path_holes_lut)

# Load the gyral gruyère volume
g,fg = igl.read_triangle_mesh(path_holes_vol)

# Load CGAL's skeleton lines
skel = load_skeleton_lines(path_skel)

# Load CGAL's gruyère-skeleton correspondence
corr = load_skeleton_correspondence(path_corresp)

# lut gives for each original vertex its corresponding
# vertex in gyral gruyère surface, or -1 if it was removed
nv=len(lut)
ng=len([x for x in lut if x>=0])

# Compute stereographic projection of the original mesh and its gruyère version
st = np.zeros((nv,2))
stg = np.zeros((ng,2))
min,max=np.min(s,axis=0),np.max(s,axis=0)
R=np.max(max-min)/2
i,j = 0,0
for x,y,z in s:
    a = np.arctan2(y,x)
    b = np.arccos(-z/R)
    st[i,:] = [b*np.cos(a),b*np.sin(a)]
    if lut[i]>=0:
        stg[j,:] = st[i,:]
        j += 1
    i += 1

# skel_vert contains the skeleton vertices in the skeleton correspondance array
skel_vert = np.array([x[:3] for x in corr])

# gryr_vert contains the guyère vertices in the skeleton correspondance array
gryr_vert = np.array([x[3:] for x in corr])

# g contains the same vertices as gryr_vert, but with different indices
# Compute ind is such that g[i] = gryr_vert[ind[i]]
tree = KDTree(gryr_vert)
dist, ind = tree.query(g, k=1)

# Compute dni is such that g[dni[i]] = gryr_vert[i]
# dni = np.zeros(len(ind),dtype=np.int)
dni = np.zeros(len(corr),dtype=np.int)
for i,val in enumerate(ind):
    dni[val] = i

def smooth(line, iterations=5):
    line2 = line.copy()
    N = len(line)
    for it in range(iterations):
        for i in range(1,N-1):
            line2[i] = 0.25*line[i-1] + 0.5*line[i] + 0.25*line[i+1]
        line = line2
    return line

# A single vertex in skel_vert may be connected to
# several vertices in gryr_vert. List their indices
skel_gryr_list = []
base = 0
for k in range(len(skel_vert)):
    d = np.sum((skel_vert[base]-skel_vert[k])**2)
    if d > 0.0:
        skel_gryr_list.append([skel_vert[base], base, k])
        base = k

tree2 = KDTree(np.array([arr[0] for arr in skel_gryr_list]))
stg2 = np.concatenate([stg,stg])

skeleton = []
for i in range(len(skel)):
    d2, i2 = tree2.query(skel[i], k=1)
    line = []
    width = []
    gyral_width = 0
    for idx,j in enumerate(i2):
        j = j[0]
        sk,a,b = skel_gryr_list[j]
        d = np.sqrt(np.sum((sk - gryr_vert[a:b])**2, axis=1))
        gyral_width += np.mean(d)
        w = 1/d
        x = stg2[dni[a:b]]
        y = np.sum((x.T*w).T,axis=0)/np.sum(w)
        width.append(np.mean(d))
        line.append(y)
    line = smooth(np.array(line))
    width = smooth(np.array(width))
    skeleton.append([line, width])

min_width = np.min([np.min(width) for _,width in skeleton])
max_width = np.max([np.max(width) for _,width in skeleton])
print(min_width, max_width)

import matplotlib.pyplot as plt
from matplotlib import cm

tab20 = cm.get_cmap("tab20")
rainbow = cm.get_cmap("rainbow")
plt.figure(figsize=(15,15))
# plt.scatter(stg[:,0],stg[:,1], marker=".", color="black", alpha=0.1)
for i,(line,width) in enumerate(skeleton):
    for j in range(1,len(line)):
        val = (width[j]-min_width)/(max_width-min_width)
        plt.plot(
          [line[j-1][0],line[j][0]],
          [line[j-1][1],line[j][1]],
          linewidth=1 + 14*val,
          #color=rainbow(val)
          color=tab20(i%20)
        )
plt.axis("equal")
plt.savefig("%s_flat.svg"%path_base)
