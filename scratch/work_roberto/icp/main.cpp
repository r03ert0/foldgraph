#include <Eigen/Core>
#include <iostream>
#include <sys/stat.h>
#include <igl/readPLY.h>
#include <igl/writePLY.h>
#include <igl/point_mesh_squared_distance.h>

#include <stdio.h>
#include <stdlib.h>

igl::AABB<Eigen::MatrixXd,3> tree;

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

int main(int argc, char * argv[])
{
  using namespace Eigen;
  using namespace std;
  using namespace igl;
  
  /*
    Register mesh mov to mesh ref
  */
  char *path_ref = argv[1];
  char *path_mov = argv[2];
  char *path_result = argv[3];
  float diff;

  struct stat info;
  if(stat(path_ref,&info))
      printf("File %s not found\n", path_ref);
  if(stat(path_mov,&info))
      printf("File %s not found\n", path_mov);

  MatrixXd Vmov; // Vmov is changed
  MatrixXd Vref;
  MatrixXi Fmov;
  MatrixXi Fref;
  MatrixXd TMP1;
  MatrixXd TMP2;

  igl::readPLY(path_ref, Vref, Fref, TMP1, TMP2);
  std::cout<<"Ref nv, nt: "<<Vref.rows()<<", "<<Fref.rows()<<std::endl;

  igl::readPLY(path_mov, Vmov, Fmov, TMP1, TMP2);
  std::cout<<"Mov nv, nt: "<<Vmov.rows()<<", "<<Fmov.rows()<<std::endl;
  
  int iter = icp(Vref, Fref, &Vmov, Fmov, &diff);
  if(path_result)
  {
      igl::writePLY(path_result, Vmov, Fmov);
      printf("iterations: %i\n", iter);
  }
  else
      printf("No output path provided, nothing saved\n");

  return 0;
}
