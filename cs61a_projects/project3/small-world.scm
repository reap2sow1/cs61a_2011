;;; small-world.scm
;;; Miniature game world for debugging the CS61A adventure game project.
;;; You can load this instead of adv-world.scm, and reload it quickly
;;; whenever you change a class.

;;; How to use this file:
;;; If, for example, your person class doesn't work, and you do something
;;; like (define Matt (instantiate person 'Matt)), and then fix your
;;; person class definition, Matt is still bound to the faulty person
;;; object from before.  However, reloading this file whenever you
;;; change something should redefine everything in your world with the
;;; currently loaded (i.e. most recent) versions of your classes.

(define berk_pold (instantiate jail 'berkpol))
(define 61A-Lab (instantiate place '61A-Lab))
(define Lounge (instantiate place 'Lounge))
(define Noahs (instantiate restaurant 'Noahs bagel 0.50))
(can-go 61A-Lab 'up Lounge)
(can-go Lounge 'down 61A-Lab)
(can-go Lounge 'east Noahs)
(can-go Noahs 'west Lounge)
;;;  Hopefully you'll see more of the world than this in real life
;;;  while you're doing the project!

(define Conner (instantiate person 'Conner Lounge))
(define thebadone (instantiate thief 'thebadone 61A-Lab))
(define po1 (instantiate police 'police1 Lounge berk_pold))

(define homework-box (instantiate thing 'homework-box))
(ask 61A-Lab 'appear homework-box)

(define coke (instantiate coke))
(define bagel (instantiate bagel)) 
(define pen (instantiate thing 'pen))
(ask Lounge 'appear coke)
(ask Lounge 'appear bagel)
(ask Lounge 'appear pen)
(ask Conner 'take coke)
(ask Conner 'take pen)

(define laba (instantiate person 'Lab-assistant 61A-Lab))

