    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
    CONFIG  FOSC = INTIO67
    CONFIG  WDTEN = OFF
    CONFIG  MCLRE = EXTMCLR       ; MCLR Pin Enable bit (MCLR pin enabled, RE3 input pin disabled)
    CONFIG  LVP = ON              ; Single-Supply ICSP Enable bit (Single-Supply ICSP enabled if MCLRE is also 1)
    
;========== Variable definitions ==========
;<editor-fold defaultstate="collapsed" desc="Variables">
   cblock 0x20
   ISR_reg;0x20
   i2c_adress;0x21
   i2c_data;0x22
   count1_10ms;0x23
   count2_10ms;0x24
   state;0x25
   bit_received;0x26
   letter;0x27
   word_checkH;0x28
   word_checkL;29
   race_col;30
   SSD;31
   outer_loop_333;32
   inner_loop_333;33
   i2c_letter_1;34  s
   i2c_letter_2;34  l
   i2c_letter_3;34  g
   i2c_letter_4;34  n 
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
	GOTO 	ISR_handler 
	
;========== Initialization ==========
;<editor-fold defaultstate="collapsed" desc="Setup">
Setup
;3 second delay
;    CALL    delay_loop_333
;    CALL    delay_loop_333
;    CALL    delay_loop_333
;    CALL    delay_loop_333
;    CALL    delay_loop_333
;    CALL    delay_loop_333
;    CALL    delay_loop_333
;    CALL    delay_loop_333
;    CALL    delay_loop_333

    CLRF    ISR_reg
    CLRF    i2c_adress
    CLRF    i2c_data
    CLRF    count1_10ms
    CLRF    count2_10ms
    CLRF    state
    CLRF    bit_received
    CLRF    letter
    CLRF    word_checkL
    CLRF    word_checkH
    CLRF    race_col
    CLRF    SSD
    CLRF    outer_loop_333
    CLRF    inner_loop_333
    CLRF    i2c_letter_1
    CLRF    i2c_letter_2
    CLRF    i2c_letter_3
    CLRF    i2c_letter_4
    CLRF    outer_loop_1
    CLRF    inner_loop_1
    CLRF    sensor_l
    CLRF    sensor_m
    CLRF    sensor_r
    CLRF    mode_select
    CLRF    mode_select_flag
    CLRF    SSD
    CLRF    ADC_result_l
    CLRF    ADC_result_r
    CLRF    ADC_result_m
    CLRF    outer_loop_333
    CLRF    inner_loop_333
    CLRF    black_h_l
    CLRF    blue_h_l
    CLRF    green_h_l	    
    CLRF    red_h_l
    CLRF    black_h_m
    CLRF    blue_h_m
    CLRF    green_h_m
    CLRF    red_h_m
    CLRF    black_h_r
    CLRF    blue_h_r
    CLRF    green_h_r
    CLRF    red_h_r
    CLRF    nav_reg
    CLRF    counter1
    CLRF    counter2

    
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
    
flash_333ms_isr	    EQU	    0
power_on	    EQU	    0
menu		    EQU	    1
program		    EQU	    2
follow_colour	    EQU	    3
calibrate	    EQU	    4
race		    EQU	    5
racing		    EQU	    6
time		    EQU	    7
red		    EQU	    3
green		    EQU	    2
blue		    EQU	    1
black		    EQU	    0
	    
    BCF	    ISR_reg,flash_333ms_isr
    
    CALL    ini_ports
    ;CALL    ini_external_interrupts
    CALL    ini_oscilator
    CALL    ini_ADC
    CALL    ini_async_transmit_recieve
    CALL    ini_I2C
    CALL    ini_menu
    CALL    ini_digital_inputs
    
    GOTO    start
 ;</editor-fold>
; -------------	
; PROGRAM START	
; -------------  
start
    BSF	    state,power_on 
    
states
    ;--------------State select------------
    ;BSF    state,power_on 
    ;BSF    state,menu
    ;BSF    state,program
    ;BSF    state,follow_colour
    ;BSF    state,calibrate
    ;BSF    state,race
    ;BSF    state,racing
    ;BSF    state,time
    ;--------------------------------------
    
    BTFSC   state,power_on 
    GOTO    power_on_state0
    BTFSC   state,menu
    GOTO    menu_state1
    BTFSC   state,program
    GOTO    program_state2
    BTFSC   state,follow_colour
    GOTO    follow_colour_state3
    BTFSC   state,calibrate
    GOTO    calibrate_state4
    BTFSC   state,race
    GOTO    race_state5
    ;BTFSC   state,racing
    ;GOTO    menu_state6
    BTFSC   state,time
    GOTO    time_state7
 
;<editor-fold defaultstate="collapsed" desc="Power on (State 0)">
power_on_state0
    CALL	SSD_clear
    MOVLW	B'00110011'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CLRF    word_checkL
    CLRF    word_checkH
    
    MOVLW   B'00001101'
    CALL    transmit
    MOVLW   'V'
    CALL    transmit
    MOVLW   'r'
    CALL    transmit
    MOVLW   'o'
    CALL    transmit
    MOVLW   'o'
    CALL    transmit
    MOVLW   'o'
    CALL    transmit
    MOVLW   'm'
    CALL    transmit
    MOVLW   '.'
    CALL    transmit
    MOVLW   '.'
    CALL    transmit
    MOVLW   '.'
    CALL    transmit
    MOVLW   B'00001101'
    CALL    transmit
    
