# Scheme code difference analyzer

###### Project Specifications
- Prototype a procedure expr-compare that compares two Scheme expressions x and y, and produces a difference summary of where the two expressions are the same and where they differ.
- Design the difference summary to also be a Scheme expression which, if executed in an environment where the Scheme variable % is true, has the same behavior as x, and otherwise has the same behavior as y.
- Build a shorter summary expression uses λ in places where one input expression uses a lambda expression and the other used a λ expression
- The input is limited to the subset of expressions that consists of literal constants, identifiers, and function calls
