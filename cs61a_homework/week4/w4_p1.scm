(define (substitute list_fp old_word new_word)
	(define (replace sent)
		(cond ((empty? sent) '())
			  ((list? (car sent)) (list (replace (car sent))))
			  ((equal? old_word (car sent)) (cons new_word (replace (bf sent))))
			  (else (cons (first sent) (replace (cdr sent))))))
	(define (substitute-helper list_fp replaced-list old_word new_word)
		(if (empty? list_fp)
			(apply append (reverse replaced-list))
			(substitute-helper
				(cdr list_fp)
				(cons (replace (list (car list_fp))) replaced-list)
				old_word
				new_word)))
	(substitute-helper list_fp '() old_word new_word))
	
(define l '((lead guitar) (bass guitar) (rhythm guitar) drums))