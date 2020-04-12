#LOAD_SEGMENT=FFFFH
#LOAD_OFFSET=0000H

#AX=0000H
#BX=0000H
#CX=0000H
#DX=0000H
#SI=0000H
#DI=0000H
#BP=0000H

#CS=0000H
#IP=0000H

#DS=0000H
#ES=0000H
#SS=0000H
#SP=FFFEH



	JMP     ST1
	DB     509 DUP(0)
	DW     T_ISR
	DW     0000
	DB     508 DUP(0)

; KEYPAD TABLE
KEYPAD_TABLE DB 0EEH,0EDH,0EBH,0E7H,0DEH,0DDH,0DBH,0D7H,0BEH,0BDH,0BBH,0B7H,07EH,07DH,07BH,077H

;DISPLAY TABLE
DISPLAY_TABLE DB 3FH,06H,5BH,4FH,66H, 6DH,7DH,27H,7FH,6FH

;MOTOR STEP TABLE
MOTOR_TABLE DB 19H,13H,16H,1CH,19H,13H

;VARIABLES
KEY0 DB ?
KEY1 DB ?
TEMP1 DB ?
TEMP0 DB ?
TEMP  DB ?
TEMP_SENSE1 DB ?
TEMP_SENSE2 DB ?
TEMP_SENSE3 DB ?
TEMP_SENSE4 DB ?
TEMP_SENSE5 DB ?
TEMP_SENSE6 DB ?

HOURS DB ?
CUR_PORT DB ?
CUR_TEMP DB ?

DISP DB ?
DB	465 DUP(0) 

;MAIN PROGRAM
ST1:      CLI

; INTIALIZE DS, ES,SS TO START OF RAM
MOV       AX,0200H
MOV       DS,AX
MOV       ES,AX
MOV       SS,AX
MOV       SP,0FFFEH


;INITIALIZE VARIABLES
MOV KEY0,00H
MOV KEY1,00H

MOV TEMP1,02H
MOV TEMP0,03H
MOV TEMP,23D

MOV TEMP_SENSE1,25D
MOV TEMP_SENSE2,25D
MOV TEMP_SENSE3,25D
MOV TEMP_SENSE4,25D
MOV TEMP_SENSE5,25D
MOV TEMP_SENSE6,25D

MOV HOURS,01H

MOV CUR_PORT,10H
MOV CUR_TEMP,17H

MOV DISP,01H

; 8255-A (STARTING 00H)
; INTIALISE KEYPAD, UPPER PORT C AS (TAKES) INPUT ,PORT B ,PORT A AND LOWER PORT C AS (GIVES) OUTPUT, 
	MOV     AL, 10001000B
	OUT     06H,AL

; 8255-B (STARTING 08H)
; INITIALIZE SENSORS, PORT A AND UPPER PORT C (TAKES) INPUT, PORT B AND LOWER PORT C AS (GIVES) OUTPUT, 
	MOV		AL, 10011000B
	OUT		0EH, AL

; 8255-C (STARTING 10H) 
;INITIALIZE MOTORS 1,2,3, PORT A,B,C (GIVES) OUTPUT, 
	MOV		AL, 10000000B
	OUT		16H, AL

; 8255-D (STARTING 18H) 
;INITIALIZE MOTORS 4,5,6, PORT A,B,C (GIVES) OUTPUT, 
	MOV		AL, 10000000B
	OUT		1EH, AL
	
;INITIALIZE TIMER. (STARTING 20H)
;CLOCK 0 IN MODE 2 WITH 1KHZ INPUT
;CLOCK 1 IN MODE 3 WITH 1MHZ INPUT
;CLOCK 2 IN MODE 3 WITH 5MHZ INPUT
	MOV		AL, 00110100B
	OUT		26H, AL
	MOV     AL, 01110110B
	OUT     26H, AL
	MOV     AL, 10110110B
	OUT     26H, AL

;SEND COUNT OF 01F4H = 500D TO CLOCK 0
;SEND COUNT OF 03E8H = 1000D TO CLOCK 1
;SEND COUNT OF 0005H = 5D TO CLOCK 2
	MOV 	AL,0F4H
	OUT 	20H,AL
	MOV 	AL,01H
	OUT 	20H,AL
	
	MOV 	AL,0E8H
	OUT 	22H,AL
	MOV 	AL,03H
	OUT 	22H,AL
	
	MOV 	AL,05H
	OUT 	24H,AL
	MOV 	AL,00H
	OUT 	24H,AL
