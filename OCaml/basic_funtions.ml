(*HW 1*)

(*Q1*)
(*let subset a b = List.mem a b*) (*Error: This expression has type int but an expression was expected of type 'a list*)
let subset a b = List.for_all (fun x -> List.mem x b) a

(*Q2*)
(*let equal_sets a b = mem a b && mem b a*)
let equal_sets a b = List.for_all (fun x -> List.mem x b) a && List.for_all (fun x -> List.mem x a) b

(*Q3*)
let set_union a b = List.append a b (* returns duplicates *)

(*Q4*)
(*a represents set of sets, use Q3 and list module, one liner*)
let set_all_union a = List.fold_left set_union [] a

(*Q5*)
(*A potential way to write the function would be the following: let self_member s = List.exists (fun x -> List.mem x s) s *)
(*Yet this function in OCaml would always return false on a set (represented as a list) that is not a member of itself and a type error 
  when testing for a set that is a member of itself which would have to be self referencing. This occurs because OCaml is statically
  typed language where lists elements must all have the same type therefore self-referencing cannot occur in lists.*)

(*Q6*)
(*3 parameters to function, keep calling f on c until it converges on a fixed point*)
let rec computed_fixed_point eq f x = if eq (f x) x then x else computed_fixed_point eq f (f x)

(*Q7*)
(*Perform graph search to remove unreachable nodes*)

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(* let awksub_grammar = Expr, awksub_rules - this is tuple with first element = start symbol and second element = rules *)

let rec filter_terms lst =
	match lst with
	|[] -> []
	|h::t -> match h with
		|T term -> filter_terms t
		|N nonterm -> nonterm::(filter_terms t)

let rec find_nonterms (n_sym, trav_rules) =
	match trav_rules with
	|[] -> [n_sym]@[]
	|hd::tl -> match hd with
		|(non_sym, rhs) -> if non_sym = n_sym then (filter_terms rhs)@(find_nonterms (n_sym, tl)) else find_nonterms (n_sym, tl);;

let rec follow_nonterms trav_rules n_lst = (*without tuple argument, can use partial application*)
	match n_lst with
	|[]-> []
	|h_sym::t_sym -> find_nonterms (h_sym, trav_rules)@(follow_nonterms trav_rules t_sym)

let filter_reachable (start_sym, rules) =
	let follow_grammar = follow_nonterms rules in (*attempt a partial application but not sure with tuple*)
	let reached_rules = computed_fixed_point equal_sets follow_grammar [start_sym] in
	(start_sym, (List.filter (fun x -> List.mem (fst x) reached_rules) rules));;

	 
