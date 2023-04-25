    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
    CONFIG  FOSC = INTIO67
    CONFIG  WDTEN = OFF

;========== Variable definitions ==========
;<editor-fold defaultstate="collapsed" desc="Variables">
   cblock 0x20
	outer_loop_1;0x20
	inner_loop_1;0x21
	sensor_l;0x22
	sensor_m;0x23
	sensor_r;0x24
	ADC_result_l;0x25
	ADC_result_r;0x26
	ADC_result_m;0x27
	mode_select;0x28
	mode_select_flag;0x29
	SSD;0x30
	outer_loop_333;0x31
	inner_loop_333;0x32
	black_h_l;0x33
	blue_h_l;0x34
	green_h_l;0x35
	red_h_l;0x36
	black_h_m;0x37
	blue_h_m;0x38
	green_h_m;0x39
	red_h_m;0x40
	black_h_r;0x41
	blue_h_r;0x42
	green_h_r;0x43
	red_h_r;0x44
	nav_reg;0x45
	counter1;0x46
	counter2;0x46
	endc
 ;</editor-fold>
;========== Reset vector ==========
	org 	00h
	goto 	Setup  
    
;========== Interrupt vector ==========
	org 	08h
	BTFSC	mode_select_flag,startup_mode_flag
	GOTO 	state_change_ISR 
	GOTO	register_dump_isr
	
;========== Initialization ==========
;<editor-fold defaultstate="collapsed" desc="Setup">

Setup
    ; Initialize variables
    CLRF	outer_loop_1
    CLRF	inner_loop_1
    CLRF	sensor_l
    CLRF	sensor_m
    CLRF	sensor_r
    CLRF	mode_select
    CLRF	mode_select_flag
    CLRF	SSD
    CLRF	ADC_result_l
    CLRF	ADC_result_r
    CLRF	ADC_result_m
    CLRF	outer_loop_333
    CLRF	inner_loop_333
    CLRF	black_h_l
    CLRF	blue_h_l
    CLRF	green_h_l	    
    CLRF	red_h_l
    CLRF	black_h_m
    CLRF	blue_h_m
    CLRF	green_h_m
    CLRF	red_h_m
    CLRF	black_h_r
    CLRF	blue_h_r
    CLRF	green_h_r
    CLRF	red_h_r
    CLRF	nav_reg
    CLRF	counter1
    CLRF	counter2

    
startup_mode		    EQU	    0
mode_select_mode	    EQU	    1
calibration_mode	    EQU	    2
colour_detector_mode	    EQU	    3
navigation_mode		    EQU	    4

startup_mode_flag	    EQU	    0
mode_selsct_mode_flag	    EQU	    1
calibiration_mode_flag	    EQU	    2
colour_derector_mode_flag   EQU	    3
navigation_mode_flag	    EQU	    4
	    
l	EQU	2
m	EQU	1
r	EQU	0
	
    MOVLW	D'1'
    MOVWF	counter1
    MOVLW	D'1'
    MOVWF	counter2
	    
    BSF		mode_select_flag,startup_mode_flag
    
    ; Initialize Ports
    MOVLB	0xF
    
    CLRF	PORTA	    ;PORT-Write/Read
    CLRF	LATA	    ;LAT-Wrire to PORT/Read from LAT register
    CLRF	ANSELA	    ;ANSEL-'1'=analog pin/'0'=digital pin
    CLRF	TRISA	    ;TRIS-'1'=input pin/'0'=output pin
    
    CLRF	PORTB
    CLRF	LATB
    CLRF	ANSELB
    CLRF	TRISB
    
    CLRF	PORTC
    CLRF	LATC
    CLRF	ANSELC
    CLRF	TRISC
    
    CLRF	PORTD
    CLRF	LATD
    CLRF	ANSELD
    CLRF	TRISD
    
    CLRF	PORTE	    ;PORT-Write/Read
    CLRF	LATE	    ;LAT-Wrire to PORT/Read from LAT register
    CLRF	ANSELE	    ;ANSEL-'1'=analog pin/'0'=digital pin
    CLRF	TRISE	    ;TRIS-'1'=input pin/'0'=output pin
    
    ;Interupt ports
    BSF		TRISB,0
    BCF 	ANSELB,0
    
    ; Initialize Interrupts
    CLRF	INTCON	
    BSF 	INTCON,INT0IE
    BSF		INTCON,GIE
    
    ; Initialize oscillator
    BSF	    OSCCON,IRCF0
    BCF	    OSCCON,IRCF1
    BSF	    OSCCON,IRCF2	; IRCF<2:0> = '101' = 4Mhz

    ; Initialize ADC
    BSF 	TRISC,3		;RC3 = input
    BSF 	ANSELC,3 	;RC3 = analog
    
    BSF 	TRISC,4		;RC4 = input
    BSF 	ANSELC,4 	;RC4 = analog
    
    BSF 	TRISC,5		;RC5 = input
    BSF 	ANSELC,5	;RC5 = analog
    
    CLRF	ADRESH
    MOVLW 	B'00101111'	;left justify
    MOVWF 	ADCON2		;& 12 TAD ACQ time
    MOVLW 	B'00000000'
    MOVWF 	ADCON1		;ADC ref = Vdd, Vss
    MOVLB	0x00
    GOTO	startup_transition
 ;</editor-fold>
