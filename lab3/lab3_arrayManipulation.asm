;======================MAIN====================
ORG 0000H

LJMP MAIN

ORG 100H

;        -----------------
; Sub Routine to generate delay of (d/2)s
;        -----------------
delay :
	USING 0
	PUSH AR3
	PUSH AR4
	PUSH AR5
	CLR A
	MOV A,4AH ; get D from 4FH
	MOV B,#0AH
	MUL AB ; Mul by 10 as (d/2)s = 50*Dms     
	MOV R3,A  ; Mov the loop parameter to R3
	delayLoop : ; write loop to last d/2 seconds 
			MOV R4,#200
			BACK1:
			MOV R5,#0FFH	
			BACK :
			DJNZ R5, BACK
			DJNZ R4, BACK1
			DJNZ R3, delayLoop
	POP AR3
	POP AR4
	POP AR5
	RET

;        ----------------
; Routine to read in Port lines P1.3 - P1.0 as a sngle nibble
; Reads a nibble , one at a time and stores it
;        ----------------
readNibble:
	USING 0
	PUSH AR1
	MOV P1,#00H			; Clearing the port
	MOV P1,#0F0H		; All LEDs on to signal start
	MOV 4AH,#0AH		; set the delay to 5s
	LCALL delay
	MOV P1,#00H
	MOV A,P1
	SWAP A
	ANL A,#0F0H			; ANDing with 11110000 to get upper nibble
	MOV R1,A
	MOV 4AH,#02H		; set the delay to 1s
	LCALL delay
	MOV P1,A
	MOV 4AH,#0AH		; set the delay to 5s
	LCALL delay
	MOV P1,#00H
	MOV A,P1
	SWAP A
	ANL A,#0F0H
	CJNE A, #00H, readNibble
	MOV 4EH,R1
	POP AR1
	RET					; Return to caller


;        ----------------
; Routine to read in Port lines P1.3 - P1.0 as a sngle nibble
; Reads 2 nibbles , one at a time , makes a byte and stores it
;        ----------------
packNibbles:
	PUSH AR0			; Push R0
	LCALL readNibble	
	MOV R0,4EH			; Read MSB in R0
	LCALL readNibble	
	MOV A,4EH			; Read LSB in A
	SWAP A
	;DEC R0
	ADD A,R0			; Add R0 and A 
	MOV 4FH,A 			; Store the result in 4FH
	POP AR0
	RET
	
;        ---------------
; Sub routine to read and store bytes into memory
;        ---------------
readValues:
	USING 0
	PUSH AR0
	PUSH AR1
	MOV R0,50H			; Read K from 50H
	MOV R1,51H			; Read P from 51H
	readLoop :
		LCALL packNibbles
		MOV @R1,4FH 		; Move input to correct location
		INC R1				; Increase address pointer	
		DJNZ R0, readLoop 
	POP AR0
	POP AR1
	RET
	
displayValues:
	CLR PSW.7
	MOV P1, #0FH
	NOP
	MOV A, P1
	SUBB A, 50H
	JNC Invalid
	MOV P1, #0FH
	MOV A, P1
	ADD A, 51H
	MOV R0, A
	MOV A, @R0
	ANL A, #0F0H
	MOV P1, A
	MOV 4AH, #04H;4S DELAY
	LCALL delay
	MOV A, @R0
	ANL A, #0FH
	SWAP A
	MOV P1,A
	MOV 4AH, #04H;4S DELAY
	LCALL delay
	SJMP displayValues
	RET

Invalid:
	MOV P1, #00H
	RET

shuffleBits	:
	USING 0
	PUSH AR0
	PUSH AR1
	PUSH AR2
	MOV R0,50H			; read K from 50H
	MOV R1,51H			; read A from 51H
	MOV R2,52H			; read B from 52H
	DEC R0
	DEC R0
	MOV A,@R1
	INC R1
	XRL A,@R1
	MOV @R2,A
	INC R2
	XORloop :
		CLR A
		MOV A,@R1
		INC R1
		XRL A,@R1
		MOV @R2,A
		INC R2
		DJNZ R0, XORloop
	MOV A,R1
	MOV R1,51H
	XRL A,@R1
	MOV @R2,A
	POP AR2
	POP AR1
	POP AR0
	RET

MAIN:

MOV 60H,#01H
MOV 61H,#02H
MOV 62H,#03H
MOV 63H,#04H
MOV 64H,#05H

MOV 50H,#04H;------------------------Value of K
MOV 51H,#60H;------------------------Array A start location
MOV 52H,#70H;------------------------Array B start location
LCALL shuffleBits

MOV 50H,#04H;------------------------Value of K
MOV 51H,#70H;------------------------Array B start Location
LCALL displayValues;----------------Display the last four bits of elements on LEDs
here:SJMP here;---------------------WHILE loop(Infinite Loop)
END
; ------------------------------------END MAIN------------------------------------