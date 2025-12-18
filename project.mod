reset;

param n_players; # number of players and dots
param n_moves; # Number of moves. n_forms = M + 1
param n_sections; # Number of sections

set F; # Forms (n_moves+1, "Sets" in marching band terminology)
set M within F; # Moves (n_moves. Move m goes from form m to form m+1)
set P; # Players (n_players)
set S; # Sections (n_sections)
set D; # Dots (n_players)
set P_S{S} within P; # Players in each section

param l{s in D, e in D, m in M} >= 0; # distance between each pair of dots from move m-1 to move m
param r{d in D, dp in D, f in F} >= 0; # distance between each pair of dots in form f
# I don't think x and y coordinates of dots?

param d_weight >= 0; # weight for distance between players in objective function
# ^^ We could index this on section to weight some sections more heavily

var x{b in D, e in D, m in M, p in P} binary; # 1 if player p goes from dot b goes to dot e from form m to form m+1
var d{s in S, f in F} >= 0; # distance between players in section s in form f

minimize movement_and_spacing:
    sum{m in M, b in D, e in D, p in P} l[b,e,m] * x[b,e,m,p]
    + d_weight * sum{s in S, f in F} d[s,f];

s.t. one_move_per_player{p in P, m in M}:
    sum{b in D, e in D} x[b,e,m,p] = 1;