; -------------	
; PROGRAM START	
; -------------

startup_transition
    ;GOTO	cal_black_l		;uncomment for adc test
    BTFSC	mode_select_flag,startup_mode_flag
    GOTO	startup
    GOTO	mode
    
startup 
    CALL	SSD_clear
    MOVLW	B'11111111'
    MOVFF	WREG,SSD
    CALL	SSD_display	;on
    CALL	delay_loop_333
    CALL	SSD_clear
    CALL	delay_loop_333
    
    BTFSC	mode_select_flag,startup_mode_flag
    GOTO	startup
    GOTO	mode
    
;new line of code
;<editor-fold defaultstate="collapsed" desc="Main Menu">

mode
    MOVLB	0xF
    ;Initialize PORTB
    CLRF	PORTB
    CLRF	LATB
    CLRF	ANSELB
    CLRF	TRISB
    
   ;Disable Interrupts
    CLRF	INTCON	
    BCF 	INTCON,INT0IE
    BCF		INTCON,GIE
    
    ;Set up port b for digital inputs
    BSF		TRISB,0
    BCF		ANSELB,0
    MOVLB	0x00
    
show_c
    MOVLW	B'01001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    NOP
    CALL	delay_loop_333
    BTFSS	PORTB,0
    GOTO	show_c
    GOTO	show_c_transition
    
show_c_transition
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    BTFSS	PORTB,0
    GOTO	show_d
    GOTO	show_c_buffer
    
show_c_buffer
    BTFSC	PORTB,0
    BRA		show_c_buffer
    CALL	initialize_RGBs
    GOTO	calibration_buffer_black_l
    
show_d
    MOVLW	B'00111101'
    MOVFF	WREG,SSD
    CALL	SSD_display
    BTFSS	PORTB,0
    GOTO	show_d
    GOTO	show_d_transition
    
show_d_transition
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'00111101'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'00111101'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'00111101'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'00111101'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    BTFSS	PORTB,0
    GOTO	show_n
    GOTO	show_d_buffer
    
show_d_buffer
    BTFSC	PORTB,0
    BRA		show_d_buffer
    GOTO	detect_black_l
    
show_n
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    BTFSS	PORTB,0
    GOTO	show_n
    GOTO	show_n_transition
    
show_n_transition
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    BTFSS	PORTB,0
    GOTO	show_c
    GOTO	show_n_buffer
    
show_n_buffer
    BTFSC	PORTB,0
    BRA		show_n_buffer
    GOTO	nav_mode
 ;</editor-fold>
;========== Calibration ==========
;<editor-fold defaultstate="collapsed" desc="Calibration Sequence">

calibration_buffer_black_l
    CALL	show_black_l
    BTFSS	PORTB,0
    GOTO	calibration_buffer_black_l
    GOTO	cal_black_l
    

cal_black_l
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	ADCpoll_l
    ;GOTO	cal_black_m	    ;uncomment and break for adc test
    MOVFF	ADC_result_l,WREG
    ADDLW	D'5'
    MOVFF	WREG,black_h_l
    CLRF	ADC_result_l
    CALL	show_black_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_black_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_black_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    GOTO	calibration_buffer_blue_l
    
calibration_buffer_blue_l
    CALL	show_blue_l
    BTFSS	PORTB,0
    GOTO	calibration_buffer_blue_l
    GOTO	cal_blue_l
    
cal_blue_l
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	ADCpoll_l
    MOVFF	ADC_result_l,WREG
    ADDLW	D'5'
    MOVFF	WREG,blue_h_l
    CLRF	ADC_result_l
    CALL	show_blue_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_blue_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_blue_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    GOTO	calibration_buffer_green_l
    
calibration_buffer_green_l
    CALL	show_green_l
    BTFSS	PORTB,0
    GOTO	calibration_buffer_green_l
    GOTO	cal_green_l
    
cal_green_l
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	ADCpoll_l
    MOVFF	ADC_result_l,WREG
    ADDLW	D'5'
    MOVFF	WREG,green_h_l
    CLRF	ADC_result_l
    CALL	show_green_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_green_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_green_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    GOTO	calibration_buffer_red_l
    
calibration_buffer_red_l
    CALL	show_red_l
    BTFSS	PORTB,0
    GOTO	calibration_buffer_red_l
    GOTO	cal_red_l
    
cal_red_l
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	ADCpoll_l
    MOVFF	ADC_result_l,WREG
    ADDLW	D'5'
    MOVFF	WREG,red_h_l
    CLRF	ADC_result_l
    CALL	show_red_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_red_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    CALL	show_red_l
    CALL	delay_loop_333
    CALL	clear_RGB_l
    CALL	delay_loop_333
    GOTO	calibration_buffer_black_m
    
calibration_buffer_black_m
    CALL	show_black_m
    BTFSS	PORTB,0
    GOTO	calibration_buffer_black_m
    GOTO	cal_black_m
    
