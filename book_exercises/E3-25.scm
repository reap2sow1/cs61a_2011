(define (make-table)
	(let ((local-table (list '*table*)))
		(define (lookup entity keys local-local-table)
			(if (equal? keys '())
				(if (equal? entity '())
					false
					(cdr entity))
				(if (equal? (cdr keys) '())
					(let ((new-entity (assoc (car keys) (cdr local-local-table))))
						(if new-entity ; --> record exists
							(lookup new-entity (cdr keys) local-local-table)
							false))
					(let ((new-entity (assoc (car keys) (cdr local-local-table))))
						(if new-entity ; --> sub-table exists
							(lookup '() (cdr keys) new-entity)
							false)))))
		(define (insert! entity value keys local-local-table)
			(let ((new-entity (assoc (car keys) (cdr local-local-table))))
				(if (equal? (cdr keys) '()) ; if true --> then we have a record, not a subtable at this point
					(if new-entity
						(begin (set-cdr! new-entity value) local-local-table)
						(begin (set-cdr! local-local-table (cons (cons (car keys) value) (cdr local-local-table))) local-local-table))
					(if new-entity ; --> we have a subtable, but does it exist? Getting to this points assumes x number of dimensions of tables
						(set-cdr! local-local-table (cons (insert! '() value (cdr keys) new-entity) (cdr local-local-table)))
						(set-cdr! local-local-table (cons (insert! '() value (cdr keys) (list (car keys))) (cdr local-local-table)))))))
		;;(trace insert!)
		(define (dispatch m)
			(cond ((eq? m 'lookup-proc) (lambda (keys) (lookup '() keys local-table)))
				  ((eq? m 'insert-proc!) (lambda (value keys) (if (equal? keys '()) (error "You need at least 1 key to insert into the table") (insert! '() value keys local-table))))
				  (else (error "Unknown operation: TABLE" m))))
			dispatch))
			
			
(define (insert! table value . keys) ; user interfaces should have the duty of making sure numerous keys can come in
	((table 'insert-proc!) value keys))

(define (lookup table . keys)
	((table 'lookup-proc) keys))
	
(define t1 (make-table))
(insert! t1 5 'number1)
(insert! t1 6 'number2)
(insert! t1 7 'number3)
(insert! t1 88 'double-d 'number5)
(insert! t1 99 'double-d 'number6)