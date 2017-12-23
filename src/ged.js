"use strict";

/*
    node indices are unique!
    i.e., if g1 and g2 are disjoint graphs, their nodes
    cannot have the same indices.
*/
var myg1={
    n:new Set([0,1,2,3]),
    e:new Set(['0,1','1,2','2,3','3,1'])
};
var myg2={
    n:new Set([4,5,6]),
    e:new Set(['4,5','5,6'])
};

function a(e,v) {
    var ab=e.split(',').map(function(o){return parseInt(o)});
    if(v) {
        ab[0]=v;
        return ab[0]+','+ab[1];
    }
    return ab[0];
}
function b(e,v) {
    var ab=e.split(',').map(function(o){return parseInt(o)});
    if(v) {
        ab[1]=v;
        return ab[0]+','+ab[1];
    }
    return ab[1];
}
function equal(g1,g2) {
    var i,o;

    // compare nodes
    if(g1.n.size!=g2.n.size) {
        console.log(" different number of nodes");
        return false;
    }
    for(o of [...g1.n]) {
        if(g2.n.has(o)==false) {
            console.log(" node",o,"is not in g2");
            return false;
        }
    };

    // compare edges
    if(g1.e.size!=g2.e.size) {
        console.log(" different number of edges");
        return false;
    }
    for(o of [...g1.e]) {
        if(g2.e.has(o)==false &&
            g2.e.has(b(o)+','+a(o))==false) {
            console.log(" edge",o,"is different");
            return false;
        }
    };
    return true;
}
/**
 * @func edit(g1,g2,l)
 * @desc Apply the transformation path l to transform g1 into g2
 */
function edit(g1,g2,l) {
    var i,j,op,g={n:[],e:[]},c=0;
    
    // copy g1 into g
    g.n=new Set([...g1.n]);
    g.e=new Set([...g1.e]);
    
    // apply the graph edit operations in l
    for(i=0;i<l.length;i++) {
        switch(l[i].op) {
            case 'ns': // node substitution
                var u,v;
                u=l[i].arg[0];
                v=l[i].arg[1];
                // substitute node
                if(g.n.has(u)) {
                    g.n.delete(u);
                    g.n.add(v);
                    c+=cost('ns');
                }
                // update edges
                g.e.forEach(function(o) {
                    if(a(o)==u) {
                        g.e.delete(o);
                        g.e.add(a(o,v));
                    }
                    if(b(o)==u) {
                        g.e.delete(o);
                        g.e.add(b(o,v));
                    }
                });
                break;
            case 'nd': // node deletion (plus implicit edge deletion)
                var u;
                u=l[i].arg[0];
                // delete node
                if(g.n.has(u)) {
                    g.n.delete(u);
                    c+=cost('nd');
                }
                // implicit edge deletions
                g.e.forEach(function(o) {
                    if(a(o)==u || b(o)==u) {
                        g.e.delete(o);
                        c+=cost('ed');
                    }
                });
                break;
            case 'ni': // node insertion
                var u,v,op;
                u=l[i].arg[0];
                g.n.add(u);
                // implicit edge modifications
                /*
                    node u has neighbours v in g1
                    - for each neighbour v, check if it has already been moved to g2
                    - if u,v are also neighbours in g2, add an edge substitution
                    - if u,v are not any longer neighbours in g2, add an edge deletion
                */
                for(e of g.e) {
                    if(a(e)==u) {
                        v=b(e);
                        // check if v is in g2
                        for(op of l) {
                            if(op.arg[0]==v) {

                                break;
                            }
                        }
                    }
                    if(b(e)==u) {
                    }
                }
                /*
                    node u has w neighbours in g2
                    - if u,w were not neighbours in g1, add an edge insertion
                */
                break;
        }
    }
    
    return {g:g,c:c};
}
function cost(op) {
    var c;
    switch(op) {
        case 'ns': // node substitution
            c=0;
            break;
        case 'nd': // node deletion
            c=1;
            break;
        case 'ni': // node insertion
            c=1;
            break;
        case 'ed': // edge deletion
            c=1;
            break;
        case 'ei': // edge insertion
            c=1;
            break;
    }
    return c;
}
function gprint(g) {
    var gg={g:{n:[...g.g.n],e:[...g.g.e]},c:g.c};
    return gg;
}
/**
 * @func ged(g1,g2)
 * @desc Compute the graph edits necessary to transform g1 into g2
 * @param g1 Graph Source graph
 * @param g2 Graph Target graph
 * @output A graph editing path and its cost
 */