cal_black_m
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	ADCpoll_m
    ;GOTO	cal_black_r		;uncomment and break for adc test
    MOVFF	ADC_result_m,WREG
    ADDLW	D'5'
    MOVFF	WREG,black_h_m
    CLRF	ADC_result_m
    CALL	show_black_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_black_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_black_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    GOTO	calibration_buffer_blue_m
    
calibration_buffer_blue_m
    CALL	show_blue_m
    BTFSS	PORTB,0
    GOTO	calibration_buffer_blue_m
    GOTO	cal_blue_m
    
cal_blue_m
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	ADCpoll_m
    MOVFF	ADC_result_m,WREG
    ADDLW	D'5'
    MOVFF	WREG,blue_h_m
    CLRF	ADC_result_m
    CALL	show_blue_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_blue_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_blue_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    GOTO	calibration_buffer_green_m
    
calibration_buffer_green_m
    CALL	show_green_m
    BTFSS	PORTB,0
    GOTO	calibration_buffer_green_m
    GOTO	cal_green_m
    
cal_green_m
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	ADCpoll_m
    MOVFF	ADC_result_m,WREG
    ADDLW	D'5'
    MOVFF	WREG,green_h_m
    CLRF	ADC_result_m
    CALL	show_green_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_green_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_green_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    GOTO	calibration_buffer_red_m
    
calibration_buffer_red_m
    CALL	show_red_m
    BTFSS	PORTB,0
    GOTO	calibration_buffer_red_m
    GOTO	cal_red_m
    
cal_red_m
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	ADCpoll_m
    MOVFF	ADC_result_m,WREG
    ADDLW	D'5'
    MOVFF	WREG,red_h_m
    CLRF	ADC_result_m
    CALL	show_red_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_red_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    CALL	show_red_m
    CALL	delay_loop_333
    CALL	clear_RGB_m
    CALL	delay_loop_333
    GOTO	calibration_buffer_black_r
    
calibration_buffer_black_r
    CALL	show_black_r
    BTFSS	PORTB,0
    GOTO	calibration_buffer_black_r
    GOTO	cal_black_r
    
cal_black_r
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	ADCpoll_r
    ;GOTO	cal_black_l		;uncomment and break for adc test
    MOVFF	ADC_result_r,WREG
    ADDLW	D'5'
    MOVFF	WREG,black_h_r
    CLRF	ADC_result_r
    CALL	show_black_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_black_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_black_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    GOTO	calibration_buffer_blue_r
    
calibration_buffer_blue_r
    CALL	show_blue_r
    BTFSS	PORTB,0
    GOTO	calibration_buffer_blue_r
    GOTO	cal_blue_r
    
cal_blue_r
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	ADCpoll_r
    MOVFF	ADC_result_r,WREG
    ADDLW	D'5'
    MOVFF	WREG,blue_h_r
    CLRF	ADC_result_r
    CALL	show_blue_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_blue_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_blue_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    GOTO	calibration_buffer_green_r
    
calibration_buffer_green_r
    CALL	show_green_r
    BTFSS	PORTB,0
    GOTO	calibration_buffer_green_r
    GOTO	cal_green_r
    
cal_green_r
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	ADCpoll_r
    MOVFF	ADC_result_r,WREG
    ADDLW	D'5'
    MOVFF	WREG,green_h_r
    CLRF	ADC_result_r
    CALL	show_green_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_green_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_green_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    GOTO	calibration_buffer_red_r
    
calibration_buffer_red_r
    CALL	show_red_r
    BTFSS	PORTB,0
    GOTO	calibration_buffer_red_r
    GOTO	cal_red_r
    
cal_red_r
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	ADCpoll_r
    MOVFF	ADC_result_r,WREG
    ADDLW	D'5'
    MOVFF	WREG,red_h_r
    CLRF	ADC_result_r
    CALL	show_red_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_red_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    CALL	show_red_r
    CALL	delay_loop_333
    CALL	clear_RGB_r
    CALL	delay_loop_333
    GOTO	mode
;</editor-fold>
;========== Colour Detector ==========
;<editor-fold defaultstate="collapsed" desc="Colour Detector">
detect_black_l
    CALL	initialize_RGBs
    CALL	ADCpoll_l
    CLRF	WREG
    MOVFF	black_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_blue_l
    CALL	show_black_l
    GOTO	detect_black_m
    
detect_blue_l
    CLRF	WREG
    MOVFF	blue_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_green_l
    CALL	show_blue_l
    GOTO	detect_black_m
    
detect_green_l
    CLRF	WREG
    MOVFF	green_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_red_l
    CALL	show_green_l
    GOTO	detect_black_m
    
detect_red_l
    CLRF	WREG
    MOVFF	red_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_white_l
    CALL	show_red_l
    GOTO	detect_black_m
    
detect_white_l
    CALL	show_white_l
    GOTO	detect_black_m
    
detect_black_m
    CALL	ADCpoll_m
    CLRF	WREG
    MOVFF	black_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_blue_m
    CALL	show_black_m
    GOTO	detect_black_r
    
detect_blue_m
    CLRF	WREG
    MOVFF	blue_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_green_m
    CALL	show_blue_m
    GOTO	detect_black_r
    
