%------------------------KenKen------------------------
kenken(N,C,T):-
    % array size limits
    len_row(T, N),
    len_col(T, N),

    % finite domain limits
    within_domain(T, N),
    maplist(fd_all_different, T),

    transpose(T, Tt),
    maplist(fd_all_different, Tt),

    %check the constraints left
    check_constraint_list(C,T), 

    maplist(fd_labeling, T).

%------------------------KenKen helper functions------------------------

% The following functions were taken from sudoku_cell hint code
len_row(X, N) :-
    length(X, N).

len_col([], _).
len_col([HD | TL], N) :-
    length(HD, N),
    len_col(TL, N).

within_domain([], _).
within_domain([HD | TL], N) :-
    fd_domain(HD, 1, N),
    within_domain(TL, N).

transpose([], []).
transpose([F|Fs], Ts) :-
    transpose(F, [F|Fs], Ts).

transpose([], _, []).
transpose([_|Rs], Ms, [Ts|Tss]) :-
        lists_firsts_rests(Ms, Ts, Ms1),
        transpose(Rs, Ms1, Tss).

lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
        lists_firsts_rests(Rest, Fs, Oss).


%The following functions are written by the student
check_constraint_list([],T).
check_constraint_list([Hd|Tl],T):-
    check_constraint(Hd,T),
    check_constraint_list(Tl,T).

%get nth element ie ith row and jth column
element([Row|Col], T, Element):-
    nth(Row, T, Lrow), 
    nth(Col, Lrow, Element).

%base cases: addition = 0, multiplication = 1
check_sum([], T, 0).
check_sum([Sumhd|Sumtl], T, Sum):-
    element(Sumhd,T,Ele),
    check_sum(Sumtl, T, Tmpsum),
    Sum #= Tmpsum+Ele.

check_product([], T, 1).
check_product([Prodhd|Prodtl], T, Prod):-
    element(Prodhd,T,Ele),
    check_product(Prodtl, T, Tmpprod),
    Prod #= Tmpprod*Ele.

check_difference(Sq1,Sq2, T, Diff):-
    element(Sq1,T,Ele1),
    element(Sq2,T,Ele2),
    Diff #= Ele1-Ele2.

check_quotient(Sq1,Sq2, T, Quot):-
    element(Sq1, T, Ele1),
    element(Sq2, T, Ele2),
    Quot #= Ele1/Ele2.

%constraints that need to be met: plus, minus, multiply, divide
check_constraint(+(S,L), T):- 
    check_sum(L, T, S).

check_constraint(*(P,L), T):- 
    check_product(L, T, P).

check_constraint(-(D,A,K), T):-
    check_difference(A, K, T, D);
    check_difference(K, A, T, D).

check_constraint(/(Q,B,K), T):-
    check_quotient(B, K, T, Q);
    check_quotient(K, B, T, Q).


%----------------------Plain KenKen--------------------
plain_kenken(N,C,T):-
    create_grid(T, N, C).

%----------------------Plain KenKen helper functions--------------------
create_grid(Grid,N,C):-
  length(Grid, N),
  fill_2d_row(N,Grid),
  check_constraint_list_plain(C,Grid),
  transpose(Grid,Gridtrans),
  maplist(all_unique,Gridtrans).

% This function was taken from plain_domain hint code
within_domain_plain(N, Domain) :- 
    findall(X, between(1, N, X), Domain).

all_unique([]).
all_unique([H|T]):-
    member(H,T),!,fail.
all_unique([H|T]):-
    all_unique(T).

%The following function was adapted from plain_domain hint code and modified
fill_2d_row(_, []).
fill_2d_row(N, [Hd|Tl]):-
    length(Hd, N),
    within_domain_plain(N, Domain),
    permutation(Domain, Hd),
    all_unique(Hd),
    %then recurse
    fill_2d_row(N, Tl).

%The following functions are written by the student
check_constraint_list_plain([],T).
check_constraint_list_plain([Hd|Tl],T):-
    check_constraint_plain(Hd,T),
    check_constraint_list_plain(Tl,T).

check_sum_plain([], T, 0).
check_sum_plain([Sumhd|Sumtl], T, Sum):-
    element(Sumhd,T,Ele),
    check_sum_plain(Sumtl, T, Tmpsum),
    Sum is (Tmpsum+Ele).

check_product_plain([], T, 1).
check_product_plain([Prodhd|Prodtl], T, Prod):-
    element(Prodhd,T,Ele),
    check_product_plain(Prodtl, T, Tmpprod),
    Prod is (Tmpprod*Ele).

check_difference_plain(Sq1,Sq2, T, Diff):-
    element(Sq1,T,Ele1),
    element(Sq2,T,Ele2),
    Diff is (Ele1-Ele2).

check_quotient_plain(Sq1,Sq2, T, Quot):-
    element(Sq1, T, Ele1),
    element(Sq2, T, Ele2),
    Quot =:= Ele1/Ele2.

%constraints that need to be met: plus, minus, multiply, divide
check_constraint_plain(+(S,L), T):- 
    check_sum_plain(L, T, S).

check_constraint_plain(*(P,L), T):- 
    check_product_plain(L, T, P).

check_constraint_plain(-(D,A,K), T):-
    check_difference_plain(A, K, T, D);
    check_difference_plain(K, A, T, D).

check_constraint_plain(/(Q,B,K), T):-
    check_quotient_plain(B, K, T, Q);
    check_quotient_plain(K, B, T, Q).


%------------------------KenKen test cases------------------------
kenken_testcase(
  6,
  [
   +(11, [[1|1], [2|1]]),
   /(2, [1|2], [1|3]),
   *(20, [[1|4], [2|4]]),
   *(6, [[1|5], [1|6], [2|6], [3|6]]),
   -(3, [2|2], [2|3]),
   /(3, [2|5], [3|5]),
   *(240, [[3|1], [3|2], [4|1], [4|2]]),
   *(6, [[3|3], [3|4]]),
   *(6, [[4|3], [5|3]]),
   +(7, [[4|4], [5|4], [5|5]]),
   *(30, [[4|5], [4|6]]),
   *(6, [[5|1], [5|2]]),
   +(9, [[5|6], [6|6]]),
   +(8, [[6|1], [6|2], [6|3]]),
   /(2, [6|4], [6|5])
  ]
).

kenken_mytestcase_5(5,[+(5, [[1|1],[2|1]]), *(15, [[1|2],[1|3]]), -(3, [1|4],[1|5]), /(2, [2|2], [2|3]), -(4, [2|4],[2|5]), 
   *(20, [[3|1],[4|1]]),*(12,[[3|2],[3|3],[4|2]]),*(12,[[3|4],[4|4],[4|5]]),/(2, [4|3], [5|3]),+(6, [[5|1],[5|2]]),-(1, [5|4],[5|5])],T).