power_on_transition
    BTFSS   word_checkL,0
    GOTO    power_on_transition
    BTFSS   state,menu
    GOTO    power_on_transition
    GOTO    states
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Menu (State 1)">
menu_state1
    CALL	SSD_clear
    MOVLW	B'01111110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    ;BCF	    state,menu
    CLRF    word_checkL
    CLRF    word_checkH
    
    CALL    display_menu
   
menu_transition
    BTFSC   state,program
    GOTO    states
    BTFSC   state,follow_colour
    GOTO    states
    BTFSC   state,calibrate
    GOTO    states
    BTFSC   state,race
    GOTO    states
    BTFSC   state,time
    GOTO    states
    GOTO    menu_transition

;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Program (State 2)">
program_state2
    CALL	SSD_clear
    MOVLW	B'00110000'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CLRF    word_checkL
    CLRF    word_checkH
    CLRF    i2c_adress
    CLRF    i2c_data
    
i2c_transmit_test
    BTFSC   word_checkL,6
    GOTO    states
    BTFSC   word_checkL,0
    GOTO    states
    GOTO    i2c_transmit_test
      
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Follow colour (State 3)">
follow_colour_state3
    CALL	SSD_clear
    MOVLW	B'01101101'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CLRF    word_checkL
    CLRF    word_checkH
       
colour_select
    BTFSC   word_checkH,6	    ;checks enter for r
    GOTO    states
    BTFSC   word_checkH,4	    ;checks enter for g
    GOTO    states
    BTFSC   word_checkH,2	    ;checks enter for b
    GOTO    states
    BTFSC   word_checkH,0	    ;checks enter for n
    GOTO    states
    BTFSC   word_checkL,0	    ;checks for boom
    GOTO    states
    GOTO    colour_select
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Calibrate (State 4)">
calibrate_state4
    CALL	SSD_clear
    MOVLW	B'01111001'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CLRF    word_checkL
    CLRF    word_checkH
    
calibration_buffer_black_l
    CALL	show_black_l
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    BTFSC	word_checkL,0
    GOTO	states
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
    GOTO    states
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Race (State 5)">
race_state5
    CALL	SSD_clear
    MOVLW	B'00110011'
    MOVFF	WREG,SSD
    CALL	SSD_display

    CLRF    word_checkL
    CLRF    word_checkH
    
race_mode_handler
    BTFSC   race_col,red
    GOTO    race_red
    BTFSC   race_col,blue
    GOTO    race_blue
    BTFSC   race_col,green
    GOTO    race_green
    BTFSC   race_col,black
    GOTO    race_black
    BTFSC   word_checkL,0
    GOTO    states
    GOTO    race_mode_handler
    
race_red
    CALL    racing_red
    GOTO    check_red_l
    
race_blue
    CALL    racing_blue
    GOTO    check_blue_l
    
race_green
    CALL    racing_green
    GOTO    check_green_l
    
race_black
    CALL    racing_black
    GOTO    check_black_l
    
check_black_l
    NOP
    NOP
    NOP
    
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
    NOP
    NOP
    NOP
    
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
    NOP
    NOP
    NOP
     
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
    NOP
    NOP
    NOP
    
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
    DECFSZ	counter2
    GOTO	nav_black
    GOTO	states
    
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
    DECFSZ	counter2
    GOTO	nav_blue
    GOTO	states
    
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
    DECFSZ	counter2
    GOTO	nav_green_start
    GOTO	states
    
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
    DECFSZ	counter2
    GOTO	nav_red
    GOTO	states
    
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
;<editor-fold defaultstate="collapsed" desc="Time (State 7)">
time_state7
    
    GOTO    states
;</editor-fold>
;========== Subroutines ==========
;<editor-fold defaultstate="collapsed" desc="RGB Subroutines">
initialize_RGBs
    MOVLB	0xF
    ;left
    BCF		PORTB,7
    BCF		PORTB,6
    BCF		PORTB,5
    
    BCF		LATB,7
    BCF		LATB,6
    BCF		LATB,5
    
    BCF		ANSELB,7
    BCF		ANSELB,6
    BCF		ANSELB,5
    
    BCF		TRISB,7
    BCF		TRISB,6
    BCF		TRISB,5
    
    
    
    ;middle
    BCF		PORTA,4
    BCF		PORTA,5
    BCF		PORTE,0
    
    BCF		LATA,4
    BCF		LATA,5
    BCF		LATE,0
    
    BCF		ANSELA,4
    BCF		ANSELA,5
    BCF		ANSELE,0
    
    BCF		TRISA,4
    BCF		TRISA,5
    BCF		TRISE,0
    
    ;right
    BCF		PORTA,7
    BCF		PORTA,6
    BCF		PORTC,0
    
    BCF		LATA,7
    BCF		LATA,6
    BCF		LATC,0
    
    BCF		ANSELA,7
    BCF		ANSELA,6
    BCF		ANSELC,0
    
    BCF		TRISA,7
    BCF		TRISA,6
    BCF		TRISC,0
    
    MOVLB	0x00
    RETURN
    
show_black_l
    MOVLB	0xF
    BSF		LATB,7
    BCF		LATB,6
    BSF		LATB,5
    MOVLB	0x00
    RETURN
    
show_blue_l
    MOVLB	0xF
    BcF		LATB,7
    BCF		LATB,6
    BSF		LATB,5
    MOVLB	0x00
    RETURN
    
show_green_l
    MOVLB	0xF
    BSF		LATB,7
    BSF		LATB,6
    BCF		LATB,5
    MOVLB	0x00
    RETURN
    
