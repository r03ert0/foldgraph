const fs = require('fs');
const tsnejs = require('../bin/tsnejs/tsne');

const opt = {
    epsilon: 10, // epsilon is learning rate (10 = default)
    perplexity: 20, // roughly how many neighbors each point influences (30 = default)
    dim: 3 // dimensionality of the embedding (2 = default)
};
const tsne = new tsnejs.tSNE(opt); // create a tSNE instance
const R = 10;

// load graph
function load_graph(curvesPath) {
    let i;
    const str = fs.readFileSync(curvesPath).toString();
    const arr = str.split('\n');
    const [nv, nt, ne] = arr[0].split(' ').map((o)=>parseInt(o));
    console.log(`Reading nverts: ${nv}, ntris:${nt}, nedges: ${ne}`);
    let tmpVerts = [];
    let tmpEdges = [];
    for(i=0;i<nv;i++) {
        tmpVerts.push(arr[i+1].split(' ').map((o)=>parseFloat(o)));
    }
    for(i = 0; i<ne; i++) {
        tmpEdges.push(arr[1+nv+i].split(' ').map((o)=>parseInt(o)));
    }
    return [tmpVerts, tmpEdges];
}

//save graph
function save_graph(graph_path, verts, edges) {
    fs.writeFileSync(graph_path, [
        `${verts.length} 0 ${edges.length}`,
        ...verts.map((o)=>o.join(' ')),
        ...edges.map((o)=>o.join(' '))
    ].join('\n'));
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

    sort_edges(edges);

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

function remove_vertex_at_index(index, verts, edges) {
    const arr = [];
    // remove the vertex
    verts.splice(index, 1);

    // remove the affected edges
    for(let i=edges.length-1;i>=0;i--) {
        const ed = edges[i];
        if(ed[0] === index ) {
            arr.push(ed[1]);
            edges.splice(i,1);
        }
        if(ed[1] === index) {
            arr.push(ed[0]);
            edges.splice(i,1);
        }
    }
    if(arr.length > 2) {
        console.error("Only vertices of degree 0, 1 or 2 can be removed. Degree =", arr.length);
        return;
    }

    // push a new edge bridging over the removed one if degree 2
    if(arr.length == 2) {
        edges.push(arr);
    }

    // adjust the indices of the remaining vertices
    for(let ed of edges) {
        if(ed[0] > index) {
            ed[0]--;
        }
        if(ed[1] > index) {
            ed[1]--;
        }
    }
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

// remove elbow vertices and isolated vertices -- in place
function remove_elbow_vertices(verts, edges) {
    let i;
    let nremoved = 0;
    const degree = [];

    // compute vertices's degrees
    for(i=0;i<verts.length; i++) {
        degree[i] = 0;
    }
    for(let ed of edges) {
        degree[ed[0]]++;
        degree[ed[1]]++;
    }
    for(i=verts.length-1;i>=0;i--) {
        if(degree[i] === 2) {
            console.log("Remove elbow vertex", i);
            remove_vertex_at_index(i, verts, edges);
            nremoved++;
        } else if(degree[i] == 0 ) {
            console.log("Remove isolated vertex", i);
            remove_vertex_at_index(i, verts, edges);
            nremoved++;
        }
    }

    return nremoved;
}
// sort edges in ascending order, and such that for e(a,b), a<b, in place.
function sort_edges(edges) {
    for(const e of edges) {
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
}

// remove repeated edges, in place
function remove_repeated_edges(edges) {
    let nremoved = 0;

    sort_edges(edges);

    for(let i = edges.length-1;i>0;i--) {
        const e1 = edges[i];
        const e2 = edges[i-1];
        if(e1[0] === e2[0] && e1[1] === e2[1]) {
            console.log("Remove repeated edge", e1);
            edges.splice(i, 1);
            nremoved++;
        }
    }

    return nremoved;
}

// progressively project Y to a sphere of radius R (inplace)
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

// make a graph
function simplify_graph(newVerts, newEdges) {
    const [uniqueVerts, uniqueEdges] = combine_vertices(newVerts, newEdges);
    
    let didChange;
    do {
        didChange = 0;
        didChange += remove_elbow_vertices(uniqueVerts, uniqueEdges);
        didChange += remove_repeated_edges(uniqueEdges);
    } while(didChange > 0);

    return [uniqueVerts, uniqueEdges];
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
save_graph(path_output_root + '_curves.txt', flatY, edges);

// make a graph
const [newVerts, newEdges] = graph_from_curves(flatY, edges);

// save the final graph
save_graph(path_output_root + '_intermediate.txt', newVerts, newEdges);

// remove elbow vertices and repeated edges
const [uniqueVerts, uniqueEdges] = simplify_graph(newVerts, newEdges);

// save the final graph
save_graph(path_output_root + '_graph.txt', uniqueVerts, uniqueEdges);
