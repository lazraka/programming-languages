# Scheme code difference analyzer
prototype a procedure expr-compare that compares two Scheme expressions x and y, and produces a difference summary of where the two expressions are the same and where they differ.
So you decide to have the difference summary also be a Scheme expression which, if executed in an environment where the Scheme variable % is true, has the same behavior as x, and otherwise has the same behavior as y.
shorter summary expression, so you decide that the summary should use λ in places where one input expression used a lambda expression and the other used a λ expression
limited to the subset of expressions that consists of literal constants, identifiers, function calls, the special form