detect_green_m
    CLRF	WREG
    MOVFF	green_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_red_m
    CALL	show_green_m
    GOTO	detect_black_r
    
detect_red_m
    CLRF	WREG
    MOVFF	red_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_white_m
    CALL	show_red_m
    GOTO	detect_black_r
    
detect_white_m
    CALL	show_white_m
    GOTO	detect_black_r
    
detect_black_r
    CALL	ADCpoll_r
    CLRF	WREG
    MOVFF	black_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_blue_r
    CALL	show_black_r
    GOTO	colour_detector_buffer
    
detect_blue_r
    CLRF	WREG
    MOVFF	blue_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_green_r
    CALL	show_blue_r
    GOTO	colour_detector_buffer
    
detect_green_r
    CLRF	WREG
    MOVFF	green_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_red_r
    CALL	show_green_r
    GOTO	colour_detector_buffer
    
detect_red_r
    CLRF	WREG
    MOVFF	red_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_white_r
    CALL	show_red_r
    GOTO	colour_detector_buffer
    
detect_white_r
    CALL	show_white_r
    GOTO	colour_detector_buffer
    
colour_detector_buffer
    BTFSS	PORTB,0
    GOTO	detect_black_l
    GOTO	mode
;</editor-fold>
;========== LLI ==========
;<editor-fold defaultstate="collapsed" desc="Navigation Menu">

nav_mode
    MOVLB	0xF
    ;Initialize PORTB
    CLRF	PORTB
    CLRF	LATB
    CLRF	ANSELB
    CLRF	TRISB
    
   ;Disable Interrupts
    CLRF	INTCON	
    BCF 	INTCON,INT0IE
    BCF		INTCON,GIE
    
    ;Set up port b for digital inputs
    BSF		TRISB,0
    BCF		ANSELB,0
    MOVLB	0x00
    
show_black
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    NOP
    CALL	delay_loop_333
    BTFSS	PORTB,0
    GOTO	show_black
    GOTO	show_black_transition
    
show_black_transition
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    BTFSS	PORTB,0
    GOTO	show_blue
    GOTO	show_black_buffer
    
show_black_buffer
    BTFSC	PORTB,0
    BRA		show_black_buffer
    GOTO	check_black_l
    
show_blue
    MOVLW	B'01111111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    BTFSS	PORTB,0
    GOTO	show_blue
    GOTO	show_blue_transition
    
show_blue_transition
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01111111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    MOVLW	B'01111111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01111111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    MOVLW	B'01111111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    BTFSS	PORTB,0
    GOTO	show_green
    GOTO	show_blue_buffer
    
show_blue_buffer
    BTFSC	PORTB,0
    BRA		show_blue_buffer
    GOTO	check_blue_l
    
show_green
    MOVLW	B'01011111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    BTFSS	PORTB,0
    GOTO	show_green
    GOTO	show_green_transition
    
show_green_transition
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01011111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    MOVLW	B'01011111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01011111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    MOVLW	B'01011111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    BTFSS	PORTB,0
    GOTO	show_red
    GOTO	show_green_buffer
    
show_green_buffer
    BTFSC	PORTB,0
    BRA		show_green_buffer
    GOTO	check_green_l
    
show_red
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    BTFSS	PORTB,0
    GOTO	show_red
    GOTO	show_red_transition
    
show_red_transition
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    CALL	delay_loop_333
    
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL	delay_loop_333
    
    CALL	SSD_clear
    
    BTFSS	PORTB,0
    GOTO	show_black
    GOTO	show_red_buffer
    
show_red_buffer
    BTFSC	PORTB,0
    BRA		show_red_buffer
    GOTO	check_red_l
 ;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Navigation State">
  
check_black_l
    ;Interupt ports
    BSF		TRISB,0
    BCF 	ANSELB,0
    
    ; Initialize Interrupts
    CLRF	INTCON	
    BSF 	INTCON,INT0IE
    BSF		INTCON,GIE
 
    CALL	ADCpoll_l
    MOVFF	black_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	clear_black_l
    BSF		nav_reg,l
    GOTO	check_black_m
    
clear_black_l
    BCF		nav_reg,l
    
check_black_m
    CALL	ADCpoll_m
    MOVFF	black_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	clear_black_l
    BSF		nav_reg,m
    GOTO	check_black_r
    
clear_black_m
    BCF		nav_reg,m
    
check_black_r
    CALL	ADCpoll_r
    MOVFF	black_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	clear_black_r
    BSF		nav_reg,r
    GOTO	nav_black
    
clear_black_r
    BCF		nav_reg,r
    GOTO	nav_black
    
check_blue_l
    ;Interupt ports
    BSF		TRISB,0
    BCF 	ANSELB,0
    
    ; Initialize Interrupts
    CLRF	INTCON	
    BSF 	INTCON,INT0IE
    BSF		INTCON,GIE
    
    CALL	ADCpoll_l
    MOVFF	blue_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	clear_blue_l
    MOVFF	black_h_l,WREG
    CPFSGT	ADC_result_l
    GOTO	clear_blue_l
    BSF		nav_reg,l
    GOTO	check_blue_m
    