function ged(g1,g2) {
    var open=[];
    var w,l,i,j,k,min,lmin;
    var n,m;
    
    n=g1.n.length;
    m=g2.n.length;
    
    for(w=0;w<n;w++) {
        l=new Array([{op:'ns',arg:[0,w]}]);
        open.push({
            l:l,
            c:cost(l[0])
        });
    }
    l=new Array([{op:'nd',arg:[0]}]);
    open.push({l:l,c:cost(l[0])});
    
    while(open.length) {
        k++;
    
        // find path l of least cost
        min=0;
        for(i=0;i<open.length;i++) {
            if(open[i].c<open[min].c) {
                min=i;
            }
        }
        
        // take it
        lmin=open.splice(min,1)[0];
        
        // check if lmin is a complete edit
        if(equal(g2,edit(g1,lmin.l))) {
            return lmin;
        } else {
        // if not, continue processing nodes
            if(k<g1.n.length) {
                // for each yet unassigned node add a path including it
                for(w=0;w<g2.n.length;j++) {
                    for(j=0;j<lmin.l.length;j++) {
                        if(lmin.l[j].op=='ns' && lmin.l[j].arg[1]==w) {
                            continue;
                        }
                    }
                    l=lmin.concat([{op:'ns',arg:[k,w]}]);
                    open.push({
                        l:l,
                        c:cost()
                    });
                }
            } else {
                var a=[];
                for(w=0;g2.n.length;j++) {
                    for(j=0;j<lmin.l.length;j++) {
                        if(lmin.l[j].op=='ns' && lmin.l[j].arg[1]==w) {
                            continue;
                        }
                    }
                    a.push([{op:'ni',arg:[w]}]);
                }
                l=lmin.concat(a);
                open.push({l:l,c:cost(l)});
            }
        }
        
    }
}