show_red_l
    MOVLB	0xF
    BSF		LATB,7
    BCF		LATB,6
    BCF		LATB,5
    MOVLB	0x00
    RETURN
    
show_white_l
    MOVLB	0xF
    BSF		LATB,7
    BSF		LATB,6
    BSF		LATB,5
    MOVLB	0x00
    RETURN
    
show_black_m
    MOVLB	0xF
    BSF		LATA,4
    BCF		LATA,5
    BSF		LATE,0
    MOVLB	0x00
    RETURN
    
show_blue_m
    MOVLB	0xF
    BcF		LATA,4
    BCF		LATA,5
    BSF		LATE,0
    MOVLB	0x00
    RETURN
    
show_green_m
    MOVLB	0xF
    BSF		LATA,4
    BSF		LATA,5
    BCF		LATE,0
    MOVLB	0x00
    RETURN
    
show_red_m
    MOVLB	0xF
    BSF		LATA,4
    BCF		LATA,5
    BCF		LATE,0
    MOVLB	0x00
    RETURN
    
show_white_m
    MOVLB	0xF
    BSF		LATA,4
    BSF		LATA,5
    BSF		LATE,0
    MOVLB	0x00
    RETURN
    
show_black_r
    MOVLB	0xF
    BSF		LATA,7
    BCF		LATA,6
    BSF		LATC,0
    MOVLB	0x00
    RETURN
    
show_blue_r
    MOVLB	0xF
    BcF		LATA,7
    BCF		LATA,6
    BSF		LATC,0
    MOVLB	0x00
    RETURN
    
show_green_r
    MOVLB	0xF
    BSF		LATA,7
    BSF		LATA,6
    BCF		LATC,0
    MOVLB	0x00
    RETURN
    
show_red_r
    MOVLB	0xF
    BSF		LATA,7
    BCF		LATA,6
    BCF		LATC,0
    MOVLB	0x00
    RETURN
    
show_white_r
    MOVLB	0xF
    BSF		LATA,7
    BSF		LATA,6
    BSF		LATC,0
    MOVLB	0x00
    RETURN
    
clear_RGB_l
    MOVLB	0xF
    BCF		LATB,7
    BCF		LATB,6
    BCF		LATB,5
    MOVLB	0x00
    RETURN
    
clear_RGB_m
    MOVLB	0xF
    BCF		LATA,4
    BCF		LATA,5
    BCF		LATE,0
    MOVLB	0x00
    RETURN
    
clear_RGB_r
    MOVLB	0xF
    BCF		LATA,7
    BCF		LATA,6
    BCF		LATC,0
    MOVLB	0x00
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="ADC Subroutines">
    ;ADC poll left sensor
ADCpoll_l
    MOVLB	0xF
    MOVLW 	B'00000001'	;AN0(RA0) enable (left)
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
    MOVLW 	B'00000101'	;AN1(RA1) enable (middle)
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
    MOVLW 	B'00001001'	;AN2(RA2) enable (right)
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
;<editor-fold defaultstate="collapsed" desc="Serial Transmission">
transmit
    MOVFF   WREG,TXREG1		;data to be transmitted----------------------------------------------------------------
    BTFSS   TXSTA1,TRMT		;check status of the transmission,
    BRA	    $-2			;TRMRT cleared if in progress, set if done
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize Ports">
ini_ports
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
    
    MOVLB	0x00
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize External Interrupts">
ini_external_interrupts
    MOVLB	0xF
    
    BCF		PORTB,0
    BCF	    	LATB,0
    BCF	    	ANSELB,0
    BCF		TRISB,0
    
    ;Initialize Interrupts
    CLRF	INTCON		;button interrputs
    BSF 	INTCON,INT0IE	;
    BSF		INTCON,GIE	;
    
    MOVLB	0x00
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize Digital Inputs">
ini_digital_inputs
    BSF		TRISB,0		;TRIS-'1'=input pin/'0'=output pin
    BCF 	ANSELB,0	;ANSEL-'1'=analog pin/'0'=digital pin
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize oscillator">
ini_oscilator
    MOVLB	0xF
    
    BSF	    OSCCON,IRCF0
    BCF	    OSCCON,IRCF1
    BSF	    OSCCON,IRCF2	; IRCF<2:0> = '101' = 4Mhz
    
    MOVLB	0x00
    RETURN
    ;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize ADC">
ini_ADC
    MOVLB	0xF
    
    BSF 	TRISA,0		;RA0 = input
    BSF 	ANSELA,0 	;RA0 = analog
    
    BSF 	TRISA,1		;RA1 = input
    BSF 	ANSELA,1 	;RA1 = analog
    
    BSF 	TRISA,2		;RA2 = input
    BSF 	ANSELA,2	;RA2 = analog
    
    CLRF	ADRESH
    MOVLW 	B'00101111'	;left justify
    MOVWF 	ADCON2		;& 12 TAD ACQ time
    MOVLW 	B'00000000'
    MOVWF 	ADCON1		;ADC ref = Vdd, Vss
    
    MOVLB	0x00
    RETURN
    ;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize Asynchronous Transmission and Reception">
