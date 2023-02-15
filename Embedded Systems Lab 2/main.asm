;
; Embedded Systems Lab 2.asm
;
; Created: 2/7/2023 7:10:48 PM
; Author : epicg
;
.include "m328Pdef.inc"

.equ delay2 = 0x20 ; delay value for debouncing
.equ digit_0 = 0x3F; pattern to display digit 0
.equ digit_1 = 0x06 ; pattern to display digit 1
.equ digit_2 = 0x5B ; pattern to display digit 2
.equ digit_3 = 0x4F ; pattern to display digit 3
.equ digit_4 = 0x66 ; pattern to display digit 4
.equ digit_5 = 0x6D ; pattern to display digit 5
.equ digit_6 = 0x7D ; pattern to display digit 6
.equ digit_7 = 0x07 ; pattern to display digit 7
.equ digit_8 = 0x7F ; pattern to display digit 8
.equ digit_9 = 0x6F ; pattern to display digit 9
.equ dash = 0x40
.def value = r20 
.def tens = r24
.def ones = r25
.def temp = r18
;.def count = R20 ; counter 

; Set push button (PB3) as input
; Set SER (PB0), RCLK (PB1), and SRCLK (PB2) as outputs
cbi PORTB, PB3
cbi PORTB, PB4
nop
ldi r16, 0
ldi r16, (1<<DDB0) | (1<<DDB1) | (1<<DDB2)
out DDRB, r16
nop
ldi value, 0x00
; Main loop
reset: 
	clr r28
	clr r26 
	clr value
	ldi r16, digit_0
	rcall display
	rcall delay
	rcall display
	; Put code here to generate RCLK pulse
	sbi PORTB, PB1 ; set PB1 (RCLK)
	cbi PORTB, PB1 ; clear PB1 (RCLK)
	nop
	in r17, PINB
	sbrs R17, PB3
	rjmp reset
main:
	; Read push button state
	nop
	nop
	in R17, PINB
	sbrs R17, PB4
	rjmp countdown
	sbrs R17, PB3 ; check if pb3 is cleared. PB3 is logic low on button press and logic high on button release
	rjmp rightbuttonpressed
	rjmp main ; if push button is not pressed, wait


countDown: 
	rcall delay
	in R17, PINB
	sbrs R17, PB4
	rjmp countDown ; if the button was not cleared 
	cpi value, 0
	breq countdownEnd
	start: 
		rcall delay 
		rcall delay 
		rcall delay 
		inc r28 
		cpi r28, 29
		brne start
	clr r28
	dec value 
	cpi value, 0
	breq countdownEnd
	cpi value, 9
	brlt displaycountdownOne
	displaycountdownDouble:
		rcall findValue ; find the tens and ones place
		mov temp, tens
		rcall lookup
		rcall display
		nop
		mov temp, ones
		call lookup
		rcall display
		rjmp displaycountdownDone
	displaycountdownOne:
		ldi temp, 0
		nop
		rcall lookup
		rcall display
		mov temp, value
		rcall lookup
		rcall display
	displaycountdownDone: 
		sbi PORTB, PB1 ; set PB1 (RCLK)
		cbi PORTB, PB1 ; clear PB1 (RCLK)
	cpi value, 0 
	brne start 
	rjmp countdownEnd

resetchecksum:
	in R17, PINB
	sbrc R17, PB3
	rjmp reset
	rjmp resetchecksum

; Debounce push button
; TODO: etermine how long the button has been pressed to trigger a reset
rightbuttonpressed:
	rcall delay
	checkReset: 
		in R17, PINB
		sbrs R17, PB3
		rjmp resetCounter	
	clr R28
	cpi value, 25 ; if the value is equal to 25, branch back to main as thats the max number we allow
	breq main
	ldi r28, 0x00
	sbrc R17, PB3
	rjmp buttonReleased
	rjmp reset


resetCounter: 
	rcall delay 
	rcall delay
	rcall delay 
	inc r28 
	cpi R28, 29
	breq resetchecksum
	rjmp checkReset



