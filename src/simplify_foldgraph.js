const {load_graph, save_graph} = require("./graph_io.js");

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
                newVerts.push(Y[edges[i+1][0]]);
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

// get arguments
const path_skel_curves = process.argv[2];
const path_output_root = process.argv[3];

let [verts, edges] = load_graph(path_skel_curves);

// make a graph
const [newVerts, newEdges] = graph_from_curves(verts, edges);

// save the intermediate graph
// save_graph(path_output_root + '_intermediate.txt', newVerts, newEdges);

// remove elbow vertices and repeated edges
const [uniqueVerts, uniqueEdges] = simplify_graph(newVerts, newEdges);

// save the final graph
save_graph(path_output_root + '_graph.txt', uniqueVerts, uniqueEdges);