ini_async_transmit_recieve
    MOVLB	0xF
    
    CLRF    TXSTA1
    CLRF    RCSTA1
    CLRF    SPBRG1
    
    ;Initialize Asynchronous Transmission
    CLRF    SPBRG1
    CLRF    SPBRGH1
    
    BCF	    TXSTA1,SYNC		;set baudrate
    BCF	    BAUDCON1,BRG16	;
    BSF	    TXSTA1,BRGH         ;
				;
    MOVLW   D'12'		;sets baud rate to 19200 at 4MHz
    MOVWF   SPBRG1		;
    
    BSF	    TRISC,TX1
    BSF	    TRISC,RX1
    
    BSF	    RCSTA1,SPEN		;set SPEN bit to enable the asynchronous serial port
    BCF	    TXSTA1,TX9		;set the TX9 bit for 9-bit transmission
    BCF	    BAUDCON1,CKTXP	;Set CKTXP bit for inverted transmition polarity
    BSF	    TXSTA1,TXEN		;enable the transmission;sets TXxIF interrupt bit
    
    ;Initialize Asynchronous Reception
    
    BSF	    PIE1,RC1IE	;sets the RCxIF bit when data transfers from the 
			;RSR to the receive buffer RCREGx; ISR occurs
    BSF	    INTCON,PEIE	;serial reception interrputs
    BSF	    INTCON,GIE	;
    
    
    BCF	    RCSTA1,RX9		;set RX9 bit for 9-bit reception
    BCF	    BAUDCON1,DTRXP	;Set the DTRXP for inverted receive polarity
    BSF	    RCSTA1,CREN
    
    MOVLB	0x00
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize I2C Master Mode">
ini_I2C
    MOVLB	0xF

    CLRF    SSP1CON1
    BSF	    SSP1CON1,SSPM3	;sets i2c to master mode
    BCF	    SSP1CON1,SSPM2	;
    BCF	    SSP1CON1,SSPM1	;
    BCF	    SSP1CON1,SSPM0	;
    
    BSF	    SSP1CON1,SSPEN	;enables synchronous serial port
    
    BSF	    TRISC,SCL1
    BSF	    TRISC,SDA1
    
    MOVLW   D'9'		;sets Fcolck = 100KHz at fosc = 4MHz
    MOVWF   SSP1ADD		;
    
    MOVLB	0x00
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Initialize Menu">
ini_menu
    CLRF    WREG
    MOVLW   's'
    MOVFF   WREG,i2c_letter_1
    CLRF    WREG
    MOVLW   'l'
    MOVFF   WREG,i2c_letter_2
    CLRF    WREG
    MOVLW   'g'
    MOVFF   WREG,i2c_letter_3
    CLRF    WREG
    MOVLW   'n'
    MOVFF   WREG,i2c_letter_4
    CLRF    WREG
    
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="I2C Transmit">
i2c_transmit
    BSF	    SSP1CON2,SEN	    ;send start condition to eeprom
    BTFSS   PIR1,SSP1IF		    ;
    BRA	    $-2			    ;
    BCF	    PIR1,SSP1IF		    ;

    MOVLW   B'10100000'		    ;send control byte to eeprom
    MOVWF   SSP1BUF		    ;

    BTFSC   SSP1CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA	    $-2			    ;sent

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif, which must be 
    BCF	    PIR1,SSP1IF		    ;cleared in software

    MOVFF   i2c_adress,SSP1BUF	    ;send target adress to eeprom

    BTFSC   SSP1CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA	    $-2			    ;sent

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif, which must be 
    BCF	    PIR1,SSP1IF		    ;cleared in software

    MOVFF   i2c_data,SSP1BUF	    ;send data to eeprom

    BTFSC   SSP1CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA	    $-2			    ;sent

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif
    BCF	    PIR1,SSP1IF		    ;

    BSF	    SSP1CON2,PEN	    ;stop condition

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif, which must be 
    BCF	    PIR1,SSP1IF		    ;cleared in software

    call    delay_10ms
    call    delay_10ms

    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="I2C Receive">