clear_blue_l
    BCF		nav_reg,l
    
check_blue_m
    CALL	ADCpoll_m
    MOVFF	blue_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	clear_blue_m
    MOVFF	black_h_m,WREG
    CPFSGT	ADC_result_m
    GOTO	clear_blue_m
    BSF		nav_reg,m
    GOTO	check_blue_r
    
clear_blue_m
    BCF		nav_reg,m
    
check_blue_r
    CALL	ADCpoll_r
    MOVFF	blue_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	clear_blue_r
    MOVFF	black_h_r,WREG
    CPFSGT	ADC_result_r
    GOTO	clear_blue_r
    BSF		nav_reg,r
    GOTO	nav_blue
    
clear_blue_r
     BCF	nav_reg,r
     GOTO	nav_blue
    
check_green_l
     ;Interupt ports
    BSF		TRISB,0
    BCF 	ANSELB,0
    
    ; Initialize Interrupts
    CLRF	INTCON	
    BSF 	INTCON,INT0IE
    BSF		INTCON,GIE
     
    CALL	ADCpoll_l
    MOVFF	green_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	clear_green_l
    MOVFF	blue_h_l,WREG
    CPFSGT	ADC_result_l
    GOTO	clear_green_l
    BSF		nav_reg,l
    GOTO	check_green_m
    
clear_green_l
    BCF		nav_reg,l
    GOTO	check_green_m
    
check_green_m
    CALL	ADCpoll_m
    MOVFF	green_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	clear_green_m
    MOVFF	blue_h_m,WREG
    CPFSGT	ADC_result_m
    GOTO	clear_green_m
    BSF		nav_reg,m
    GOTO	check_green_r
    
clear_green_m
    BCF		nav_reg,m
    GOTO	check_green_r

check_green_r
    CALL	ADCpoll_r
    MOVFF	green_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	clear_green_r
    MOVFF	blue_h_r,WREG
    CPFSGT	ADC_result_r
    GOTO	clear_green_r
    BSF		nav_reg,r
    GOTO	nav_green
    
clear_green_r
    BCF		nav_reg,r
    GOTO	nav_green
    
check_red_l
    ;Interupt ports
    BSF		TRISB,0
    BCF 	ANSELB,0
    
    ; Initialize Interrupts
    CLRF	INTCON	
    BSF 	INTCON,INT0IE
    BSF		INTCON,GIE
    
    CALL	ADCpoll_l
    MOVFF	red_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	clear_red_l
    MOVFF	green_h_l,WREG
    CPFSGT	ADC_result_l
    GOTO	clear_red_l
    BSF		nav_reg,l
    GOTO	check_red_m
    
clear_red_l
    BCF		nav_reg,l
    
check_red_m
    CALL	ADCpoll_m
    MOVFF	red_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	clear_red_m
    MOVFF	green_h_m,WREG
    CPFSGT	ADC_result_m
    GOTO	clear_red_m
    BSF		nav_reg,m
    GOTO	check_red_r
    
clear_red_m
    BCF		nav_reg,m
    
check_red_r
    CALL	ADCpoll_r
    MOVFF	red_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	clear_red_r
    MOVFF	green_h_r,WREG
    CPFSGT	ADC_result_r
    GOTO	clear_red_r
    BSF		nav_reg,r
    GOTO	nav_red
    
clear_red_r
    BCF		nav_reg,r
    GOTO	nav_red
    
nav_black
    DECFSZ	counter1
    GOTO	nav_black_start
    GOTO	nav_black_inner_loop

nav_black_inner_loop
    MOVLW	D'255'
    MOVWF	counter1
    DECFSZ	counter2
    GOTO	nav_black
    GOTO	mode
    
nav_black_start
    BTFSS	nav_reg,l
    GOTO	err_t_left_str_str_black	;l=0
    GOTO	t_right_err_str_stop_black		;l=1
    
err_t_left_str_str_black
    BTFSS	nav_reg,m
    GOTO	error_turn_left_black	;l=0,m=0
    GOTO	straight_straight_black	;l=0,m=1
    
t_right_err_str_stop_black
    BTFSS	nav_reg,m
    GOTO	turn_right_error_black	;l=1,m=0
    GOTO	straight_stop_black		;l=1,m=0
    
error_turn_left_black
    BTFSS	nav_reg,r
    GOTO	error_black
    GOTO	turn_left_black
    
straight_straight_black
    BTFSS	nav_reg,r
    GOTO	straight_black
    GOTO	straight_black
    
turn_right_error_black
    BTFSS	nav_reg,r
    GOTO	turn_right_black
    GOTO	error_black
    
straight_stop_black	
    BTFSS	nav_reg,r
    GOTO	straight_black
    GOTO	stop_black
    
error_black
    MOVLW	B'01001111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_black_l
    
turn_left_black
    MOVLW	B'00001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_black_l
    
straight_black
    MOVLW	B'01011011'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_black_l
    
turn_right_black
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_black_l
    
stop_black
    MOVLW	B'00110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_black_l

