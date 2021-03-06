;; ADV.SCM
;; This file contains the definitions for the objects in the adventure
;; game and some utility procedures.

(define-class (basic-object name)
	(instance-vars (properties (make-table)))
	(method (put key value)
		(insert! key value properties))
	(default-method (lookup message properties)))

(define-class (place name)
  (parent (basic-object name))
  (instance-vars
   (directions-and-neighbors '())
   (things '())
   (people '())
   (entry-procs '())
   (exit-procs '()))
  (method (type) 'place)
  (method (neighbors) (map cdr directions-and-neighbors))
  (method (exits) (map car directions-and-neighbors))
  (method (look-in direction)
    (let ((pair (assoc direction directions-and-neighbors)))
      (if (not pair)
	  '()                     ;; nothing in that direction
	  (cdr pair))))           ;; return the place object
  (method (appear new-thing)
    (if (memq new-thing things)
	(error "Thing already in this place" (list name new-thing)))
    (set! things (cons new-thing things))
    'appeared)
  (method (enter new-person)
    (if (memq new-person people)
	(error "Person already in this place" (list name new-person)))
    (set! people (cons new-person people))
	(for-each (lambda (person) (if (not (eq? person new-person)) (ask person 'notice new-person))) people)
    (for-each (lambda (proc) (proc)) entry-procs)
    'appeared)
  (method (gone thing)
    (if (not (memq thing things))
	(error "Disappearing thing not here" (list name thing)))
    (set! things (delete thing things)) 
    'disappeared)
  (method (exit person)
    (for-each (lambda (proc) (proc)) exit-procs)
    (if (not (memq person people))
	(error "Disappearing person not here" (list name person)))
    (set! people (delete person people)) 
    'disappeared)

  (method (new-neighbor direction neighbor)
    (if (assoc direction directions-and-neighbors)
	(error "Direction already assigned a neighbor" (list name direction)))
    (set! directions-and-neighbors
	  (cons (cons direction neighbor) directions-and-neighbors))
    'connected)
	
  (method (may-enter? person) #t)

  (method (add-entry-procedure proc)
    (set! entry-procs (cons proc entry-procs)))
  (method (add-exit-procedure proc)
    (set! exit-procs (cons proc exit-procs)))
  (method (remove-entry-procedure proc)
    (set! entry-procs (delete proc entry-procs)))
  (method (remove-exit-procedure proc)
    (set! exit-procs (delete proc exit-procs)))
  (method (clear-all-procs)
    (set! exit-procs '())
    (set! entry-procs '())
    'cleared) )

(define-class (person name place)
  (parent (basic-object name))
  (instance-vars
   (possessions '())
   (saying "")
   (money 100))
  (initialize
   (ask self 'put 'strength 50)
   (ask place 'enter self))
  (method (type) 'person)
  (method (get-money amount)
	(begin (set! money (+ money amount)) money))
  (method (pay-money amount)
	(if (> 0 (- money amount))
		#f
		(begin (set! money (- money amount)) #t)))
  (method (buy food-person-wants)
	(let ((food (ask place 'sell self food-person-wants)))
		(if food
			(set! possessions (cons food possessions)))))
  (method (eat)
	(set! possessions (flatmap
						(lambda (item) 
							(if (ask item 'edible?)
								(begin 
									(ask (ask self 'place) 'gone item) 
									(ask self 'put 'strength (+ (ask self 'strength) (ask item 'calories)))
									(ask item 'change-possessor 'no-one)
									'())
								(list item)))
								possessions)))
  (method (look-around)
    (map (lambda (obj) (ask obj 'name))
	 (filter (lambda (thing) (not (eq? thing self)))
		 (append (ask place 'things) (ask place 'people)))))
  (method (go-directly-to new-place)
	     (ask (ask self 'place) 'exit self)
	     (announce-move name (ask self 'place) new-place)
	     (for-each
	      (lambda (p)
		(ask (ask self 'place) 'gone p)
		(ask new-place 'appear p))
	      possessions)
	     (set! place new-place)
	     (ask new-place 'enter self))
  (method (take-all)
	(let ((things-not-owned 
			(flatmap (lambda (thing) (if (eq? (owner thing) 'no-one) (list thing) '())) (ask place 'things))))
		(map (lambda (thing) (ask self 'take thing)) things-not-owned)) 'all-taken)
  (method (take thing)
    (cond ((not (thing? thing)) (error "Not a thing" thing))
	  ((not (memq thing (ask place 'things)))
	   (error "Thing taken not at this place"
		  (list (ask place 'name) thing)))
	  ((memq thing possessions) (error "You already have it!"))
	  (else
	  
	   ;; If somebody already has this object...
		(let ((possessor (ask thing 'possessor)))
			(if (not (equal? 'no-one possessor))
				(if (ask thing 'may-take? self)
					(begin 
						(ask possessor 'lose thing) 
						(ask thing 'change-possessor self) 
						(have-fit possessor)
						(announce-take name thing)
						(set! possessions (cons thing possessions)))
					(format #t "~A is to strong!~%" (ask possessor 'name)))
				(begin 
					(announce-take name thing)
					(set! possessions (cons thing possessions))
					(ask thing 'change-possessor self))))
	   )))

  (method (lose thing)
    (set! possessions (delete thing possessions))
    (ask thing 'change-possessor 'no-one)
    'lost)
  (method (talk) (print saying))
  (method (set-talk string) (set! saying string))
  (method (exits) (ask place 'exits))
  (method (notice person) (ask self 'talk))
  (method (go direction)
    (let ((new-place (ask place 'look-in direction)))
      (cond ((null? new-place)
				(error "Can't go" direction))
		 ((not (ask new-place 'may-enter? self))
				(error "Place is locked -- " (ask new-place 'name)))
	    (else
	     (ask place 'exit self)
	     (announce-move name place new-place)
	     (for-each
	      (lambda (p)
		(ask place 'gone p)
		(ask new-place 'appear p))
	      possessions)
	     (set! place new-place)
	     (ask new-place 'enter self))))) )   
	   
(define-class (thing name)
	(parent (basic-object name))
	(instance-vars (possessor 'no-one))
	(method (type) 'thing)
	(method (may-take? receiver)
		(let ((possessor (ask self 'possessor)))
			(if (> (ask receiver 'strength) (ask possessor 'strength))
				self
				#f)))
	(method (change-possessor new-possessor)
		(set! possessor new-possessor)
		'okay)
	(default-method (error "Bad message to class: " message)))
	
(define-class (laptop name)
	(parent (thing name))
	(method (type) 'laptop)
	(method (connect password)
		(let ((owner (ask self 'possessor)))
			(if (eq? 'no-one owner) 
				(error "No one is manning this laptop " (ask self 'name))
				(let ((hotspot (ask (ask self 'possessor) 'place)))
				  (if (not (hotspot? hotspot)) 
					(error "This place has no wifi " (ask hotspot 'name))) 
					(ask hotspot 'connect self password)))))
	(method (surf url)
		(let ((owner (ask self 'possessor)))
			(if (eq? 'no-one owner) 
				(error "No one is manning this laptop " (ask self 'name))
				(let ((hotspot (ask (ask self 'possessor) 'place)))
				  (cond ((not (hotspot? hotspot)) (error "This place has no wifi " (ask hotspot 'name))) 
						((memq self (ask hotspot 'connected-laptops)) (system (string-append "lynx " url)))
						(else (error "You are not connected to this hotspot " (ask hotspot 'name))))))))
	(method (disconnect)
		(let ((owner (ask self 'possessor)))
			(if (eq? 'no-one owner) 
				(error "No one is manning this laptop " (ask self 'name))
				(let ((hotspot (ask (ask self 'possessor) 'place)))
				  (if (not (hotspot? hotspot)) 
					(error "This place has no wifi " (ask hotspot 'name))) 
					(ask hotspot 'disconnect self))))))

(define-class (hotspot name password)
	(parent (place name))
	(instance-vars (connected-laptops '()))  
	(method (type) 'hotspot)
	(method (connect laptop guessing-password)
		(cond ((memq laptop connected-laptops) (error "Already connected " (ask laptop 'name)))
			  ((eq? password guessing-password) (begin (set! connected-laptops (cons laptop connected-laptops)) "Now connected!"))
			  (else 
				(error "Incorrect password, try again " guessing-password))))
	(method (disconnect laptop)
		(begin (set! connected-laptops (delete laptop connected-laptops)) "Disconnected!"))
	(method (surf laptop url)
		(system (string-append "lynx " url)))
	(method (exit person)
		(let ((laptop (flatmap (lambda (possession) (if (laptop? possession) (list possession) '())) (ask person 'possessions))))
			(if (and (not (equal? laptop '())) (memq (car laptop) connected-laptops))
				(begin (set! connected-laptops (delete (car laptop) connected-laptops)) (usual 'exit person))
				(usual 'exit person)))))
		
		
(define-class (locked-place name)
	(parent (place name))
	(instance-vars (locked #t))
	(method (unlock) 
		(set! locked #f)  
		(display name)
		(display " is now unlocked")
		(newline))
	(method (lock)
		(set! locked #t)
		(display name)
		(display " is now locked")
		(newline))
	(method (may-enter? person)
		(if locked
			#f
			#t)))
			
(define-class (garage name)
	(parent (place name))
	(class-vars (serial-counter 1))
	(instance-vars (table (make-table)))
	(method (park thing-car)
		(let ((possessor (ask thing-car 'possessor)))
			(cond ((null? (flatmap 
					  (lambda (thing) (if (eq? thing thing-car) (list thing-car) '()))
					  (usual 'things))) (error "Car is not in the garage " thing-car))
				  ((eq? 'no-one possessor) (error "Whose driving this car?!?! " thing-car))
				(else 
					(begin
						(let ((new-ticket (instantiate ticket 'ticket serial-counter)))
							(insert! serial-counter thing-car table)
							(ask possessor 'lose thing-car)
							(ask self 'appear new-ticket)
							(ask possessor 'take new-ticket)
							(set! serial-counter (+ 1 serial-counter))
							'okay))))))
	(method (un-park ticket)
		(if (not (ticket? ticket)) 
			(error "Not a ticket " ticket)
			(let ((ticket-number (ask ticket 'number)))
				(let ((thing-car (lookup ticket-number table)) (possessor (ask ticket 'possessor)))
					(if (not thing-car)
						(error "Car is not parked here")
						(begin
							(ask possessor 'lose ticket)
							(ask possessor 'take thing-car)
							(insert! ticket-number #f table)
							'okay)))))))
							
(define-class (jail name)
	(parent (place name))
	(instance-vars (directions-and-neighbors '()))
	(method (new-neighbor direction neighbor)
		'())
	(method (type) 'jail))
	
(define-class (food name calories)
	(parent (thing name))
	(instance-vars (edible? #t)))
	
(define-class (bagel)
	(parent (food 'bagel 200)))
	
(define-class (coke)
	(parent (food 'coke 80)))

(define-class (restaurant name type-of-food price-for-one)
	(parent (place name))
	(method (menu)
		(list type-of-food price-for-one))
	(method (sell person food-person-wants)
		(if (eq? (ask person 'type) 'police)
			(let ((food (instantiate type-of-food)))
				(if (eq? food-person-wants (ask food 'name))
					(begin (display "Thank you for your service!\n") food)))
			(let ((food (instantiate type-of-food)))
				(if (eq? food-person-wants (ask food 'name))
					(if (ask person 'pay-money price-for-one) 
						food 
						(begin (error "Not enough funds") #f))
					(error "We don't sell those here -- " food-person-wants))))))
					; not enough funds to pay for one food unit if returns #f
	
				
(define-class (ticket name number)
	(parent (thing name)))
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Implementation of thieves for part two
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (edible? food)
  (ask food 'edible?))

(define-class (thief name initial-place)
  (parent (person name initial-place))
  (initialize (ask self 'put 'strength 300))
  (instance-vars
   (behavior 'steal))
  (method (type) 'thief)

  (method (notice person)
    (if (eq? behavior 'run)
		(let ((exits (ask (usual 'place) 'exits)))
			(if (not (empty? exits))
				(ask self 'go (pick-random exits))))
		(let ((food-things
			   (filter (lambda (thing)
				 (and (edible? thing)
					  (not (eq? (ask thing 'possessor) self))))
				   (ask (usual 'place) 'things))))
		  (if (not (null? food-things))
			  (begin
			   (ask self 'take (car food-things))
			   (set! behavior 'run)
			   (ask self 'notice person)) )))) )
			   
			   
(define-class (police name initial-place station)
	(parent (person name initial-place))
	(initialize (if (not (and (procedure? station) (equal? (ask station 'type) 'jail))) (error "Police must be created initially in a station/jail -" station) (ask self 'put 'strength 1000)))
	(method (type) 'police)
	(method (notice person)
		(if (eq? (ask person 'type) 'thief)
			(begin
				(display "Crime Does Not Pay!\n")
				(format #t "~A was apprehended\n" (ask person 'name))
				(for-each (lambda (item) (ask person 'lose item)) (ask person 'possessions))
				(ask person 'go-directly-to station)))))
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utility procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (name obj) (ask obj 'name))
(define (inventory obj)
  (if (person? obj)
      (map name (ask obj 'possessions))
      (map name (ask obj 'things))))
	  
(define (whereis obj)
	(if (person? obj)
		(ask (ask obj 'place) 'name)
		(error "Not a person object -- " obj)))
		
(define (owner obj)
	(if (thing? obj)
		(let ((owner (ask obj 'possessor)))
			(if (equal? owner 'no-one)
				'no-one
				(ask owner 'name)))
		(error "Not a thing -- " ob)))

(define (people-here location)
	(map name (ask location 'people)))

(define (get-ticket person)
	(let ((tickets (flatmap (lambda (possession) (if (ticket? possession) (list possession) '())) (ask person 'possessions))))
		(if (not (null? tickets))
			(car tickets)
			'())))

;;; this next procedure is useful for moving around

(define (move-loop who)
  (newline)
  (print (ask who 'exits))
  (display "?  > ")
  (let ((dir (read)))
    (if (equal? dir 'stop)
	(newline)
	(begin (print (ask who 'go dir))
	       (move-loop who)))))


;; One-way paths connect individual places.

(define (can-go from direction to)
  (ask from 'new-neighbor direction to))


(define (announce-take name thing)
  (newline)
  (display name)
  (display " took ")
  (display (ask thing 'name))
  (newline))

(define (announce-move name old-place new-place)
  (newline)
  (newline)
  (display name)
  (display " moved from ")
  (display (ask old-place 'name))
  (display " to ")
  (display (ask new-place 'name))
  (newline))

(define (have-fit p)
  (newline)
  (display "Yaaah! ")
  (display (ask p 'name))
  (display " is upset!")
  (newline))


(define (pick-random set)
  (nth (random (length set)) set))

(define (delete thing stuff)
  (cond ((null? stuff) '())
	((eq? thing (car stuff)) (cdr stuff))
	(else (cons (car stuff) (delete thing (cdr stuff)))) ))

(define (person? obj)
  (and (procedure? obj)
       (member? (ask obj 'type) '(person police thief))))
	   
(define (jail? obj)
  (and (procedure? obj)
		(equal? 'jail (ask obj 'type))))

(define (thing? obj)
  (or (and (procedure? obj)
       (eq? (ask obj 'type) 'thing))
	   (laptop? obj)))
	   
(define (ticket? obj)
	(and (procedure? obj)
		(eq? (ask obj 'type) 'thing)
		(eq? (ask obj 'name) 'ticket)))

(define (hotspot? obj)
	(and (procedure? obj)
			(eq? (ask obj 'type) 'hotspot)))

(define (laptop? obj)
	(and (procedure? obj)
			(eq? (ask obj 'type) 'laptop)))