const fs = require("fs")

// load graph
const load_graph = function (curvesPath) {
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
const save_graph = function (graph_path, verts, edges) {
  fs.writeFileSync(graph_path, [
      `${verts.length} 0 ${edges.length}`,
      ...verts.map((o)=>o.join(' ')),
      ...edges.map((o)=>o.join(' '))
  ].join('\n'));
}

module.exports = {
  load_graph,
  save_graph
};