nav_blue
    DECFSZ	counter1
    GOTO	nav_blue_start
    GOTO	nav_blue_inner_loop

nav_blue_inner_loop
    MOVLW	D'255'
    MOVWF	counter1
    DECFSZ	counter2
    GOTO	nav_blue
    GOTO	mode
    
nav_blue_start
    BTFSS	nav_reg,l
    GOTO	err_t_left_str_str_blue	    ;l=0
    GOTO	t_right_err_str_stop_blue	    ;l=1
    
err_t_left_str_str_blue
    BTFSS	nav_reg,m
    GOTO	error_turn_left_blue		;l=0,m=0
    GOTO	straight_straight_blue	;l=0,m=1
    
t_right_err_str_stop_blue
    BTFSS	nav_reg,m
    GOTO	turn_right_error_blue	;l=1,m=0
    GOTO	straight_stop_blue		;l=1,m=0
    
error_turn_left_blue
    BTFSS	nav_reg,r
    GOTO	error_blue
    GOTO	turn_left_blue
    
straight_straight_blue
    BTFSS	nav_reg,r
    GOTO	straight_blue
    GOTO	straight_blue
    
turn_right_error_blue
    BTFSS	nav_reg,r
    GOTO	turn_right_blue
    GOTO	error_blue
    
straight_stop_blue	
    BTFSS	nav_reg,r
    GOTO	straight_blue
    GOTO	stop_blue
    
error_blue
    MOVLW	B'01001111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_blue_l
    
turn_left_blue
    MOVLW	B'00001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_blue_l
    
straight_blue
    MOVLW	B'01011011'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_blue_l
    
turn_right_blue
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_blue_l
    
stop_blue
    MOVLW	B'00110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_blue_l
    
nav_green
    DECFSZ	counter1
    GOTO	nav_green_start
    GOTO	nav_green_inner_loop

nav_green_inner_loop
    MOVLW	D'20'
    MOVWF	counter1
    DECFSZ	counter2
    GOTO	nav_green_start
    GOTO	mode
    
nav_green_start
    BTFSS	nav_reg,l
    GOTO	err_t_left_str_str_green	;l=0
    GOTO	t_right_err_str_stop_green		;l=1
    
err_t_left_str_str_green
    BTFSS	nav_reg,m
    GOTO	error_turn_left_green	;l=0,m=0
    GOTO	straight_straight_green	;l=0,m=1
    
t_right_err_str_stop_green
    BTFSS	nav_reg,m
    GOTO	turn_right_error_green	;l=1,m=0
    GOTO	straight_stop_green		;l=1,m=0
    
error_turn_left_green
    BTFSS	nav_reg,r
    GOTO	error_green
    GOTO	turn_left_green
    
straight_straight_green
    BTFSS	nav_reg,r
    GOTO	straight_green
    GOTO	straight_green
    
turn_right_error_green
    BTFSS	nav_reg,r
    GOTO	turn_right_green
    GOTO	error_green
    
straight_stop_green
    BTFSS	nav_reg,r
    GOTO	straight_green
    GOTO	stop_green
    
error_green
    MOVLW	B'01001111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_green_l
    
turn_left_green
    MOVLW	B'00001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_green_l
    
straight_green
    MOVLW	B'01011011'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_green_l
    
turn_right_green
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_green_l
    
stop_green
    MOVLW	B'00110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_green_l
    
nav_red
    DECFSZ	counter1
    GOTO	nav_red_start
    GOTO	nav_red_inner_loop

nav_red_inner_loop
    MOVLW	D'255'
    MOVWF	counter1
    DECFSZ	counter2
    GOTO	nav_red
    GOTO	mode
    
nav_red_start
    BTFSS	nav_reg,l
    GOTO	err_t_left_str_str_red	;l=0
    GOTO	t_right_err_str_stop_red	;l=1
    
err_t_left_str_str_red
    BTFSS	nav_reg,m
    GOTO	error_turn_left_red	    ;l=0,m=0
    GOTO	straight_straight_red    ;l=0,m=1
    
t_right_err_str_stop_red
    BTFSS	nav_reg,m
    GOTO	turn_right_error_red	    ;l=1,m=0
    GOTO	straight_stop_red	    ;l=1,m=0
    
error_turn_left_red
    BTFSS	nav_reg,r
    GOTO	error_red
    GOTO	turn_left_red
    
straight_straight_red
    BTFSS	nav_reg,r
    GOTO	straight_red
    GOTO	straight_red
    
turn_right_error_red
    BTFSS	nav_reg,r
    GOTO	turn_right_red
    GOTO	error_red
    
straight_stop_red
    BTFSS	nav_reg,r
    GOTO	straight_red
    GOTO	stop_red
    
error_red
    MOVLW	B'01001111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_red_l
    
turn_left_red
    MOVLW	B'00001110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_red_l
    
straight_red
    MOVLW	B'01011011'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_red_l
    
turn_right_red
    MOVLW	B'01110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_red_l
    
stop_red
    MOVLW	B'00110111'
    MOVFF	WREG,SSD
    CALL	SSD_display
    GOTO	check_red_l
 ;</editor-fold>
