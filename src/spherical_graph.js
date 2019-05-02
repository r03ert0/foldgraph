const fs = require('fs');
const tsnejs = require('../bin/tsnejs/tsne');

const opt = {
    epsilon: 10, // epsilon is learning rate (10 = default)
    perplexity: 20, // roughly how many neighbors each point influences (30 = default)
    dim: 3 // dimensionality of the embedding (2 = default)
};
const tsne = new tsnejs.tSNE(opt); // create a tSNE instance
const R = 10;

let i, j, k;

// progressively project Y to a sphere of radius R
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

// combine vertices which are too close
function combine_vertices(verts, edges) {
    const uniqueVerts = [];
    const uniqueEdges = [];
    const lut = [];
    let tol = 1e-3;
    let i, j;
    let max = 0;

    // adjust combination threshold to maximum graph length
    for(i=0;i<verts.length;i++) {
        for(j=0;j<verts.length;j++) {
            const [x1,y1,z1] = verts[i];
            const [x2,y2,z2] = verts[j];
            const d = Math.sqrt((x1-x2)**2+(y1-y2)**2+(z1-z2)**2);
            if(d > max) {
                max = d;
            }
        }
    }
    tol = max * tol;

    // combine nodes below the length tolerance
    for(i=0;i<verts.length;i++) {
        if(typeof lut[i] === 'undefined') {
            lut[i] = uniqueVerts.length;
            uniqueVerts.push(verts[i]);
        }
        for(j=i+1;j<verts.length;j++) {
            const [x1,y1,z1] = verts[i];
            const [x2,y2,z2] = verts[j];
            const d = Math.sqrt((x1-x2)**2+(y1-y2)**2+(z1-z2)**2);
            if(d<tol && typeof lut[j] === 'undefined') {
                lut[j] = lut[i];
            }
        }
    }

    // sort edges in ascending order, and such that for e(a,b), a<b.
    for(e of edges) {
        if(e[1]<e[0]) {
            const tmp = e[0];
            e[0] = e[1];
            e[1] = tmp;
        }
    }
    edges.sort((a, b) => {
        if(a[0]<b[0]) { return -1}
        else if (a[0]>b[0]) { return 1}
        else return a[1]-b[1];
    });
    for(i=0;i<edges.length;i++) {
        const a = lut[edges[i][0]];
        const b = lut[edges[i][1]];
        // do not push 0-length edges
        if( a !== b ) {
            uniqueEdges.push([a, b]);
        }
    }

    return [uniqueVerts, uniqueEdges];
}

// extract graph lines from curves
function graph_from_curves(Y, edges) {
    const newVerts = [];
    const newEdges = [];
    let i;
    newVerts.push(Y[0]);
    for(i = 0; i < edges.length - 1; i++) {
        if(edges[i][1] != edges[i+1][0]) {
            newVerts.push(Y[edges[i][1]]);
            newEdges.push([newVerts.length - 2, newVerts.length - 1]);
            if(i < edges.length - 2) {
                newVerts.push(flatY[edges[i+1][0]]);
            }
        }
    }

    return [newVerts, newEdges];
}

// load data
function load_data(curvesPath) {
    let i;
    const str = fs.readFileSync(curvesPath).toString();
    const arr = str.split('\n');
    const [nv, nt, ne] = arr[0].split(' ').map((o)=>parseInt(o));
    console.log(nv,nt,ne);
    let tmpVerts = [];
    let tmpEdges = [];
    let dists = [];
    for(i=0;i<nv;i++) {
        tmpVerts.push(arr[i+1].split(' ').map((o)=>parseFloat(o)));
        dists.push([]);
    }
    for(i = 0; i<ne; i++) {
        tmpEdges.push(arr[1+nv+i].split(' ').map((o)=>parseInt(o)));
    }
    return [tmpVerts, tmpEdges];
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
    for(k = 0; k < 100; k++) {
        tsne.step();
        console.log(k, Y[0]);
        spherical_projection(Y);
    }

    return Y;
}

// polar stereographic projection
function stereographic(Y) {
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

function save_graph(graph_path, verts, edges) {
    fs.writeFileSync(graph_path, [
        `${verts.length} 0 ${edges.length}`,
        ...verts.map((o)=>o.join(' ')),
        ...edges.map((o)=>o.join(' '))
    ].join('\n'));
}

// load skeleton curves
let [tmpVerts, tmpEdges] = load_data('../data/derived/skeleton/baboon/both_skel_curves.txt');
let [verts, edges] = combine_vertices(tmpVerts, tmpEdges);

// project the curves into a sphere using tSNE
let Y = run_tsne(verts);

// flatten the sphere into a disc
let flatY = stereographic(Y);

// save the resulting flat curves
save_graph('result_curves.txt', flatY, edges);

// make a graph
const [newVerts, newEdges] = graph_from_curves(flatY, edges);
const [uniqueVerts, uniqueEdges] = combine_vertices(newVerts, newEdges);

// save the resulting flat graph
save_graph('result_graph.txt', uniqueVerts, uniqueEdges);
