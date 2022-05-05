#lang racket
(provide (all-defined-out))

(define (expr-compare x y)
	(cond [(equal? x y) x]
		[(and (boolean? x) (boolean? y)) (cond [(equal? x y) x] [x '%] [y '(not %)])]
		[(or (not (list? x)) (not (list? y))) (list 'if '% x y)]
		[(or (empty? x) (empty? y)) '()]
		[(and (list? x) (list? y)) (cond [(not (= (length x) (length y))) (list 'if '% x y)]
										[#t (compare-heads x y)])]
	)
)
;if have list, must differ to further functions to check all cases
(define (compare-heads x y)
	(let ([xhead (car x)]
			[xtail (cdr x)]
			[yhead (car y)]
			[ytail (cdr y)])
	(cond [(or (equal? xhead 'quote) (equal? yhead 'quote)) (list 'if '% x y)]
		[(and (boolean? xhead) (boolean? yhead)) (cons (if xhead '% '(not %)) (compare-heads xtail ytail))]
		[(and (equal? xhead 'if) (equal? yhead 'if)) (compare-lists x y)]
		[(or (equal? xhead 'if) (equal? yhead 'if)) (list 'if '% x y)]
		[(and (equal? xhead 'λ) (equal? yhead 'λ)) (if (not (= (length (car xtail)) (length (car ytail)))) (list 'if '% x y) (compare-lambda xtail ytail 'λ))]
		[(and (equal? xhead 'lambda) (equal? yhead 'lambda)) (if (not (= (length (car xtail)) (length (car ytail)))) (list 'if '% x y) (compare-lambda xtail ytail 'lambda))]		
		[(and (lambda? xhead) (lambda? yhead)) (if (not (= (length (car xtail)) (length (car ytail)))) (list 'if '% x y) (compare-lambda xtail ytail 'λ))]
		[(or (lambda? xhead) (lambda? yhead)) (list 'if '% x y)]
		[#t (compare-lists x y)])
	))

(define (compare-lists x y)
	(if (and (empty? x) (empty? y)) '()
		(let ([xhead (car x)]
			[xtail (cdr x)]
			[yhead (car y)]
			[ytail (cdr y)])
		(cond
			[(equal? xhead yhead) (cons yhead (compare-lists xtail ytail))]
			[(and (boolean? xhead) (boolean? yhead)) (cons (if xhead '% '(not %)) (compare-lists xtail ytail))]
			[(and (list? xhead) (list? yhead)) 
				(cond 
					[(not (= (length xhead) (length yhead))) (cons (list 'if '% xhead yhead) (compare-heads xtail ytail))]
					[#t (cons (compare-heads xhead yhead) (compare-lists xtail ytail))])]
			[#t (cons (list 'if '% xhead yhead) (compare-lists xtail ytail))]
			)
		)
	)
)

;This function was taken from the TA hint code
(define (lambda? x)
  (member x '(lambda λ)))

(define (lambda-list? x)
    (and (list? x) (equal? (length x) 3) (member (car x) '(lambda λ)))
  ;if list length does not equal 3, it does not pass the test case of recursion from TA code
)

(define (compare-lambda x y lamsym)
	(let ([args-x (car x)]
		[args-y (car y)])
		(cond [(not (= (length args-x) (length args-y))) (list 'if '% x y)]
				[(equal? args-x args-y) (cons lamsym (cons args-x (list (expr-compare (list-ref x 1) (list-ref y 1)))))]
				[#t (let ([new-args (replace-lambda-args args-x args-y)] [dict-list (build-dict args-x args-y)])
					(cons lamsym (list new-args (expr-compare (replace-x dict-list (list-ref x 1)) (replace-y dict-list (list-ref y 1))))
						)
					)]
			)
		)
	)

(define (replace-lambda-args x-param y-param)
	(if (or (empty? x-param) (empty? y-param)) '()
		(let ([xhead (car x-param)] [xtail (cdr x-param)]
			[yhead (car y-param)] [ytail (cdr y-param)])
		(cond
			[(equal? xhead yhead) (cons yhead (replace-lambda-args xtail ytail))]
			[#t (let ([new-bindings (bind-vars xhead yhead)])
						(cons new-bindings (replace-lambda-args xtail ytail)))]
			)
		)
	)
)

(define (build-dict x-param y-param)
	(if (or (empty? x-param) (empty? y-param)) '()
		(let ([xhead (car x-param)] [xtail (cdr x-param)]
				[yhead (car y-param)] [ytail (cdr y-param)])
			(cond
				[(equal? xhead yhead) (build-dict xtail ytail)]
				[#t (let ([new-bindings (bind-vars xhead yhead)])
					(cons (list xhead yhead new-bindings) (build-dict xtail ytail)))]))))

(define (replace-x bindings-list x)
	(cond [(empty? bindings-list) x]
			[#t (let ([bindings-list-head (car bindings-list)])
				(replace-x (cdr bindings-list) (replace-lambda-body (car bindings-list-head) (list-ref bindings-list-head 2) x)))]
		)		;the new x with the body replaced will be sent to the x param in a recursive call										
	)

(define (replace-y bindings-list y)
	(cond [(empty? bindings-list) y]
			[#t (let ([bindings-list-head (car bindings-list)])
				(replace-y (cdr bindings-list) (replace-lambda-body (cadr bindings-list-head) (list-ref bindings-list-head 2) y)))]
		)
	)

(define (replace-lambda-body old new expr)
	(cond [(empty? expr) '()]
			[(not (list? expr)) (if (equal? old expr) new expr)]
			[(equal? (car expr) 'quote) expr]
			;this is the case where the expression is a list, must check for nested-lambda
			[#t (let ([nested-expr (car expr)]) 
				(if (list? nested-expr) (if (lambda-list? nested-expr) (cons (handle-nested old new nested-expr) (replace-lambda-body old new (cdr expr)))
											 (cons (replace-lambda-body old new nested-expr) (replace-lambda-body old new (cdr expr))))
										(if (equal? old nested-expr) (cons new (replace-lambda-body old new (cdr expr))) 
											(cons nested-expr (replace-lambda-body old new (cdr expr))))))]
		)
	)
		
(define (handle-nested old new expr)
    (let ([new-body (list-ref expr 2)])
        (cond
            [(or (equal? old (list-ref expr 1))
                (member old (list-ref expr 1))) expr] ;if don't use list-ref, the parentheses do not add up
            [(not (list? new-body)) (cons (car expr) (list (cadr expr) (replace-lambda-body old new new-body)))]
            [#t (cons (car expr) (replace-lambda-body old new (cdr expr)))]
        )
    )
)

(define (bind-vars x y) (string->symbol (string-append (symbol->string x) "!" (symbol->string y))))

;compare-lambda-params, sends the bindings to the body
;compare-lambda-body, takes in the arguments and the dictionary, and populates the body with the bindings

;This function is adapted from the TA hintcode
(define (test-expr-compare x y)
  (and (equal? (eval x) (eval (list 'let '([% #t]) (expr-compare x y))))
       (equal? (eval y) (eval (list 'let '([% #f]) (expr-compare x y))))
    )
  )

(define test-expr-x '(cons (if #t ((lambda (a b) (+ ((lambda (g) (- g 1)) a) b)) 1 2) 4) (quote (1 1))))
(define test-expr-y '(cons (if #f ((λ      (a c) (+ ((lambda (g) (+ g 1)) a) c)) 1 2) 3) '(1 1)))

