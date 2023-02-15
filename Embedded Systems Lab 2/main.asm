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

.def value = r20 
.def tens = r21
.def ones = r22
.def temp = r18
;.def count = R20 ; counter 

; Set push button (PB3) as input
cbi DDRB, 3

; Set SER (PB0), RCLK (PB1), and SRCLK (PB2) as outputs
sbi DDRB, 0
sbi DDRB, 1
sbi DDRB, 2
ldi value, 0x00
; Main loop
reset: 
	ldi r16, digit_0
	rcall display
	rcall display
	; Put code here to generate RCLK pulse
	sbi PORTB, PB1 ; set PB1 (RCLK)
	cbi PORTB, PB1 ; clear PB1 (RCLK)

main:
	; Read push button state
	in R17, PINB
	sbrc R17, 3 ; check if pb3 is cleared. PB3 is logic low on button press and logic high on button release
	rcall rightbuttonpressed
	rjmp main ; if push button is not pressed, wait


; Debounce push button
; TODO: etermine how long the button has been pressed to trigger a reset
rightbuttonpressed:
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay
	rcall delay

	in R17, PINB
	sbrc R17, 3
	rcall buttonReleased
	rjmp main
	
	

buttonReleased:
	inc value 
	rcall findValue ; find the tens and ones place

	displayTens: 
		ldi tens, 0
		mov temp, tens
		rcall lookup
	displayOnes:
		ldi ones, 3
		mov temp, ones
		rcall lookup
	; Put code here to generate RCLK pulse
	sbi PORTB, PB1 ; set PB1 (RCLK)
	cbi PORTB, PB1 ; clear PB1 (RCLK)



	ret

findValue:
	ldi tens, 0x00 ; quotient
	mov ones, r20  ; remainder
	div: 
		inc r17
		subi r16, 10
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
ret

equal0: 
	ldi R16, digit_0
	rcall display
	rjmp main
equal1: 
	ldi R16, digit_1
	rcall display
	rjmp main 
equal2: 
	ldi R16, digit_2
	rcall display
	rjmp main
equal3: 
	ldi R16, digit_3
	rcall display
	rjmp main
equal4: 
	ldi R16, digit_4
	rcall display
	rjmp main
equal5: 
	ldi R16, digit_5
	rcall display
	rjmp main
equal6: 
	ldi R16, digit_6
	rcall display
	rjmp main
equal7: 
	ldi R16, digit_7
	rcall display
	rjmp main
equal8: 
	ldi R16, digit_8
	rcall display
	rjmp main
equal9: 
	ldi R16, digit_9
	rcall display
	rjmp main




; Subroutine to display a digit on the seven-segment display
; runs two times, first send tens to display, then send ones 
display:
; Backup used registers on stack
	push R16
	push R17
	in R17, SREG
	push R17
	ldi R17, 8 ; loop --> test all 8 bits
loop:
	rol R16 ; rotate left through Carry
	BRCS set_ser_in_1 ; branch if Carry is set

	; Put code here to set SER to 0
	cbi PORTB, PB0 ; clear PB0 (SER)

	rjmp end
	set_ser_in_1:
		sbi PORTB, PB0 ; set PB0 (SER)

end:
	sbi PORTB, PB2 ; set PB2 (SRCLK)
	cbi PORTB, PB2 ; clear PB2 (SRCLK)

	dec R17
	brne loop
; Restore registers from stack
	pop R17
	out SREG, R17
	pop R17
	pop R16
	ret