;========== Interrupt service routines ==========
;<editor-fold defaultstate="collapsed" desc="Interrupt Service Routines">
state_change_ISR	;GIE = '0'
    NOP
    BCF		mode_select_flag,startup_mode_flag
    NOP
    BCF	    INTCON,INT0IF
    RETFIE	;GIE = '1'
    
register_dump_isr	;GIE = '0'
detect_black_l_isr
    CALL	initialize_RGBs
    CALL	ADCpoll_l
    CLRF	WREG
    MOVFF	black_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_blue_l_isr
    CALL	show_black_l
    GOTO	detect_black_m_isr
    
detect_blue_l_isr
    CLRF	WREG
    MOVFF	blue_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_green_l_isr
    CALL	show_blue_l
    GOTO	detect_black_m_isr
    
detect_green_l_isr
    CLRF	WREG
    MOVFF	green_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_red_l_isr
    CALL	show_green_l
    GOTO	detect_black_m_isr
    
detect_red_l_isr
    CLRF	WREG
    MOVFF	red_h_l,WREG
    CPFSLT	ADC_result_l
    GOTO	detect_white_l_isr
    CALL	show_red_l
    GOTO	detect_black_m_isr
    
detect_white_l_isr
    CALL	show_white_l
    GOTO	detect_black_m_isr
    
detect_black_m_isr
    CALL	ADCpoll_m
    CLRF	WREG
    MOVFF	black_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_blue_m_isr
    CALL	show_black_m
    GOTO	detect_black_r_isr
    
detect_blue_m_isr
    CLRF	WREG
    MOVFF	blue_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_green_m_isr
    CALL	show_blue_m
    GOTO	detect_black_r_isr
    
detect_green_m_isr
    CLRF	WREG
    MOVFF	green_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_red_m_isr
    CALL	show_green_m
    GOTO	detect_black_r_isr
    
detect_red_m_isr
    CLRF	WREG
    MOVFF	red_h_m,WREG
    CPFSLT	ADC_result_m
    GOTO	detect_white_m_isr
    CALL	show_red_m
    GOTO	detect_black_r_isr
    
detect_white_m_isr
    CALL	show_white_m
    GOTO	detect_black_r_isr
    
detect_black_r_isr
    CALL	ADCpoll_r
    CLRF	WREG
    MOVFF	black_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_blue_r_isr
    CALL	show_black_r
    GOTO	end_register_dump_isr
    
detect_blue_r_isr
    CLRF	WREG
    MOVFF	blue_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_green_r_isr
    CALL	show_blue_r
    GOTO	end_register_dump_isr
    
detect_green_r_isr
    CLRF	WREG
    MOVFF	green_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_red_r_isr
    CALL	show_green_r
    GOTO	end_register_dump_isr
    
detect_red_r_isr
    CLRF	WREG
    MOVFF	red_h_r,WREG
    CPFSLT	ADC_result_r
    GOTO	detect_white_r_isr
    CALL	show_red_r
    GOTO	end_register_dump_isr
    
detect_white_r_isr
    CALL	show_white_r
    GOTO	end_register_dump_isr
    
end_register_dump_isr
    BCF	    INTCON,INT0IF
    RETFIE	;GIE = '1'
;</editor-fold>
;========== Subroutines ==========
;<editor-fold defaultstate="collapsed" desc="Delay Subroutines">

delay_loop_1			
    MOVLW	0xAA
    MOVWF	outer_loop_1		
go_on_1					
    MOVLW	0xBB
    MOVWF	inner_loop_1
go_on_2
    DECFSZ	inner_loop_1,F	
    GOTO	go_on_2	
    DECFSZ	outer_loop_1,F
    GOTO	go_on_1	
    RETURN
    
delay_loop_333
    MOVLW	D'255'
    MOVWF	outer_loop_333		
go_on_1_333				
    MOVLW	D'216'
    MOVWF	inner_loop_333
go_on_2_333
    DECFSZ	inner_loop_333,F	
    GOTO	go_on_2_333
    DECFSZ	outer_loop_333,F
    GOTO	go_on_1_333
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="ADC Subroutines">
    ;ADC poll left sensor
ADCpoll_l
    MOVLB	0xF
    MOVLW 	B'00111101'	;AN15(RC3) enable (left)
    MOVWF 	ADCON0
    BSF		ADCON0,GO
    MOVLB	0x00
poll_l 
    BTFSC	ADCON0,GO ;done?
    BRA		poll_l
    MOVFF	ADRESH,WREG
    MOVWF	ADC_result_l
    RETURN
    
;ADC poll middle sensor
ADCpoll_m
    MOVLB	0xF
    MOVLW 	B'01000001'	;AN16(RC4) enable (middle)
    MOVWF 	ADCON0
    BSF		ADCON0,GO
    MOVLB	0x00
poll_m
    BTFSC	ADCON0,GO ;done?
    BRA		poll_m
    MOVFF	ADRESH,WREG
    MOVWF	ADC_result_m
    RETURN
    
;ADC poll right sensor
ADCpoll_r
    MOVLB	0xF
    MOVLW 	B'01000101'	;AN17(RC5) enable (right)
    MOVWF 	ADCON0
    BSF		ADCON0,GO
    MOVLB	0x00