i2c_receive
    BSF		    SSP1CON2,RSEN   	    ;send start condition to eeprom
					    ;(use RSEN for a continuous read)
				    
    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		    $-2			    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    MOVLW	    B'10100000'		    ;send write control byte to eeprom
    MOVWF	    SSP1BUF		    ;

    BTFSC	    SSP1CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA		    $-2			    ;sent

    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		     $-2		    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    MOVFF	    i2c_adress,SSP1BUF	    ;send target adress to eeprom

    BTFSC	    SSP1CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA		    $-2			    ;sent

    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		    $-2			    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    BSF		    SSP1CON2,RSEN	    ;send restart condition to eeprom

    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		    $-2			    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    MOVLW	    B'10100001'		    ;send read control byte to eeprom
    MOVWF	    SSP1BUF		    ;

    BTFSC	    SSP1CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA		    $-2			    ;sent

    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		    $-2			    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    BSF		    SSP1CON2,RCEN	    ;begins reception from target eeprom adress

    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		    $-2			    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    MOVFF	    SSP1BUF,i2c_data	    ;stores recieved data in a file register

    BSF		    SSP1CON2,ACKDT	    ;master sets a not acknowlege. 
    BSF		    SSP1CON2,ACKEN	    ;master sends the not acknowlege

    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		    $-2			    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software
    
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Display Menu">
display_menu
    CLRF    WREG
    MOVLW   'T'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'm'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   '3'
    CALL    transmit
    CLRF    WREG
    MOVLW   '9'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'i'
    CALL    transmit
    CLRF    WREG
    MOVLW   's'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'T'
    CALL    transmit
    CLRF    WREG
    MOVLW   'h'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'A'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'T'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'm'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    CLRF    WREG
    MOVFF   i2c_letter_1,WREG
    CALL    transmit
    CLRF    WREG
    MOVFF   i2c_letter_2,WREG
    CALL    transmit
    CLRF    WREG
    MOVFF   i2c_letter_3,WREG
    CALL    transmit
    CLRF    WREG
    MOVFF   i2c_letter_4,WREG
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    CLRF    WREG
    MOVLW   'C'
    CALL    transmit
    CLRF    WREG
    MOVLW   'h'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   's'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'y'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'u'
    CALL    transmit
    CLRF    WREG
    MOVLW   'r'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'M'
    CALL    transmit
    CLRF    WREG
    MOVLW   'A'
    CALL    transmit
    CLRF    WREG
    MOVLW   'R'
    CALL    transmit
    CLRF    WREG
    MOVLW   'V'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'm'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'd'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   '.'
    CALL    transmit
    CLRF    WREG
    MOVLW   '.'
    CALL    transmit
    CLRF    WREG
    MOVLW   '.'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    CLRF    WREG
    MOVLW   '('
    CALL    transmit
    CLRF    WREG
    MOVLW   'P'
    CALL    transmit
    CLRF    WREG
    MOVLW   ')'
    CALL    transmit
    CLRF    WREG
    MOVLW   'r'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'g'
    CALL    transmit
    CLRF    WREG
    MOVLW   'r'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'm'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    CLRF    WREG
    MOVLW   '('
    CALL    transmit
    CLRF    WREG
    MOVLW   'F'
    CALL    transmit
    CLRF    WREG
    MOVLW   ')'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'l'
    CALL    transmit
    CLRF    WREG
    MOVLW   'l'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'w'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'c'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'l'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'u'
    CALL    transmit
    CLRF    WREG
    MOVLW   'r'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    CLRF    WREG
    MOVLW   '('
    CALL    transmit
    CLRF    WREG
    MOVLW   'C'
    CALL    transmit
    CLRF    WREG
    MOVLW   ')'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'l'
    CALL    transmit
    CLRF    WREG
    MOVLW   'i'
    CALL    transmit
    CLRF    WREG
    MOVLW   'b'
    CALL    transmit
    CLRF    WREG
    MOVLW   'r'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   't'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    CLRF    WREG
    MOVLW   '('
    CALL    transmit
    CLRF    WREG
    MOVLW   'R'
    CALL    transmit
    CLRF    WREG
    MOVLW   ')'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'c'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    CLRF    WREG
    MOVLW   '('
    CALL    transmit
    CLRF    WREG
    MOVLW   'T'
    CALL    transmit
    CLRF    WREG
    MOVLW   ')'
    CALL    transmit
    CLRF    WREG
    MOVLW   'i'
    CALL    transmit
    CLRF    WREG
    MOVLW   'm'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00001101'
    CALL    transmit
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Racing Red">
racing_red
    CLRF    WREG
    MOVLW   'R'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'c'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   'i'
    CALL    transmit
    CLRF    WREG
    MOVLW   'n'
    CALL    transmit
    CLRF    WREG
    MOVLW   'g'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'R'
    CALL    transmit
    CLRF    WREG
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Racing Green">
racing_green
    CLRF    WREG
    MOVLW   'R'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'c'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   'i'
    CALL    transmit
    CLRF    WREG
    MOVLW   'n'
    CALL    transmit
    CLRF    WREG
    MOVLW   'g'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'G'
    CALL    transmit
    CLRF    WREG
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Racing Blue">
racing_blue
    CLRF    WREG
    MOVLW   'R'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'c'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   'i'
    CALL    transmit
    CLRF    WREG
    MOVLW   'n'
    CALL    transmit
    CLRF    WREG
    MOVLW   'g'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'B'
    CALL    transmit
    CLRF    WREG
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Racing Black">
racing_black
    CLRF    WREG
    MOVLW   'R'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'c'
    CALL    transmit
    CLRF    WREG
    MOVLW   'e'
    CALL    transmit
    CLRF    WREG
    MOVLW   'i'
    CALL    transmit
    CLRF    WREG
    MOVLW   'n'
    CALL    transmit
    CLRF    WREG
    MOVLW   'g'
    CALL    transmit
    CLRF    WREG
    MOVLW   B'00100000'
    CALL    transmit
    CLRF    WREG
    MOVLW   'n'
    CALL    transmit
    CLRF    WREG
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""<Enter>" check">
check_enter
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    RETURN
    BSF	    state,menu
    BCF	    state,program
    BSF	    word_checkL,0
    RETURN
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc="Delay 10ms">
delay_10ms
    MOVLW	D'15'
    MOVWF	count1_10ms
    
loop1_10ms
    MOVLW	D'255'
    MOVWF	count2_10ms
    DECFSZ	count1_10ms
    GOTO	loop2_10ms
    GOTO	delay_10ms_end
	
	
loop2_10ms
    DECFSZ	count2_10ms
    GOTO	loop2_10ms
    GOTO	loop1_10ms
	
delay_10ms_end
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Delay 333ms">
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
;========== Interrupt service routines ==========
;<editor-fold defaultstate="collapsed" desc="ISR Handler">
ISR_handler	;GIE = '0'
    BTFSC	ISR_reg,flash_333ms_isr
    GOTO	flash_333ms
    BTFSS	PIR1,RC1IF		;polls for reccieved data
    BRA		$-2
    GOTO	receive
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="333ms Flashing ISR">
flash_333ms
    BSF		ISR_reg,flash_333ms_isr
    RETFIE	;GIE = '1'
;</editor-fold>
;Serial Reception
receive					;GIE = '0'
    BTFSS	PIR1,RC1IF		;interrput handler
    BRA		$-2
    MOVFF	RCREG1,WREG
    CALL	transmit
    
