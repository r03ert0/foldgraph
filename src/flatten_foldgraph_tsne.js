const {load_graph, save_graph} = require("./graph_io.js");
const tsnejs = require('../bin/tsnejs/tsne');

const opt = {
    epsilon: 10, // epsilon is learning rate (10 = default)
    perplexity: 20, // roughly how many neighbors each point influences (30 = default)
    dim: 3 // dimensionality of the embedding (2 = default)
};
const tsne = new tsnejs.tSNE(opt); // create a tSNE instance
const R = 10;

// progressively project Y to a sphere of radius R (inplace)
// to move to the sphere slowlier, change the values to 0.95 and 0.05 or comparably
function spherical_projection(Y) {
    let radius;
    for(i=0;i<Y.length;i++) {
        const [x,y,z] = Y[i];
        radius = Math.sqrt(x*x+y*y+z*z) / R;
        Y[i][0] = 0.9*Y[i][0] + 0.1*x/radius;
        Y[i][1] = 0.9*Y[i][1] + 0.1*y/radius;
        Y[i][2] = 0.9*Y[i][2] + 0.1*z/radius;
    }
}

// run tSNE
function run_tsne(verts) {
    let i, j, k;
    const dists = [];
    // initialise distance matrix
    let distance;
    for(i = 0; i<verts.length;i++) {
        dists[i] = [];
    }
    for(i = 0; i<verts.length;i++) {
        for(j = 0; j<verts.length;j++) {
            distance = Math.sqrt(
                (verts[i][0]-verts[j][0])**2
                + (verts[i][1]-verts[j][1])**2
                + (verts[i][2]-verts[j][2])**2
            );
            dists[i][j] = distance;
            dists[j][i] = distance;
        }
    }
    tsne.initDataDist(dists);

    // first step to initialise the output array
    tsne.step();
    const Y = tsne.getSolution();

    // set original vertex positions in output array
    for(i = 0; i < Y.length; i++) {
        for(j = 0; j <opt.dim; j++) {
            Y[i][j] = verts[i][j];
        }
    }

    // run tsne
    /*for(k = 0; k < 5000; k++) {*/ /*for big complex brains, increase number of tsne iterations*/
    for(k = 0; k < 100; k++) {
        tsne.step();
        // console.log(k, Y[0]);
        spherical_projection(Y);
    }

    return Y;
}

// polar stereographic projection
function stereographic(Y) {
    let i;
    for(i=0;i<Y.length;i++) {
        let [x, y, z] = Y[i];
        const radius = Math.sqrt(x*x+y*y+z*z);
        x/=radius;
        y/=radius;
        z/=radius;
        const a = Math.atan2(y,x);
        const r = Math.acos(z);
        Y[i][0] = r*Math.cos(a);
        Y[i][1] = r*Math.sin(a);
        Y[i][2] = 0;
    }

    return Y;
}

function rotvec(R, v) {
    return [
        R[0]*v[0] + R[1]*v[1] + R[2]*v[2],
        R[3]*v[0] + R[4]*v[1] + R[5]*v[2],
        R[6]*v[0] + R[7]*v[1] + R[8]*v[2],
    ]
}

// get arguments
const path_skel_curves = process.argv[2];
const path_output_root = process.argv[3];
let rotation;
if(process.argv[4] === "--rotation") {
    rotation = process.argv[5].split(",").map((o) => parseFloat(o));
    console.log("Using rotation matrix", rotation);
}

// load skeleton curves
let [verts, edges] = load_graph(path_skel_curves);

// rotate if required
if(typeof rotation !== "undefined") {
    for(let i=0;i<verts.length;i++) {
        verts[i] = rotvec(rotation, verts[i]);
    }
}

// project the curves into a sphere using tSNE
let Y = run_tsne(verts);

// flatten the sphere into a disc
let flatY = stereographic(Y);

// save the resulting flat curves
save_graph(path_output_root + '_skel_curves_flat-tsne.txt', flatY, edges);
