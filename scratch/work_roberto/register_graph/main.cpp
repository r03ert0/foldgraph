#include <Eigen/Core>
#include <iostream>
#include <sys/stat.h>
#include <igl/readPLY.h>
#include <igl/writePLY.h>
#include <igl/point_mesh_squared_distance.h>
#include <igl/slice.h>
#include <igl/barycentric_coordinates.h>

#include <stdio.h>
#include <stdlib.h>

igl::AABB<Eigen::MatrixXd,3> tree;

/*
float icp_step(Eigen::MatrixXd *Vmov, Eigen::MatrixXd Vref, Eigen::MatrixXi Fref)
{
  using namespace Eigen;
  using namespace std;
  using namespace igl;

  int i;
  float dist = 0;

  // compute closest points
  VectorXd sqrD;
  VectorXi I;
  MatrixXd Vout;

  igl::point_mesh_squared_distance(*Vmov, Vref, Fref, sqrD, I, Vout);

  // compute rotation and translation
  MatrixXd C = Matrix3d::Constant(0);
  VectorXd oout = Vout.colwise().sum()/Vout.rows();
  VectorXd omov = (*Vmov).colwise().sum()/(*Vmov).rows();

  for(i=0;i<(*Vmov).rows();i++)
    C += ((*Vmov).row(i) - omov.transpose()).transpose()
         * (Vout.row(i) - oout.transpose());

  JacobiSVD<MatrixXd> svd(C, ComputeThinU|ComputeThinV);
  Matrix3d U = svd.matrixU();
  Matrix3d V = svd.matrixV().transpose();

  MatrixXd R = U*V;
  MatrixXd t = omov - R*oout;

  // apply rotation and translation
  (*Vmov)*=R;
  (*Vmov).transpose().colwise() -= t.col(0);

  // check convergence
  // angle_dist = arccos((trace(P*Q')-1)/2), P, Q rotation matrices
  // (here, Q=I)
  // http://www.boris-belousov.net/2016/12/01/quat-dist/
  dist = acos((R.trace()-1)/2.0);
  dist = dist + t.norm();

  return dist;
}
  
int icp(Eigen::MatrixXd Vref, Eigen::MatrixXi Fref,
        Eigen::MatrixXd *Vmov, Eigen::MatrixXi Fmov,
        float *diff)
{
  using namespace Eigen;
  using namespace std;
  using namespace igl;

  int i;
  float dist;
  int maxiter = 100;
  float tol = 1e-6;

  // init distance AABB tree
  tree.init(Vref, Fref);

  float dist0=-1;

  for(i=0;i<maxiter;i++)
  {
    dist = icp_step(Vmov, Vref, Fref);
    if(dist0<0)
    {
        *diff = dist;
        printf("initial distance: %g\n", *diff);
    }
    else
        *diff = fabs(dist-dist0);

    if(*diff < tol)
        break;

    dist0=dist;
  }
  printf("final distance: %g (after %i iterations)\n", *diff, i);

  return i;
}
*/

void read_vertices(char *path, Eigen::MatrixXd *V, Eigen::MatrixXi *E)
{
  using namespace Eigen;
  using namespace std;

  FILE *f;
  int i, nv, ne;
  float x, y, z;
  int a, b;

  f=fopen(path,"r");
  fscanf(f," %i %*i %i ", &nv, &ne);
  cout<<"verts: "<<nv<<endl;
  MatrixXd X(nv, 3);
  for(i=0;i<nv;i++)
  {
    fscanf(f, " %f %f %f ", &x, &y, &z);
    X.row(i)<<x,y,z;
  }
  MatrixXi Y(ne, 2);
  for(i=0;i<ne;i++)
  {
    fscanf(f, " %i %i ", &a, &b);
    Y.row(i)<<a,b;
  }
  (*V) = X;
  (*E) = Y;
}

void save_vertices(char *path, Eigen::MatrixXd V, Eigen::MatrixXi E)
{
  using namespace Eigen;
  using namespace std;
  
  FILE *f;
  int i;
  
  f=fopen(path,"w");
  fprintf(f,"%i 0 %i\n", (int)V.rows(), (int)E.rows());
  for(i=0;i<V.rows();i++)
  {
    fprintf(f, "%f %f %f\n", V(i,0), V(i,1), V(i,2));
  }
  for(i=0;i<E.rows();i++)
  {
    fprintf(f, "%i %i\n", E(i,0), E(i,1));
  }
  fclose(f);
}

int main(int argc, char * argv[])
{
  using namespace Eigen;
  using namespace std;
  using namespace igl;
  
  /*
    Transform fold curves to sphere
  */
  char path_orig[] = "/Users/roberto/Documents/annex-foldgraph/data/raw/baboon/both.ply";
  char path_sph[] = "/Users/roberto/Documents/annex-foldgraph/data/derived/skeleton/baboon/both_spherical.ply";
  char path_verts[] = "/Users/roberto/Documents/annex-foldgraph/data/derived/skeleton/baboon/both_skel_curves.txt";
  char path_out[] = "/Users/roberto/Documents/annex-foldgraph/data/derived/skeleton/baboon/test.txt";

  struct stat info;
  if(stat(path_orig, &info))
      printf("File %s not found\n", path_orig);
  if(stat(path_sph, &info))
      printf("File %s not found\n", path_sph);
  if(stat(path_verts, &info))
      printf("File %s not found\n", path_verts);

  MatrixXd Vorig, Vsph;
  MatrixXi Forig, Fsph;
  MatrixXd TMP1, TMP2;

  igl::readPLY(path_orig, Vorig, Forig, TMP1, TMP2);
  cout<<"Original nv, nt: "<<Vorig.rows()<<", "<<Forig.rows()<<endl;

  igl::readPLY(path_sph, Vsph, Fsph, TMP1, TMP2);
  cout<<"Spherical nv, nt: "<<Vsph.rows()<<", "<<Fsph.rows()<<endl;

  MatrixXd V;
  MatrixXi E;
  Vector3d t;
  t<<32.5,38.74,23.92;
  read_vertices(path_verts, &V, &E);
  V*=0.26;
  V.transpose().colwise() -=t;
  cout<<"Verts: "<<V.rows()<<endl;

  // init distance AABB tree
  tree.init(Vorig, Forig);

  // compute closest points
  VectorXd sqrD;
  VectorXi I;
  MatrixXd Vout;
  igl::point_mesh_squared_distance(V, Vorig, Forig, sqrD, I, Vout);

  // get barycentric coordinates
  MatrixXd Vx, Vy, Vz, B;
  Vector3d xyz;
  xyz<<0,1,2;
  MatrixXd VV(Vout.rows(),3);
  MatrixXi FF;
  slice(Forig, I, xyz, FF);
  slice(Vorig, FF.col(0), xyz, Vx);
  slice(Vorig, FF.col(1), xyz, Vy);
  slice(Vorig, FF.col(2), xyz, Vz);
  barycentric_coordinates(Vout, Vx, Vy, Vz, B);

  // get coordinates in Vsph space
  slice(Vsph, FF.col(0), xyz, Vx);
  slice(Vsph, FF.col(1), xyz, Vy);
  slice(Vsph, FF.col(2), xyz, Vz);
  int i;
  for(i=0;i<Vout.rows();i++)
    VV.row(i) = Vx.row(i)*B(i, 0) + Vy.row(i)*B(i, 1) + Vz.row(i)*B(i, 2);
    
  // save result
  save_vertices(path_out, VV, E);

  return 0;
}