countdownEnd: 
	ldi r28, 0
	ldi r26, 0 
	blinkSeconds: 
		rcall delay 
		rcall delay 
		rcall delay 
		inc r28 
		cpi r28, 14
		brne blinkSeconds
	clr r28
	ldi ones, dash
	mov r16, ones
	rcall display
	rcall display
	sbi PORTB, PB1 ; set PB1 (RCLK)
	cbi PORTB, PB1 ; clear PB1 (RCLK)
	inc r26
	cpi r26, 8
	brne blinkSeconds 
	rjmp main
buttonReleased:
	inc value 
	nop
	rcall delay
	checkDisplay: 
	cpi value, 10
	brlt displayOne
	displayDouble:
		rcall findValue ; find the tens and ones place
		mov temp, tens
		rcall lookup
		rcall display
		nop
		mov temp, ones
		call lookup
		rcall display
		rjmp displayDone
	displayOne:
		ldi temp, 0
		nop
		rcall lookup
		rcall display
		mov temp, value
		rcall lookup
		rcall display
	displayDone: 
		sbi PORTB, PB1 ; set PB1 (RCLK)
		cbi PORTB, PB1 ; clear PB1 (RCLK)
	rjmp main

findValue:
	ldi tens, 0x00 ; quotient
	mov ones, value  ; remainder
	div: 
		inc tens
		subi ones, 10
		brcc div ; branch if carry is 0 
	dec tens ; correct remainder  
	ldi r18, 10 
	add ones, r18 ; correct remainder
	ret
	 
.equ count = 0x00AA ; assign a 16-bit value to symbol 
delay:
	ldi r30, low(count)   ; r31:r30  <-- load a 16-bit value into 
	ldi r31, high(count);
	d1:
		ldi   r29, 0xff     ; r29 <-- load a 8-bit value into counter register for inner loop
	d2:
		nop ; no operation
		dec   r29            ; r29 <-- r29 - 1
		brne  d2 ; branch to d2 if result is not "0"
		sbiw r31:r30, 1 ; r31:r30 <-- r31:r30 - 1
		brne d1 ; branch to d1 if result is not "0"
	ret 


; Read push button state again to check if it is still pressed
;in R17, 3
;sbrs R17, PB3
;rjmp main ; if push button is not pressed, wait
;inc R20
;rcall lookupRight

; Increment display value
lookup:
	cpi temp, 0x00
	breq equal0
	cpi temp, 0x01
	breq equal1
	cpi temp, 0x02
	breq equal2
	cpi temp, 0x03
	breq equal3
	cpi temp, 0x04
	breq equal4
	cpi temp, 0x05
	breq equal5
	cpi temp, 0x06
	breq equal6
	cpi temp, 0x07
	breq equal7
	cpi temp, 0x08
	breq equal8
	cpi temp, 0x09
	breq equal9

equal0: 
	ldi R16, digit_0
	ret
equal1: 
	ldi R16, digit_1
	ret
equal2: 
	ldi R16, digit_2
	ret
equal3: 
	ldi R16, digit_3
	ret
equal4: 
	ldi R16, digit_4
	ret
equal5: 
	ldi R16, digit_5
	ret
equal6: 
	ldi R16, digit_6
	ret
equal7: 
	ldi R16, digit_7
	ret
equal8: 
	ldi R16, digit_8
	ret
equal9: 
	ldi R16, digit_9
	ret


; Subroutine to display a digit on the seven-segment display
; runs two times, first send tens to display, then send ones 
display:
; Backup used registers on stack
	push R16
	push R17
	in R17, SREG
	push R17
	ldi R17, 8 ; loop --> test all 8 bits
	nop
	nop
loop:
	rol R16 ; rotate left through Carry
	BRCS set_ser_in_1 ; branch if Carry is set

	; Put code here to set SER to 0
	cbi PORTB, PB0 ; clear PB0 (SER)
	nop
	rjmp end
	set_ser_in_1:
		sbi PORTB, PB0 ; set PB0 (SER)
		nop

end:
	sbi PORTB, PB2 ; set PB2 (SRCLK)
	nop
	cbi PORTB, PB2 ; clear PB2 (SRCLK)
	nop

	dec R17
	brne loop
; Restore registers from stack
	pop R17
	out SREG, R17
	pop R17
	pop R16
	cbi PORTB, PB0 ; clear pb0, ser
	nop
	ret
