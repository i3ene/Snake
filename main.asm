; 8051 Snake Game
	CSEG	At 0H
	jmp	init
	ORG	100H


; Display bus P0
; Control bus P1

; Direction: Left (0)
; Direction: Right (1)
; Direction: Up (2)
; Direction: Down (3)

; RS0: 0, RS1: 0
; SnakePos (R0), SnakeDir (R1), SnakeLen (R2), SnakeMax (R3), FoodPos (R4), FoodBlink (R5), Return (R6)
;
; RS0: 1, RS1: 0
; RS0: 0, RS1: 1
; RS0: 1, RS1: 1
; Snake positions

; Init Snake Values
init:
	MOV	R0, #11h	; SnakePos
	MOV	R1, #01h	; SnakeDir
	MOV	R2, #01h	; SnakeLen
	MOV	R3, #18h	; SnakeMax

; Main Program
loop:
	MOV	A, R0
	ACALL	direction
	JMP	loop

direction:
	; Update direction
	MOV	A, R1
	RET

END
