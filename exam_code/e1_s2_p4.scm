(define (every-nth n sen)
	(define (e-n-h sen counter)
		(cond ((empty? sen) '())
			  ((equal? n counter) (se (first sen) (e-n-h (bf sen) 1)))
			  (else (e-n-h (bf sen) (+ 1 counter)))))
    (e-n-h sen 1))