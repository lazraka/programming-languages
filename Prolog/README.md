# KenKen Solver

KenKen is an arithmetical-logical puzzle whose goal is to fill in an N×N grid with integers where every row and every column contains all the integers from 1 through N and extra constraints are also met. These extra constraints are specified by cages that say that 1 or more contiguous cells must add up to a certain value, or must yield a certain value when multiplied or that two cells must yield a certain value when divided or subtracted.

###### Project specifications
1. Write a predicate kenken/3 that accepts the following arguments:
- N, a nonnegative integer specifying the number of cells on each side of the KenKen square.
- C, a list of numeric cage constraints as described below.
- T, a list of list of integers. All the lists have length N. This represents the N×N grid.

2. Write a predicate plain_kenken/3 that acts like kenken/3 but does not use the GNU Prolog finite domain solver.
3. Illustrate the performance difference on an example.
