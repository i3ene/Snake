; 8051 Snake Game
	EQU	ZUF8R, 0x20	;ein byte
	CSEG	At	0H
	jmp	init
	ORG	100h

; Display bus P0
; Control bus P1

; Direction: Left (0)
; Direction: Right (1)
; Direction: Up (2)
; Direction: Down (3)

; Variables
; RS0: 0, RS1: 0
; Return (R0), SnakeDir (R1), SnakeLen (R2), SnakeMax (R3), FoodPos (R4), FoodBlink (R5), SnakePos (R6); Array Index (R7)
;
; Array
; RS0: 1, RS1: 0
; RS0: 0, RS1: 1
; RS0: 1, RS1: 1
; Snake positions (Array)

; Init Snake Values
init:
	MOV	R6, #21h	; SnakePos (XY)
	MOV	R1, #01h	; SnakeDir
	MOV	R2, #01h	; SnakeLen
	MOV	R3, #18h	; SnakeMax
	MOV	R4, #41h	; FoodPos (XY)
	MOV	SP, #20h	; Move StackPointer out of variable space

	MOV	A, R6		; Load first snake body part into array
	SETB	RS0		; Switch to array space
	MOV	R0, A		; Write body part to array
	CLR	RS0		; Back to variable space

; Main Program
loop:
	ACALL	input_left
	MOV	A, R1		; Load current direction
	ACALL	move_left
	ACALL	display
	JMP	loop

input_left:
	MOV	A, P2		; Load input
	XRL	A, #1h	; Mask input to first bit
	; Check if equal
	CJNE	A, #0FFh, input_up
	MOV	R1, #0h		; Set direction left
	RET

input_up:
	MOV	A, P2		; Load input
	XRL	A, #2h	; Mask input to second bit
	; Check if equal
	CJNE	A, #0FFh, input_right
	MOV	R1, #1h		; Set direction up
	RET

input_right:
	MOV	A, P2		; Load input
	XRL	A, #4h	; Mask input to third bit
	; Check if equal
	CJNE	A, #0FFh, input_down
	MOV	R1, #2h		; Set direction right
	RET

input_down:
	MOV	A, P2		; Load input
	XRL	A, #8h	; Mask input to third bit
	; Check if equal
	CJNE	A, #0FFh, input_default
	MOV	R1, #3h		; Set direction down
	RET

input_default:
	; Do nothing, keep last direction
	RET

move_left:
	CJNE	A, #00h, move_right
	; Move Left
	MOV	A, R6		; Load current position
	SUBB	A, #10h		; Remove 1 from X of pos
	ACALL	move_execute
	RET

move_right:
	CJNE	A, #01h, move_up
	; Move Right
	MOV	A, R6		; Load current position
	ADD	A, #10h		; Add 1 to X of pos
	ACALL	move_execute
	RET

move_up:
	CJNE	A, #02h, move_down
	; Move Down
	MOV	A, R6		; Load current position
	; Copy current pos
	MOV	B, A
	; Check if x position need to wrap
	ADD	A, #01h		; Ad 1 to Y of pos
	ANL	A, #0Fh		; Mask for only Y part
	ANL	B, #0F0h	; Mask copied value for X value
	ADD	A, B		; Add X and Y together
	ACALL	move_execute
	RET

move_down:
	; Move Down
	MOV	A, R6		; Load current position
	; Copy current pos
	MOV	B, A
	; Check if x position need to wrap
	SUBB	A, #01h		; Remove 1 from Y of pos
	ANL	A, #0Fh		; Mask for only Y part
	ANL	B, #0F0h	; Mask copied value for X value
	ADD	A, B		; Add X and Y together
	ACALL	move_execute
	RET

move_execute:
	; Check if snake is eating itself.
	ACALL	wrap		; Check if wrapping needs to be done
	; (Check if calculated pos is already in array)
	MOV	R6, A		; Move calculated pos to R6
	ACALL	check_food	; Check if food is eaten
	ACALL	check_loop
	; Execute move step
	INC	R0		; Increment address for first step
	ACALL	move_array
	RET

check_food:
	MOV	A, R6		; Load current pos
	MOV	B, R4		; Load food pos
	CLR	C		; Clear Carry
	; Check if food and current pos are the same
	SUBB	A, B
	JZ	eat_food
	RET

eat_food:
	INC	R2		; Increment snake length
	ACALL	generate_food
	RET

generate_food:
	; Random generate food pos
	ACALL	ZUFALL
	ACALL	wrap		; Wrap random pos to matrix
	MOV	R4, A
	ACALL	loop_food
	RET

loop_food:
	; Check every entry
	MOV	A, R7		; Load current entry index
	ADD	A, #08h		; Register offset to array space
	; Get position value of current index
	MOV	R0, A		; Save address to register
	MOV	A, @R0		; Load value from register
	; Check if current pos equals loaded pos
	SUBB	A, R4		; Subtract position values from each other
	JZ	generate_food	; If A is 0, it is same position, so game over!
	; Increment to next step
	INC	R7		; Increment entry index
	MOV	A, R7		; Load entry index
	MOV	B, R2		; Load max SnakeLen
	CJNE	A, B, check_food	; Check SnakeLen with current entry index
	; Index is equal to SnakeLen, reset index
	MOV	R7, #00h
	; Get out of loop
	RET