;Serial_Reception_ISR handler
    BTFSC	state,power_on
    GOTO	check_boom_power_on
    BTFSC	state,menu
    GOTO	menu_select
    BTFSC	state,program
    GOTO	i2c_transmit_word
    BTFSC	state,follow_colour
    GOTO	check_col
    BTFSC	state,calibrate
    GOTO	check_boom_calibrate
    BTFSC	state,race
    GOTO	check_boom_race
    RETFIE
    

;<editor-fold defaultstate="collapsed" desc=""Boom!<Enter>" Check Power On">
check_boom_power_on
    BTFSS   word_checkL,5
    GOTO    test_B_boom
    BTFSS   word_checkL,4
    GOTO    test_o1_boom
    BTFSS   word_checkL,3
    GOTO    test_o2_boom
    BTFSS   word_checkL,2
    GOTO    test_m_boom
    BTFSS   word_checkL,1
    GOTO    test_excl_boom
    BTFSS   word_checkL,0
    GOTO    test_enter_boom
    RETFIE
    
test_B_boom
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,5
    RETFIE
    
test_o1_boom
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,4
    RETFIE
    
test_o2_boom
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,3
    RETFIE
    
test_m_boom
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'm'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,2
    RETFIE
    
test_excl_boom
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '!'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,1
    RETFIE
    
test_enter_boom
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,0
    BSF	    state,menu
    BCF	    state,power_on
    BCF	    state,program
    BCF	    state,follow_colour
    BCF	    state,calibrate
    BCF	    state,race
    BCF	    state,time
    RETFIE
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc="Menu Select">
menu_select
    BTFSS   word_checkH,1
    GOTO    test_P_p
    BTFSS   word_checkH,0
    GOTO    test_enter_p
    BTFSS   word_checkL,7
    GOTO    test_F_f
    BTFSS   word_checkL,6
    GOTO    test_enter_f
    BTFSS   word_checkL,5
    GOTO    test_C_c
    BTFSS   word_checkL,4
    GOTO    test_enter_c
    BTFSS   word_checkL,3
    GOTO    test_R_r
    BTFSS   word_checkL,2
    GOTO    test_enter_r
    BTFSS   word_checkL,1
    GOTO    test_T_t
    BTFSS   word_checkL,0
    GOTO    test_enter_t
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""P<Enter>" Check">
;check_p  
test_P_p
    MOVFF   WREG,letter
    MOVLW   'P'
    CPFSEQ  letter
    GOTO    test_F_f
    BSF	    word_checkH,1
    RETFIE

test_enter_p
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    state,program
    BCF	    state,menu
    RETFIE
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc=""F<Enter>" Check">
;check_f
test_F_f
    MOVLW   'F'
    CPFSEQ  letter
    GOTO    test_C_c
    BSF	    word_checkH,1
    BSF	    word_checkH,0
    BSF	    word_checkL,7
    RETFIE

test_enter_f
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    state,follow_colour
    BCF	    state,menu
    RETFIE
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc=""C<Enter>" Check">
;check_c
test_C_c
    MOVLW   'C'
    CPFSEQ  letter
    GOTO    test_R_r
    BSF	    word_checkH,1
    BSF	    word_checkH,0
    BSF	    word_checkL,7
    BSF	    word_checkL,6
    BSF	    word_checkL,5
    RETFIE

test_enter_c
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    state,calibrate
    BCF	    state,menu
    RETFIE
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc=""R<Enter>" Check">
;check_r  
test_R_r
    MOVLW   'R'
    CPFSEQ  letter
    GOTO    test_T_t
    BSF	    word_checkH,1
    BSF	    word_checkH,0
    BSF	    word_checkL,7
    BSF	    word_checkL,6
    BSF	    word_checkL,5
    BSF	    word_checkL,4
    BSF	    word_checkL,3
    RETFIE

test_enter_r
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    state,race
    BCF	    state,menu
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""T<Enter>" Check">
;check_t    
test_T_t
    MOVLW   'T'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkH,1
    BSF	    word_checkH,0
    BSF	    word_checkL,7
    BSF	    word_checkL,6
    BSF	    word_checkL,5
    BSF	    word_checkL,4
    BSF	    word_checkL,3
    BSF	    word_checkL,2
    BSF	    word_checkL,1
    RETFIE

test_enter_t
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    state,time
    BCF	    state,menu
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="I2C Transmit Word">
i2c_transmit_word
    BTFSS   word_checkH,2
    GOTO    check_i2c_char_1
    BTFSS   word_checkH,1
    GOTO    check_i2c_char_2
    BTFSS   word_checkH,0
    GOTO    check_i2c_char_3
    BTFSS   word_checkL,7
    GOTO    check_i2c_char_4
    BTFSS   word_checkL,6
    GOTO    test_enter_i2c
    BTFSS   word_checkL,5
    GOTO    test_B_boom_in_p
    BTFSS   word_checkL,4
    GOTO    test_o1_boom_in_p
    BTFSS   word_checkL,3
    GOTO    test_o2_boom_in_p
    BTFSS   word_checkL,2
    GOTO    test_m_boom_in_p
    BTFSS   word_checkL,1
    GOTO    test_excl_boom_in_p
    BTFSS   word_checkL,0
    GOTO    test_enter_boom_in_p
    RETFIE
    
check_i2c_char_1
;    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    GOTO    store_i2c_char_1
    MOVFF   letter,i2c_data
    BSF	    word_checkH,2
    BSF	    word_checkH,1
    BSF	    word_checkH,0
    BSF	    word_checkL,7
    BSF	    word_checkL,6
    BSF	    word_checkL,5	;test boom
    RETFIE
    
