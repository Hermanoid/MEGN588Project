reset;

param n_players; # number of players and dots
param n_moves; # Number of moves. n_forms = M + 1
param n_sections; # Number of sections

set F ordered; # Forms (n_moves+1, "Sets" in marching band terminology)
set M within F ordered; # Moves (n_moves. Move m goes from form m to form m+1)
set P; # Players (n_players)
set S; # Sections (n_sections)
set D; # Dots (n_players)
set P_S{S} within P; # Players in each section

param l{m in M, b in D, e in D} >= 0; # distance between each pair of dots from move m-1 to move m
param r{f in F, d1 in D, d2 in D} >= 0; # distance between each pair of dots in form f
# I don't think x and y coordinates of dots?

param d_weight >= 0; # weight for distance between players in objective function
# ^^ We could index this on section to weight some sections more heavily

var x{m in M, p in P, b in D, e in D} binary; # 1 if player p goes from dot b goes to dot e from form m to form m+1
var d{f in F, s in S} >= 0; # distance between players in section s in form f

minimize movement_and_spacing:
    sum{m in M, b in D, e in D, p in P} l[m,b,e] * x[m,p,b,e]
    + d_weight * sum{f in F, s in S} card(P_S[s]) * d[f,s];


s.t. each_player_must_have_one_move{m in M, p in P}:
    sum{b in D, e in D} x[m,p,b,e] = 1;

# I think this is unnecessary/effectively a cut?
# s.t. all_players_move{m in M}:
#     sum{b in D, e in D, p in P} x[b,e,m,p] = n_players;

# Assert that each dot is filled on a per-form basis.
# The variable is defined over form transitions, so define it using the starting point for each move
# The end point should be the start for the next move by a later constraint.
s.t. one_player_per_dot_starts{m in M, b in D}:
    sum{e in D, p in P} x[m,p,b,e] = 1;

# Could we add a "cut" by including the same as above, but Ends?
# I think in conjunction with the "player flow" constraint this would be redundant

# Using the start of each transition for the dot-filled constraint leaves the last one.
# Use the end of the last transition to cover the last form.
s.t. one_player_per_dot_last{e in D}:
    sum{b in D, p in P} x[last(M),p,b,e] = 1;

# A player entering a "node" (dot) must leave it in the next move.
s.t. player_flow{m in M, p in P, dot in D: ord(m) < card(M)}:
    sum{b in D} x[m,p,b,dot] = sum{e in D} x[next(m),p,dot,e];

# If the next constraint was normal programming, it would seven levels of for-loops!
# Fortunately the section list and list of players in each section is ~sqrt the number of dots, which should help some with complexity.

# For each pair of players in the section, if a within-form edge involves *both* players, 
# we want to bound the section distance by that edge's length.
# So for move m, we're going to look at the *starting* dots for that move (so move m = form m. We'll handle form m+1 in a sec)
# ... and for each section, and for each pair of dots in that section (d1<d2 to avoid double counting)
# ... we'll consider bounding the section's diameter by that edge length IF the two dots in question are occupied by same section.
# We detect same-section as:
# - Sum over all players in that section and all *other* players in that section (this just reduces the number of constraints by a little, 
#           but it's not strictly necessary since the same player can't occupy two dots at once by an earlier constraint)
# - Sum over all endpoints of the start dots (necessary to detect if a player is in a dot under our transition-based indexing)
# - If player one is in dot d1 and player two is in dot d2, then the sum will be exactly 2, so -1 will create a positive lower bound
# - If only one player is in a dot, the sum will be 1 and the lower bound will be zero (thrown away)
# - Similarly the LB will be negative if neither player is in a dot (also thrown away)
s.t. section_diameter_starts{m in M, s in S, d1 in D, d2 in D: d1<d2}:
    d[m,s] >= r[m,d1,d2] * (sum{p1 in P_S[s]} sum{p2 in P_S[s]: p1 != p2} sum{e in D} (x[m,p1,d1,e] + x[m,p2,d2,e]) - 1);

# The same thing but for the last form (endpoints of the last move)
# So we sum over the starts for each edge to detect dot membership
s.t. section_diameter_last{s in S, d1 in D, d2 in D: d1<d2}:
    d[last(F),s] >= r[last(F),d1,d2] * (sum{p1 in P_S[s]} sum{p2 in P_S[s]: p1 != p2} sum{b in D} (x[last(M),p1,b,d1] + x[last(M),p2,b,d2]) - 1);