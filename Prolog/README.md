# KenKen Solver

is an arithmetical-logical puzzle whose goal is to fill in an N×N grid with integers, so that every row and every column contains all the integers from 1 through N, and so that certain extra constraints can be met. These extra constraints are specified by cages that say that 1 or more contiguous cells must add up to a certain value, 
or must yield a certain value when multiplied; or that two cells must yield a certain value when divided or subtracted.

write a predicate kenken/3 that accepts the following arguments:

N, a nonnegative integer specifying the number of cells on each side of the KenKen square.
C, a list of numeric cage constraints as described below.
T, a list of list of integers. All the lists have length N. This represents the N×N grid.

Second, write a predicate plain_kenken/3 that acts like kenken/3 but does not use the GNU Prolog finite domain solver.

Although plain_kenken/3 should be simpler than kenken/3 and should not be restricted to integers less than vector_max, the tradeoff is that it may have worse performance. 
Illustrate the performance difference on an example of your choice,
