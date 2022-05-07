# Naive parsing of context free grammars

Write a function filter_reachable g that returns a copy of the grammar g with all unreachable rules removed. This function should preserve the order of rules: that is, all rules that are returned should be in the same order as the rules in g.
Given a grammar your program will generate a function that is a parser. When this parser is given a string whose prefix is a program to parse, it returns the corresponding unmatched suffix, or an error indication if no prefix of the string is a valid program.
A matcher is a function that inspects a given string of terminals to find a match for a prefix that corresponds to a nonterminal symbol of a grammar, and then checks whether the match is acceptable by testing whether a given acceptor succeeds on the corresponding suffix.