;OUT CLOCK 0 = 2HZ APPROX.
;OUT CLOCK 1 = 1KHZ APPROX.
;OUT CLOCK 2 = 1MHZ APPROX.

;INITIALIZE TIMER 8255-E, PORT A INPUT,PORT B PORT C OUTPUT 28H
	MOV		AL, 10010000B
	OUT     2EH, AL
	MOV     AL,00H
	OUT     2AH, AL

;8259 -	ENABLE IRO ALONE USE AEOI	  
	MOV     AL,00010011B
	OUT     30H,AL
	MOV     AL,80H
	OUT     32H,AL
	MOV     AL,03H
	OUT     32H,AL
	MOV     AL,0FEH
	OUT     32H,AL
	STI
	
;START DISPLAY WITH 23(DEFAULT TEMP)
	MOV AL,4FH
	NOT AL
	OUT 00H,AL

	MOV AL,5BH
	NOT AL
	OUT 02H,AL
	
;CHECK FOR KEY RELEASE:
X0:
	MOV            DH,00H
	MOV            AL,00H
	OUT            04H,AL
X1:        
	IN             AL,04H
	AND            AL,0F0H
	CMP            AL,0F0H
	JNZ            X1

	CALL           D20MS
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
;CORE LOOP, FIRST CHECKS FOR BIOSLEEP TIMER THEN POLLING THEN CHECKS FOR KEY PRESS:
	MOV            AL,00H
	OUT            04H ,AL

X2:	IN             AL, 04H
	AND            AL,0F0H
	CMP            AL,0F0H
	JZ             X2

	CALL           D20MS

	MOV            AL,00H
	OUT            04H ,AL
	IN             AL, 04H
	AND            AL,0F0H
	CMP            AL,0F0H
	JZ             X2
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------	
;DECODES KEY MATRIX
	
;CHECK COLUMN 0	
	MOV            AL, 0EH
	MOV            BL,AL
	OUT            04H,AL
	IN             AL,04H
	AND            AL,0F0H
	CMP            AL,0F0H
	JNZ            X3
	
;CHECK COLUMN 1		
	MOV            AL, 0DH
	MOV            BL,AL
	OUT            04H ,AL
	IN             AL,04H
	AND            AL,0F0H
	CMP            AL,0F0H
	JNZ            X3
	
;CHECK COLUMN 2		
	MOV            AL, 0BH
	MOV            BL,AL
	OUT            04H,AL
	IN             AL,04H
	AND            AL,0F0H
	CMP            AL,0F0H
	JNZ            X3
	
;CHECK COLUMN 3		
	MOV            AL, 07H
	MOV            BL,AL
	OUT            04H,AL
	IN             AL,04H
	AND            AL,0F0H
	CMP            AL,0F0H
	JZ             X2
	
;DECODE KEY
X3:         
	OR             AL,BL
	MOV            CX,0FH
	MOV            DI,00H
X4:       
	CMP            AL,CS:KEYPAD_TABLE[DI]
	JZ             X5
	INC            DI
	INC            DH
	LOOP           X4
	
;DISPLAY KEY
X5: 
	CMP            DH,09H
	JG             BUTTON
	LEA            BX, DISPLAY_TABLE
	MOV            AL, CS:[BX+DI]
	NOT            AL
	MOV            DL,DISP
	CMP            DL,00H
	JNE            X6
	OUT            00H,AL
	XOR            DL,01H
	MOV            DISP,DL
	MOV            KEY0,DH
	JMP            X0
	
X6: 
	OUT            02H,AL
	XOR            DL,01H
	MOV            DISP,DL
	MOV            KEY1,DH
	JMP            X0

;IF BUTTON PRESSED IS NOT A NUMBER, THIS PROCEDURE CHECKS WHICH BUTTON AND CALLS SUBSEQUENT PROCEDURE	
BUTTON:
	CMP DH,0AH
	JE TUP
	CMP DH,0BH
	JE TDWN
	CMP DH,0CH
	JE ON
	CMP DH,0DH
	JE BIOSLEEP
	CMP DH,0EH
	JE OFF
	CMP DH,0FH
	JE REGULAR
	JMP X0

;INCREASE TEMPERATURE BY 1(UPTO 25 DEGREES)
TUP:
	MOV CL,TEMP0
	CMP CL,05H
	JE X0
	INC CL
	MOV TEMP0,CL
	MOV AL,TEMP
	ADD AL,1
	MOV TEMP,AL
	CALL DISPLAY0
	JMP X0