check_i2c_char_2
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    store_i2c_char_2
    GOTO    store_i2c_char_2
    
check_i2c_char_3
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    store_i2c_char_3
    GOTO    store_i2c_char_3

check_i2c_char_4
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'm'
    CPFSEQ  letter
    GOTO    store_i2c_char_4
    GOTO    store_i2c_char_4
    
test_enter_i2c
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,6
    BSF	    state,menu
    BCF	    state,power_on
    BCF	    state,program
    BCF	    state,follow_colour
    BCF	    state,calibrate
    BCF	    state,race
    BCF	    state,time
    RETFIE
    
test_B_boom_in_p
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,5
    RETFIE
    
test_o1_boom_in_p
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_o1_boom_in_p
    BSF	    word_checkL,4
    RETFIE
    
test_o2_boom_in_p
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_o2_boom_in_p
    BSF	    word_checkL,3
    RETFIE

test_m_boom_in_p
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'm'
    CPFSEQ  letter
    GOTO    clear_m_boom_in_p
    BSF	    word_checkL,2
    RETFIE
    
test_excl_boom_in_p
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '!'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,1
    RETFIE  
    
test_enter_boom_in_p
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,0
    BSF	    state,menu
    BCF	    state,power_on
    BCF	    state,program
    BCF	    state,follow_colour
    BCF	    state,calibrate
    BCF	    state,race
    BCF	    state,time
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="I2C Receive Letter">
i2c_receive_letter
    RETFIE
;</editor-fold>   
;<editor-fold defaultstate="collapsed" desc="Follow Colour Check">   
check_col
    BTFSS   word_checkL,5
    GOTO    test_B_boom_in_f
    BTFSS   word_checkL,4
    GOTO    test_o1_boom_in_f
    BTFSS   word_checkL,3
    GOTO    test_o2_boom_in_f
    BTFSS   word_checkL,2
    GOTO    test_m_boom_in_f
    BTFSS   word_checkL,1
    GOTO    test_excl_boom_in_f
    BTFSS   word_checkL,0
    GOTO    test_enter_boom_in_f
    BTFSS   word_checkH,7
    GOTO    test_col_b
    BTFSS   word_checkH,6
    GOTO    test_enter_col_b
    BTFSS   word_checkH,5
    GOTO    test_col_r
    BTFSS   word_checkH,4
    GOTO    test_enter_col_r
    BTFSS   word_checkH,3
    GOTO    test_col_g
    BTFSS   word_checkH,2
    GOTO    test_enter_col_r
    BTFSS   word_checkH,1
    GOTO    test_col_n
    BTFSS   word_checkH,0
    GOTO    test_enter_col_r
    RETFIE
    
test_B_boom_in_f
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    GOTO    test_col_r
    BSF	    word_checkL,5
    RETFIE
    
test_o1_boom_in_f
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    test_enter_col_b
    BSF	    word_checkL,4
    RETFIE
    
test_o2_boom_in_f
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_o2_boom_in_p
    BSF	    word_checkL,3
    RETFIE

test_m_boom_in_f
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'm'
    CPFSEQ  letter
    GOTO    clear_m_boom_in_p
    BSF	    word_checkL,2
    RETFIE
    
test_excl_boom_in_f
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '!'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,1
    RETFIE  
    
test_enter_boom_in_f
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,0
    BSF	    state,menu
    BCF	    state,power_on
    BCF	    state,program
    BCF	    state,follow_colour
    BCF	    state,calibrate
    BCF	    state,race
    BCF	    state,time
    RETFIE
    
test_col_b
    BCF	    bit_received,0
    MOVFF   letter,WREG
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    GOTO    test_col_r
    BSF	    word_checkL,5
    BSF	    word_checkL,4
    BSF	    word_checkL,3
    BSF	    word_checkL,2
    BSF	    word_checkL,1
    BSF	    word_checkL,0
    BSF	    word_checkH,7
    RETFIE

test_enter_col_b
    BSF	    bit_received,0
    MOVFF   letter,WREG
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkH,6
    BCF	    state,follow_colour
    BSF	    state,menu
    BSF	    race_col,blue
    RETFIE
    
test_col_r
    BSF	    bit_received,0
    MOVFF   letter,WREG
    MOVFF   WREG,letter
    MOVLW   'R'
    CPFSEQ  letter
    GOTO    test_col_g
    BSF	    word_checkL,5
    BSF	    word_checkL,4
    BSF	    word_checkL,3
    BSF	    word_checkL,2
    BSF	    word_checkL,1
    BSF	    word_checkL,0
    BSF	    word_checkH,7
    BSF	    word_checkH,6
    BSF	    word_checkH,5
    RETFIE

test_enter_col_r
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkH,4
    BCF	    state,follow_colour
    BSF	    state,menu
    BSF	    race_col,red
    RETFIE
    
test_col_g
    BSF	    bit_received,0
    MOVFF   letter,WREG
    MOVFF   WREG,letter
    MOVLW   'G'
    CPFSEQ  letter
    GOTO    test_col_n
    BSF	    word_checkL,5
    BSF	    word_checkL,4
    BSF	    word_checkL,3
    BSF	    word_checkL,2
    BSF	    word_checkL,1
    BSF	    word_checkL,0
    BSF	    word_checkH,7
    BSF	    word_checkH,6
    BSF	    word_checkH,5
    BSF	    word_checkH,4
    BSF	    word_checkH,3
    RETFIE