/*
    Tests
*/
var tests=[
function () {
    console.log(" * test equal: same");
    var myg1={n:new Set([1,2,3]),e:new Set(['1,2','2,3','3,1'])};
    var myg2={n:new Set([1,2,3]),e:new Set(['1,2','2,3','3,1'])};
    if(equal(myg1,myg2)!==true) {
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test equal: same but different node order");
    var myg1={n:new Set([1,2,3]),e:new Set(['1,2','2,3','3,1'])};
    var myg2={n:new Set([3,2,1]),e:new Set(['1,2','2,3','3,1'])};
    if(equal(myg1,myg2)!==true) {
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test equal: same but different edge order");
    var myg1={n:new Set([1,2,3]),e:new Set(['1,2','2,3','3,1'])};
    var myg2={n:new Set([1,2,3]),e:new Set(['1,2','3,2','3,1'])};
    if(equal(myg1,myg2)!==true) {
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test equal: different #nodes");
    var myg1={n:new Set([1,2,3]),e:new Set(['1,2','2,3','3,1'])};
    var myg3={n:new Set([1,2]),e:new Set(['1,2','2,3','3,1'])};
    if(equal(myg1,myg3)!==false) {
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test equal: different #edges");
    var myg1={n:new Set([1,2,3]),e:new Set(['1,2','2,3','3,1'])};
    var myg3={n:new Set([1,2,3]),e:new Set(['1,2','2,3'])};
    if(equal(myg1,myg3)!==false) {
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test edit: null edit");
    var myg4={n:new Set([1,2,3,4]),e:new Set(['1,2','2,3','3,4','4,2'])};
    var myg5={n:new Set([5,6,7]),e:new Set(['5,6','6,7'])};
    var l=[]; // null graph edit
    var g=edit(myg4,myg5,l);
    var g_expected={
        g:{n:new Set([1,2,3,4]),e:new Set(['1,2','2,3','3,4','4,2'])},
        c:0
    };

    if(equal(g.g,g_expected.g)!=true || g.c!=g_expected.c) {
        console.log(JSON.stringify(g));
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test edit: delete 1 node");
    var myg4={n:new Set([1,2,3,4]),e:new Set(['1,2','2,3','3,4','4,2'])};
    var myg5={n:new Set([5,6,7]),e:new Set(['5,6','6,7'])};
    var l=[{op:'nd',arg:[1]}]; // delete one node
    var g=edit(myg4,myg5,l);
    var g_expected={
        g:{n:new Set([2,3,4]),e:new Set(['2,3','3,4','4,2'])},
        c:2
    };

    if(equal(g.g,g_expected.g)!=true || g.c!=g_expected.c) {
        console.log(JSON.stringify(g));
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test edit: delete 2 nodes");
    var myg4={n:new Set([1,2,3,4]),e:new Set(['1,2','2,3','3,4','4,2'])};
    var myg5={n:new Set([5,6,7]),e:new Set(['5,6','6,7'])};
    var l=[{op:'nd',arg:[2]}]; // delete one node
    var g=edit(myg4,myg5,l);
    var g_expected={
        g:{n:new Set([1,3,4]),e:new Set(['3,4'])},
        c:4
    };

    if(equal(g.g,g_expected.g)!=true || g.c!=g_expected.c) {
        console.log(JSON.stringify(g));
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test edit: node substitution");
    var myg4={n:new Set([1,2,3,4]),e:new Set(['1,2','2,3','3,4','4,2'])};
    var myg5={n:new Set([5,6,7]),e:new Set(['5,6','6,7'])};
    var l=[{op:'ns',arg:[2,6]}]; // substitute node 2 in myg4 by node 6 in myg5
    var g=edit(myg4,myg5,l);
    var g_expected={
        g:{n:new Set([1,6,3,4]),e:new Set(['1,6','6,3','3,4','4,6'])},
        c:0
    };

    if(equal(g.g,g_expected.g)!=true || g.c!=g_expected.c) {
        console.log(JSON.stringify(g));
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test edit: node delete, substitute");
    var myg4={n:new Set([1,2,3,4]),e:new Set(['1,2','2,3','3,4','4,2'])};
    var myg5={n:new Set([5,6,7]),e:new Set(['5,6','6,7'])};
    var l=[{op:'nd',arg:[1]},{op:'ns',arg:[2,6]}]; // substitute node 2 in myg4 by node 6 in myg5
    var g=edit(myg4,myg5,l);
    var g_expected={
        g:{n:new Set([6,3,4]),e:new Set(['6,3','3,4','4,6'])},
        c:2
    };

    if(equal(g.g,g_expected.g)!=true || g.c!=g_expected.c) {
        console.log(JSON.stringify(g));
        return 'FAIL';
    } else {
        return 'Pass';
    }
},
function () {
    console.log(" * test edit: complete path");
    var myg4={n:new Set([1,2,3,4]),e:new Set(['1,2','2,3','3,4','4,2'])};
    var myg5={n:new Set([5,6,7]),e:new Set(['5,6','6,7'])};
    var l=[
        {op:'nd',arg:[1]},
        {op:'ns',arg:[2,7]},
        {op:'ns',arg:[3,6]},
        {op:'ns',arg:[4,5]}
    ]; // substitute node 2 in myg4 by node 6 in myg5
    var g=edit(myg4,myg5,l);
    var g_expected={
        g:myg5,
        c:4
    };

    if(equal(g.g,g_expected.g)!=true || g.c!=g_expected.c) {
        console.log(gprint(g));
        return 'FAIL';
    } else {
        return 'Pass';
    }
}
];
console.log("Run tests");
tests.map(function(test) {
    console.log(test());
});