; ------ Zufallszahlengenerator-----------------
ZUFALL:	mov	A, ZUF8R	; initialisiere A mit ZUF8R
	jnz	ZUB
	cpl	A
	mov	ZUF8R, A
ZUB:	anl	a, #10111000b
	mov	C, P
	mov	A, ZUF8R
	rlc	A
	mov	ZUF8R, A
	ret

wrap:
	; Check if position needs to wrap
	ACALL	wrap_x
	ACALL	wrap_y
	RET

wrap_y:
	; Copy current pos
	MOV	B, A
	; Check if y position need to wrap
	ANL	A, #0Fh		; Mask for only Y part
	ANL	A, #7h		; Mask for max matrix size
	ANL	B, #0F0h	; Mask copied value for X value
	ADD	A, B		; Add X and Y together
	RET

wrap_x:
	; Copy current pos
	MOV	B, A
	; Check if x position need to wrap
	ANL	A, #0F0h	; Mask for only X part
	; Bit shift by 4 to right
	RRC	A
	RRC	A
	RRC	A
	RRC	A
	ANL	A, #7h		; Mask for max matrix size
	; Bit shift by 4 to left
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	ANL	B, #0Fh		; Mask copied value for Y value
	ADD	A, B		; Add X and Y together
	RET


check_loop:
	; Check every entry
	MOV	A, R7		; Load current entry index
	ADD	A, #08h		; Register offset to array space
	; Get position value of current index
	MOV	R0, A		; Save address to register
	MOV	A, @R0		; Load value from register
	; Check if current pos equals loaded pos
	SUBB	A, R6		; Subtract position values from each other
	JZ	game_over	; If A is 0, it is same position, so game over!
	; Increment to next step
	INC	R7		; Increment entry index
	MOV	A, R7		; Load entry index
	MOV	B, R2		; Load max SnakeLen
	CJNE	A, B, check_loop	; Check SnakeLen with current entry index
	; Index is equal to SnakeLen, reset index
	MOV	R7, #00h
	; Get out of loop
	RET

game_over:
	; Snake ate itself
	LJMP lose

move_array:
	; Move every body entry one step
	DEC	R0		; Decrement address for this step
	MOV	B, @R0		; Load current value from register
	INC	R0		; Increment address
	MOV	@R0, B		; Save loaded value to next/last address (move value in array one up)
	; ACALL	check_array	; Check if entry is out of bound
	; Move to next address
	DEC	R0		; Decrement address since we incremented it for write
	MOV	A, R0		; Load current address
	SUBB	A, #08h		; Subtract address space offset
	JNZ	move_array	; If not zero, do next step
	; At the beginning of array, so stop
	MOV	A, R6		; Load current SnakePos
	MOV	@R0, A		; Save pos to beginning of array
	RET

check_array:
	MOV	A, R0		; Load current address
	DEC	A		; Decrement by to get next/current address
	SUBB	A, #08h		; Subtract array address offset
	JZ	array_remove	; If 0, remove array entry
	RET

array_remove:
	MOV	@R0, #00h	; Remove entry
	RET

display:
	; Display the current state to LED Matrix
	MOV	R0, #08h	; Load current address of array start
	ACALL	display_loop
	RET

display_loop:
	MOV	B, @R0		; Load current value
	ACALL	display_matrix	; Display current value
	INC	R0		; Increment current address
	MOV	A, R0		; Load current address
	SUBB	A, #08h		; Subtract array address offset
	MOV	B, R2		; Load SnakeLen
	CJNE	A, B, display_loop	; Check if SnakeLen is reached

	; Food display
	MOV	B, R4		; Load FoodPos
	ACALL	display_matrix	; Display food
	RET

display_matrix:
	MOV	P0, #0FFh	; Null X display
	MOV	P1, #0FFh	; Null Y display

	MOV	A, B		; Load value
	ANL	A, #0F0h	; Mask for only X part
	; Bit shift by 4 to right
	RRC	A
	RRC	A
	RRC	A
	RRC	A
	ANL	A, #0Fh		; Mask for only Y part
	; Map hex to matrix bit
	ACALL	display_0
	XRL	P0, A		; Add X part to P0

	MOV	A, B		; Load value
	ANL	A, #0Fh		; Mask for only Y part
	; Map hex to matrix bit
	ACALL	display_0
	XRL	P1, A		; Add Y part to P1
	RET

display_0:
	CJNE	A, #00h, display_1
	; Map 0 to matrix 0
	MOV	A, #01h
	RET

display_1:
	CJNE	A, #01h, display_2
	; Map 1 to matrix 1
	MOV	A, #02h
	RET

display_2:
	CJNE	A, #02h, display_3
	; Map 2 to matrix 2
	MOV	A, #04h
	RET

display_3:
	CJNE	A, #03h, display_4
	; Map 3 to matrix 3
	MOV	A, #08h
	RET

display_4:
	CJNE	A, #04h, display_5
	; Map 4 to matrix 4
	MOV	A, #10h
	RET

display_5:
	CJNE	A, #05h, display_6
	; Map 5 to matrix 5
	MOV	A, #20h
	RET

display_6:
	CJNE	A, #06h, display_7
	; Map 6 to matrix 6
	MOV	A, #40h
	RET

display_7:
	; Map 7 to matrix 7
	MOV	A, #80h
	RET

lose:
	END