;DECREASE TEMPERATURE BY 1(UPTO 20 DEGREES)
TDWN:
	MOV CL,TEMP0
	CMP CL,00H
	JE X0
	DEC CL
	MOV TEMP0,CL
	MOV AL,TEMP
	SUB AL,1
	MOV TEMP,AL
	CALL DISPLAY0
	JMP X0

;STARTS RATE GENERATOR FOR TAKING INPUT FROM SENSORS PERIODICALLY	
ON:
	;STARTS TIMER
	MOV     AL,01H
	OUT     2AH, AL
	JMP X0

;SETS SLEEP TIMER(UPTO 9 HOURS),AFTER TAKING INPUT RESETS DISPLAY TO TEMPERATURE
BIOSLEEP:

    MOV AL,KEY1
	MOV BL,KEY0
	MOV AH,00
	MOV CL,0AH
	MUL CL
	ADD AL,BL
	CMP AX,0009H
	JG HOURH
	MOV HOURS,AL 
	CALL DISPLAY0
	CALL DISPLAY1
	JMP TIMER_START
HOURH:
	MOV HOURS,09H
	CALL DISPLAY0
	CALL DISPLAY1
	JMP TIMER_START



;DISABLES RATE GENERATOR, SHUTS ALL AC VENTS	
OFF:
	MOV AL,06H
	OUT 10H,AL
	OUT 12H,AL
	OUT 14H,AL
	OUT 18H,AL
	OUT 1AH,AL
	OUT 1CH,AL
	MOV     AL,00H
	OUT     2AH, AL
	JMP X0

;SETS TEMPERATURE EQUAL TO NUMBER CURRENTLY ON DISPLAY, IF >25, AUTOMATICALLY SETS TO 25,SAME WITH <20	
REGULAR:
	MOV AL,KEY1
	MOV TEMP1,AL
	MOV CL,0AH
	MUL CL
	MOV CL,KEY0
	MOV TEMP0,CL
	ADD AL,CL
	MOV TEMP,AL
	CMP AL,25D
	JG DEFH
	CMP AL,20D
	JL DEFL
	JMP X0
	
DEFH:
	MOV TEMP1,02H
	MOV TEMP0,05H
	MOV AL,25D
	MOV TEMP,AL
	CALL DISPLAY0
	CALL DISPLAY1
	JMP X0
DEFL:
	MOV TEMP1,02H
	MOV TEMP0,00H
	MOV AL,20D
	MOV TEMP,AL
	CALL DISPLAY0
	CALL DISPLAY1
	JMP X0

;MULTIPLIES USER INPUT WITH 3600 AND STARTS SLEEP TIMER
TIMER_START:
	MOV     BL,HOURS
	MOV     AX,0001H
	MUL     BL
DHOUR:
	CALL    D1S 
	DEC     AX
	JNZ     DHOUR
	JMP     OFF

JMP X0

;COMPARES DESIRED TEMPERATURE WITH POLLED TEMPERATURE AND MOVES VENT ACCORDINGLY
MOTOR:
	MOV BL,TEMP
	MOV AL,CUR_TEMP
	SUB AL,BL
	CMP AL,01H
	JE P1
	CMP AL,02H
	JE P2
	CMP AL,03H
	JE P3
	CMP AL,04H
	JE P4
	CMP AL,05H
	JE P5
	
	JMP NO
	
NO:
	MOV DL,CUR_PORT
	MOV DH,00H
	MOV AL,09H
	OUT DX,AL
	RET
	
P1:
	MOV DL,CUR_PORT
	MOV DH,00H
	MOV AL,11H
	OUT DX,AL
	RET
	
P2:
	MOV DL,CUR_PORT
	MOV DH,00H
	MOV AL,13H
	OUT DX,AL
	RET
	
P3:
	MOV DL,CUR_PORT
	MOV DH,00H
	MOV AL,12H
	OUT DX,AL
	RET
	
P4:
	MOV DL,CUR_PORT
	MOV DH,00H
	MOV AL,16H
	OUT DX,AL
	RET
	
P5:
	MOV DL,CUR_PORT
	MOV DH,00H
	MOV AL,14H
	OUT DX,AL
	RET
	
;CHECKS FOR EOC
CONV:
	IN AL,0CH
	AND AL,0F0H
	CMP AL,10H
	JNE CONV
	RET	

;UPDATE LSB OF DISPLAY	
DISPLAY0:
	MOV CL,TEMP0
	MOV CH,00H
	MOV DI,CX
	LEA BX, DISPLAY_TABLE
	MOV AL,CS:[BX+DI]
	NOT AL
	OUT 00H,AL
	RET