test_enter_col_g
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkH,2
    BCF	    state,follow_colour
    BSF	    state,menu
    BSF	    race_col,green
    RETFIE
    
test_col_n
    BSF	    bit_received,0
    MOVFF   letter,WREG
    MOVFF   WREG,letter
    MOVLW   'n'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,5
    BSF	    word_checkL,4
    BSF	    word_checkL,3
    BSF	    word_checkL,2
    BSF	    word_checkL,1
    BSF	    word_checkL,0
    BSF	    word_checkH,7
    BSF	    word_checkH,6
    BSF	    word_checkH,5
    BSF	    word_checkH,4
    BSF	    word_checkH,3
    BSF	    word_checkH,2
    BSF	    word_checkH,1
    RETFIE

test_enter_col_n
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkH,0
    BCF	    state,follow_colour
    BSF	    state,menu
    BSF	    race_col,black
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""Boom!<Enter>" Check Calibrate">
check_boom_calibrate
    CALL    clear_RGB_l
    CALL    clear_RGB_m
    CALL    clear_RGB_r
    
    BTFSS   word_checkL,5
    GOTO    test_B_boom_c
    BTFSS   word_checkL,4
    GOTO    test_o1_boom_c
    BTFSS   word_checkL,3
    GOTO    test_o2_boom_c
    BTFSS   word_checkL,2
    GOTO    test_m_boom_c
    BTFSS   word_checkL,1
    GOTO    test_excl_boom_c
    BTFSS   word_checkL,0
    GOTO    test_enter_boom_c
    RETFIE
    
test_B_boom_c
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,5
    RETFIE
    
test_o1_boom_c
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,4
    RETFIE
    
test_o2_boom_c
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,3
    RETFIE
    
test_m_boom_c
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'm'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,2
    RETFIE
    
test_excl_boom_c
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '!'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,1
    RETFIE
    
test_enter_boom_c
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,0
    BSF	    state,menu
    BCF	    state,power_on
    BCF	    state,program
    BCF	    state,follow_colour
    BCF	    state,calibrate
    BCF	    state,race
    BCF	    state,time
    RETFIE
;</editor-fold>  
;<editor-fold defaultstate="collapsed" desc=""Boom!<Enter>" Check Race">
check_boom_race
    BTFSS   word_checkL,5
    GOTO    test_B_boom_r
    BTFSS   word_checkL,4
    GOTO    test_o1_boom_r
    BTFSS   word_checkL,3
    GOTO    test_o2_boom_r
    BTFSS   word_checkL,2
    GOTO    test_m_boom_r
    BTFSS   word_checkL,1
    GOTO    test_excl_boom_r
    BTFSS   word_checkL,0
    GOTO    test_enter_boom_r
    RETFIE
    
test_B_boom_r
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,5
    RETFIE
    
test_o1_boom_r
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,4
    RETFIE
    
test_o2_boom_r
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,3
    RETFIE
    
test_m_boom_r
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'm'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,2
    RETFIE
    
test_excl_boom_r
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '!'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,1
    RETFIE
    
test_enter_boom_r
    BSF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_words
    BSF	    word_checkL,0
    BSF	    state,menu
    BCF	    state,power_on
    BCF	    state,program
    BCF	    state,follow_colour
    BCF	    state,calibrate
    BCF	    state,race
    BCF	    state,time
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Store I2C Characters">
store_i2c_char_1
    BSF	    word_checkH,2
    MOVFF   letter,i2c_data
    RETFIE
store_i2c_char_2
    BSF	    word_checkH,2
    BSF	    word_checkH,1
    MOVFF   letter,i2c_data
    RETFIE
store_i2c_char_3
    BSF	    word_checkH,2
    BSF	    word_checkH,1
    BSF	    word_checkH,0
    MOVFF   letter,i2c_data
    RETFIE
store_i2c_char_4
    BSF	    word_checkH,2
    BSF	    word_checkH,1
    BSF	    word_checkH,0
    BSF	    word_checkL,7
    MOVFF   letter,i2c_data
    RETFIE
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Clear words">
clear_words
    CLRF    word_checkL
    CLRF    word_checkH
    RETFIE
    
clear_o1_boom_in_p
    BCF	    word_checkH,2
    BCF	    word_checkH,1
    BCF	    word_checkH,0
    BCF	    word_checkL,7
    BCF	    word_checkL,6
    BCF	    word_checkL,5	;test boom
    RETFIE
    
clear_o2_boom_in_p
    BCF	    word_checkH,1
    BCF	    word_checkH,0
    BCF	    word_checkL,7
    BCF	    word_checkL,6
    BCF	    word_checkL,5
    BCF	    word_checkL,4	;test boom
    RETFIE
    
clear_m_boom_in_p
    BCF	    word_checkH,0
    BCF	    word_checkL,7
    BCF	    word_checkL,6
    BCF	    word_checkL,5
    BCF	    word_checkL,4
    BCF	    word_checkL,3	;test boom
    RETFIE
;</editor-fold>
;========== Tables ==========
;<editor-fold defaultstate="collapsed" desc="Vrooom!">
vrooom_table
    ADDWF   PCL
    RETLW   B'01010110';V 0d0
    RETLW   B'01110010';r 0d2
    RETLW   B'01101111';o 0d4
    RETLW   B'01101111';o 0d6
    RETLW   B'01101111';o 0d8
    RETLW   B'01101101';m 0d10
    RETLW   B'00100001';! 0d12
;</editor-fold>

    end
   