/* Number of vertexes, edges, dispositions */
param V_count, integer, >= 0;
param E_count, integer, >= 0;
param D_count, integer, >= 0;

/* Sets of vertexes, edges and dispositions */
set V, default {0..V_count};
set E, default {1..E_count};
set D, default {1..D_count};

/* Requirements */
param h{d in D} >= 0;
param s{d in D} >= 0;
param t{d in D} >= 0;

/* Aev, Bev as params */
param A{e in E, v in V}, >= 0, default 0;
param B{e in E, v in V}, >= 0, default 0;

/* KSI xD */
param KSI{e in E} >= 0;

/* Decision variables */
var x{e in E, d in D} >= 0;

/* Objective function 'z' */
minimize z: sum{e in E, d in D} KSI[e]*x[e,d];

/* Constraints */
s.t. c1{d in D, v in V : v == s[d]} : sum{e in E} (A[e,v]*x[e,d] - B[e,v]*x[e,d]) == h[d];
s.t. c2{d in D, v in V : v <> s[d] and v <> t[d]} : sum{e in E} (A[e,v]*x[e,d] - B[e,v]*x[e,d]) == 0;
s.t. c3{d in D, v in V : v == t[d]} : sum{e in E} (A[e,v]*x[e,d] - B[e,v]*x[e,d]) == -h[d];

end;

