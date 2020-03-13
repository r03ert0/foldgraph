# foldgraph
Roberto Toro, Katja Heuer, May 2017

## Description
Folding patterns in different species are very characteristic, however, their description remains mostly qualitative. `foldgraph` is a script to convert folding patterns into graphs. These graphs can then be compared quantitatively, using for example the *Graph Edit Distance* algorithm.

![foldgraph.png](foldgraph.png)

## Getting started

#### Install submodules
`foldgraph` relies on several other commands, which are installed as git submodules. After clonning the `foldgraph` repository, you need to initialise the submodules as follows:

In the root directory, run
`git submodule init` and  
`git submodule update`  

#### Compile the submodules 
The script `0_compile_all_submodules.sh`, normally, will compile all the submodules. Run it from inside the `src` directory as follows:

`cd src`  
`source 0_compile_all_submodules.sh`  

#### Adapt subjects.txt

The `1_fold_graph_all.sh` script will process all the meshes that you have placed inside the `/data/raw` directory. Each subject directory should contain at least one mesh file in `.ply` format to process. Additional files can be used to control the `foldgraph` generation, or to add manually edited intermediate steps (more on this right after). The list of subjects that you want to analyse is placed in a text file called, for example, `subjects.txt` inside the `data` directory (see the example). Each line in this text file should point to the mesh in the `/data/raw/` directory that you want to process. Finally, the name of the text file with the subjects has to be writen in the `1_fold_graph_all.sh` script. For example, to point to your input meshes e.g. `subject001/mesh.ply`  
and then run  
`source 1_fold_graph_all.sh`  


#### Provide a rotation matrix for the raw mesh
You can provide a rotation matrix along with he raw mesh data, called `sphericalgraph-config.txt`. It will reorient the mesh prior to spherical projection and flattening of the raw skeleton.

#### Provide a manually curated *Holes Surface*.
The *holes surface* is the original surface mesh provided as input where the sulcal regions have been removed. The removal is based on the mean curvature of the surface, which in some cases may not be satisfactory. You can use a mesh editing application -- we use MeshSurgery -- to modifi this mesh. You can check and modify the `mesh_holesSurf.ply` manually, and delete bridges, or tunnels as appropriate, before it will be turned into a volume. This manually modified `mesh_holesSurf.ply` has to be inside your `data/raw/subject/` folder and the algorithm will start from there next time you execute the script.

#### Provide a manually curated *Holes Volume*.
The *holes surface* is transformed into a volumetric surface using the marching cubes algorithm. Marching cubes sometimes fuses regions which are too close. You can either decrease the voxel size (using the `config.txt` file), or just go and modify the resulting *holes volume* mesh (again, MeshSurgery may come handy). As before, place the modified version of the `_holesVol.ply` mesh inside `/data/raw/[subject]`, and `foldgraph` will run starting from there.


#### Outputs inside the derived folder
In sequence, the code produces

* `mesh_sulcLevel0.ply`: a copy of the original surface mesh  
* `mesh_sulcMap.txt`: mean curvature map  
* `mesh_holesSurf.ply` a surface mesh where the sulci are cut and appear as holes  
* `mesh_holesSurfVox.ply`: same as before but converted to *voxel coordinates* instead of *world coordinates* (that's how `meshgeometry` likes its surfaces for voxelisation)
* `mesh_holesVol.off`: makes a volume file from the surface using marching cubes (the skeletonisation algorithm only reads `.off` meshes, for the moment)
* `mesh_holesVol.ply`: same as before, but converted to `.ply` format so we can visualise it easily. This is also the mesh we use for manually editing (unstickicking gyri, reconstructing walls if necessary).
* `mesh_skel.cgal`: the resulting skeleton, in `.cgal` format
* `mesh_corresp.cgal`: the correspondance between points in the skeleton and points in the `_holesVol` mesh
* `mesh_skel_curves.txt`: the skeleton curves from the `_skel.cgal` file converted to a `.txt` format that MeshSurgery can read
* `mesh_skel_graph.txt`: the skeleton curves converted into a graph, i.e., only vertices connecting more than 2 edges in the `_skel_curves.txt` file are kept.  



--------------------------------------------
#### Adjust parameters (foldgraphv4)
** These instructions go with v4 of the foldgraph script. If you work with the current version (v5), these settings are no more needed. As we do not use the marching cubes algorithm anymore, these 3 parameters are no more used.**

You can modify the default parameters for the *iso-surface level*, the *voxel size* and the *decimation ratio* used during the marching cubes. To do so, provide a `foldgraph-config.txt` next to your rawmesh.ply inside your `data/raw/subject/` folder containing the following:  
`isosurface-level 1000`  
`vox-dim 0.125`  
`decimation-ratio 20`  
The default values are `1000`, `0.25` and `20`.  
 
* *isosurface-level*. If you make the isosurf level larger: the surface will be thinner; if you decrease the number: the surface will be thicker (and gyri may fuse in wrong places, careful, but it closes little holes on the other hand).
* *vox-dim*. The voxel size used during the marching cubes algorithm. The bigger, the thicker the surface volume will be (and gryi may fuse at some point in werong places); the smaller voxels --> the less likely it will fuse. For smaller brains it is advantageous to decrease the number from default (0.25) to eg. 0.125.
* *decimation-ratio*. If you decrease vox dim, you may want to increase the decimation ratio to stay with a reasonable number of triangles per mesh. For example in a mid-sized mesh, at voxel size 0.25, this gives 45000 triangles. So at 0.1 voxel size, it will instead of 40k generate 400k triangles --> adjust decimation-ratio to 200.  
--------------------------------------------


## Project directory description
A project directory structure based on https://drivendata.github.io/cookiecutter-data-science/

```
├── LICENSE
├── ReadMe.md          <- The top-level README for developers using this project.
├── data
│   ├── derived        <- The final, canonical data sets for modeling.
│   └── raw            <- The original, immutable data dump.
│
├── docs               <- A default Sphinx project; see sphinx-doc.org for details
│
├── notebooks          <- Jupyter notebooks. Naming convention is a number (for ordering),
│                         the creator's initials, and a short `-` delimited description, e.g.
│                         `1.0-jqp-initial-data-exploration`.
│
├── references         <- Data dictionaries, manuals, and all other explanatory materials.
│
├── reports            <- Generated analysis as HTML, PDF, LaTeX, etc.
│   └── figures        <- Generated graphics and figures to be used in reporting
│
├── requirements.txt   <- The requirements file for reproducing the analysis environment, e.g.
│                         generated with `pip freeze > requirements.txt`
│
└── src                <- Source code for use in this project.
```