poll_r
    BTFSC	ADCON0,GO ;done?
    BRA		poll_r
    MOVFF	ADRESH,WREG
    MOVWF	ADC_result_r
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="SSD Subroutines">
SSD_display
    CLRF	TRISD
    CLRF	ANSELD
    
    MOVFF	SSD,LATD
    NOP
    RETURN
    
SSD_clear
    CLRF	TRISD
    CLRF	ANSELD
    
    MOVLW	B'00000000'
    MOVFF	WREG,LATD
    NOP
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="RGB Subroutines">
initialize_RGBs
    MOVLB	0xF
    ;left
    BCF		PORTA,2
    BCF		PORTA,3
    BCF		PORTA,4
    
    BCF		LATA,2
    BCF		LATA,3
    BCF		LATA,4
    
    BCF		ANSELA,2
    BCF		ANSELA,3
    BCF		ANSELA,4
    
    BCF		TRISA,2
    BCF		TRISA,3
    BCF		TRISA,4
    
    
    
    ;middle
    BCF		PORTE,0
    BCF		PORTE,1
    BCF		PORTE,2
    
    BCF		LATE,0
    BCF		LATE,1
    BCF		LATE,2
    
    BCF		ANSELE,0
    BCF		ANSELE,1
    BCF		ANSELE,2
    
    BCF		TRISE,0
    BCF		TRISE,1
    BCF		TRISE,2
    
    ;right
    BCF		PORTA,5
    BCF		PORTA,6
    BCF		PORTA,7
    
    BCF		LATA,5
    BCF		LATA,6
    BCF		LATA,7
    
    BCF		ANSELA,5
    BCF		ANSELA,6
    BCF		ANSELA,7
    
    BCF		TRISA,5
    BCF		TRISA,6
    BCF		TRISA,7
    
    MOVLB	0x00
    RETURN
    
show_black_l
    MOVLB	0xF
    BSF		LATA,2
    BCF		LATA,3
    BSF		LATA,4
    MOVLB	0x00
    RETURN
    
show_blue_l
    MOVLB	0xF
    BcF		LATA,2
    BCF		LATA,3
    BSF		LATA,4
    MOVLB	0x00
    RETURN
    
show_green_l
    MOVLB	0xF
    BSF		LATA,2
    BSF		LATA,3
    BCF		LATA,4
    MOVLB	0x00
    RETURN
    
show_red_l
    MOVLB	0xF
    BSF		LATA,2
    BCF		LATA,3
    BCF		LATA,4
    MOVLB	0x00
    RETURN
    
show_white_l
    MOVLB	0xF
    BSF		LATA,2
    BSF		LATA,3
    BSF		LATA,4
    MOVLB	0x00
    RETURN
    
show_black_m
    MOVLB	0xF
    BSF		LATE,0
    BCF		LATE,1
    BSF		LATE,2
    MOVLB	0x00
    RETURN
    
show_blue_m
    MOVLB	0xF
    BcF		LATE,0
    BCF		LATE,1
    BSF		LATE,2
    MOVLB	0x00
    RETURN
    
show_green_m
    MOVLB	0xF
    BSF		LATE,0
    BSF		LATE,1
    BCF		LATE,2
    MOVLB	0x00
    RETURN
    
show_red_m
    MOVLB	0xF
    BSF		LATE,0
    BCF		LATE,1
    BCF		LATE,2
    MOVLB	0x00
    RETURN
    
show_white_m
    MOVLB	0xF
    BSF		LATE,0
    BSF		LATE,1
    BSF		LATE,2
    MOVLB	0x00
    RETURN
    
show_black_r
    MOVLB	0xF
    BSF		LATA,5
    BCF		LATA,6
    BSF		LATA,7
    MOVLB	0x00
    RETURN
    
show_blue_r
    MOVLB	0xF
    BcF		LATA,5
    BCF		LATA,6
    BSF		LATA,7
    MOVLB	0x00
    RETURN
    
show_green_r
    MOVLB	0xF
    BSF		LATA,5
    BSF		LATA,6
    BCF		LATA,7
    MOVLB	0x00
    RETURN
    
show_red_r
    MOVLB	0xF
    BSF		LATA,5
    BCF		LATA,6
    BCF		LATA,7
    MOVLB	0x00
    RETURN
    
show_white_r
    MOVLB	0xF
    BSF		LATA,5
    BSF		LATA,6
    BSF		LATA,7
    MOVLB	0x00
    RETURN
    
clear_RGB_l
    MOVLB	0xF
    BCF		LATA,2
    BCF		LATA,3
    BCF		LATA,4
    MOVLB	0x00
    RETURN
    
clear_RGB_m
    MOVLB	0xF
    BCF		LATE,0
    BCF		LATE,1
    BCF		LATE,2
    MOVLB	0x00
    RETURN
    
clear_RGB_r
    MOVLB	0xF
    BCF		LATA,5
    BCF		LATA,6
    BCF		LATA,7
    MOVLB	0x00
    RETURN
;</editor-fold>
    end
   