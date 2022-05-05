(*HW 2*)
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(*Q1*)
let rec combine_rhs gram_rules nsym =
	match gram_rules with
	|[] -> []
	|h::t -> if (fst h) = nsym then [snd h]@(combine_rhs t nsym) else combine_rhs t nsym

let convert_grammar grammar = 
	(fst grammar, combine_rhs (snd grammar))

(*Q2*)
type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal;;

let rec parse_tree_leaves tree = 
	match tree with
	|Node (_, tree_h::tree_tl) -> (parse_tree_leaves tree_h)@(parse_subtrees tree_tl)
	|Leaf tsym -> [tsym]
	|_ -> []
and parse_subtrees subtree =
	match subtree with
	|[] -> []
	|h::t -> (parse_tree_leaves h)@(parse_subtrees t)

(*Q3*)
let rec multdfs rules gramrules accept frag = (*takes a list of symbols*)
	match rules with
	|[] -> None
	|first_rule::rest_rules -> let ormatch = dfs first_rule gramrules accept frag in 
		match ormatch with
		|None -> multdfs rest_rules gramrules accept frag
		|_ -> ormatch
and dfs rule gramrules accept frag =
	match rule with 
	|[]-> accept frag
	|_ -> match frag with
		|[] -> None
		|hfrag::tlfrag -> match rule with 
				|[] -> None (*Need this or pattern matching not exhaustive*)
				|(T tsym)::restsym -> if tsym = hfrag then dfs restsym gramrules accept tlfrag else None
				|(N nsym)::restsym -> multdfs (gramrules nsym) gramrules (fun frag1 -> dfs restsym gramrules accept frag1) frag
				(*need to pass to the acceptor the next set of nonterminals to travers for the and matcher*)

let make_matcher gram accept frag = 
	multdfs [[N (fst gram)]] (snd gram) accept frag

(*Q4*)
let accept_empty_suffix suffix path =
	match suffix with
   | [] -> Some path
   | _ -> None

let rec multdfs_parser rules nonsymbol gramrules path accept frag = (*takes a list of symbols*)
	match rules with
	|[] -> None
	|first_rule::rest_rules -> let ormatch = dfs_parser first_rule nonsymbol gramrules path accept frag in 
		match ormatch with
		|None -> multdfs_parser rest_rules nonsymbol gramrules path accept frag
		|_ -> ormatch
and dfs_parser rule nonsymbol gramrules path accept frag =
	match rule with 
	|[]-> accept frag (Node (nonsymbol, path))
	|_ -> match frag with
		|[] -> None
		|hfrag::tlfrag -> match rule with 
				|[] -> None
				|(T tsym)::restsym -> if tsym = hfrag then dfs_parser restsym nonsymbol gramrules (path@[Leaf tsym]) accept tlfrag else None
				|(N nsym)::restsym -> 
					multdfs_parser (gramrules nsym) nsym gramrules [] (fun frag1 path1-> dfs_parser restsym nonsymbol gramrules (path@[path1]) accept frag1) frag

let make_parser grammar frag =
	multdfs_parser ((snd grammar) (fst grammar)) (fst grammar) (snd grammar) [] accept_empty_suffix frag