;UPDATE MSB OF DISPLAY
DISPLAY1:
	MOV CL,TEMP1
	MOV CH,00H
	MOV DI,CX
	LEA BX, DISPLAY_TABLE
	MOV AL,CS:[BX+DI]
	NOT AL
	OUT 02H,AL
	RET

;GENERATES DEBOUNCE DELAY	
D20MS:    
	MOV            CX,20 ; DELAY GENERATED 
XN:        
	LOOP           XN
	RET	


D1S:    
	MOV            CX,50000 ; DELAY GENERATED IS 1S
XS:        
	LOOP           XS
	RET	


T_ISR:         
    PUSH AX
	;SELECT SENSOR 1
		MOV AL,00H
		OUT 0AH,AL

	;HIGH TO LOW TRANSITION ON START AND ALE
		MOV AL,00H
		OUT 0CH,AL
		MOV AL,03H
		OUT 0CH,AL
		MOV AL,00H
		OUT 0CH,AL

	;WAIT FOR CONVERSION	
		CALL CONV

	;STORE READ TEMPERATURE
		IN AL,08H
		MOV TEMP_SENSE1,AL

	;SELECT SENSOR 2
		MOV AL,01H
		OUT 0AH,AL

	;HIGH TO LOW TRANSITION
		MOV AL,00H
		OUT 0CH,AL
		MOV AL,03H
		OUT 0CH,AL
		MOV AL,00H
		OUT 0CH,AL

	;WAIT FOR CONVERSION	
		CALL CONV

	;STORE READ TEMPERATURE
		IN AL,08H
		MOV TEMP_SENSE2,AL

	;SELECT SENSOR 3
		MOV AL,02H
		OUT 0AH,AL

	;HIGH TO LOW TRANSITION
		MOV AL,00H
		OUT 0CH,AL
		MOV AL,03H
		OUT 0CH,AL
		MOV AL,00H
		OUT 0CH,AL

	;WAIT FOR CONVERSION	
		CALL CONV

	;STORE READ TEMPERATURE
		IN AL,08H
		MOV TEMP_SENSE3,AL

	;SELECT SENSOR 4
		MOV AL,03H
		OUT 0AH,AL

	;HIGH TO LOW TRANSITION
		MOV AL,00H
		OUT 0CH,AL
		MOV AL,03H
		OUT 0CH,AL
		MOV AL,00H
		OUT 0CH,AL

	;WAIT FOR CONVERSION	
		CALL CONV

	;STORE READ TEMPERATURE
		IN AL,08H
		MOV TEMP_SENSE4,AL

	;SELECT SENSOR 5
		MOV AL,04H
		OUT 0AH,AL

	;HIGH TO LOW TRANSITION
		MOV AL,00H
		OUT 0CH,AL
		MOV AL,03H
		OUT 0CH,AL
		MOV AL,00H
		OUT 0CH,AL

	;WAIT FOR CONVERSION	
		CALL CONV

	;STORE READ TEMPERATURE
		IN AL,08H
		MOV TEMP_SENSE5,AL

	;SELECT SENSOR 6
		MOV AL,05H
		OUT 0AH,AL

	;HIGH TO LOW TRANSITION
		MOV AL,00H
		OUT 0CH,AL
		MOV AL,03H
		OUT 0CH,AL
		MOV AL,00H
		OUT 0CH,AL

	;WAIT FOR CONVERSION	
		CALL CONV

	;STORE READ TEMPERATURE
		IN AL,08H
		MOV TEMP_SENSE6,AL

	;------------UPDATING MOTORS----------

		MOV AL,TEMP_SENSE1
		MOV CUR_TEMP,AL
		MOV CUR_PORT,10H
		CALL MOTOR
		
		MOV AL,TEMP_SENSE2
		MOV CUR_TEMP,AL
		MOV CUR_PORT,12H
		CALL MOTOR
		
		MOV AL,TEMP_SENSE3
		MOV CUR_TEMP,AL
		MOV CUR_PORT,14H
		CALL MOTOR
		
		MOV AL,TEMP_SENSE4
		MOV CUR_TEMP,AL
		MOV CUR_PORT,18H
		CALL MOTOR
		
		MOV AL,TEMP_SENSE5
		MOV CUR_TEMP,AL
		MOV CUR_PORT,1AH
		CALL MOTOR
		
		MOV AL,TEMP_SENSE6
		MOV CUR_TEMP,AL
		MOV CUR_PORT,1CH
		CALL MOTOR 
		POP AX
IRET
