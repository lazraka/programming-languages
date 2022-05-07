# Naive parsing of context free grammars

###### basic_functions
The goal is to exploit the capabalities of OCaml, notably recursion by write a function "filter_reachable" that returns a copy of a grammar with all unreachable rules removed.

###### grammar_parser
The goal is to write a simple parser generator when given a grammar, the program will generate a function that is a parser. When this parser is given a string whose prefix is a program to parse, it returns the corresponding unmatched suffix, or an error indication if no prefix of the string is a valid program. It includes a matcher which is a function that inspects a given string of terminals to find a match for a prefix that corresponds to a nonterminal symbol of a grammar, and then checks whether the match is acceptable by testing whether a given acceptor succeeds on the corresponding suffix.
