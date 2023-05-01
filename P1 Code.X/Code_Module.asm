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
    GOTO    start
 ;</editor-fold>
; -------------	
; PROGRAM START	
; -------------  
start
    
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
    
    BCF	    state,power_on
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
    
power_on_boom
    BTFSS   bit_received,0
    GOTO    power_on_boom
    CALL    check_boom
    BTFSS   state,menu
    GOTO    power_on_boom
    BCF	    state,power_on 
    GOTO    states
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Menu (State 1)">
menu_state1
    CALL	SSD_clear
    MOVLW	B'01111110'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    BCF	    state,menu
    CLRF    word_checkL
    CLRF    word_checkH
    
    CALL    display_menu
   
menu_select
    BTFSS   bit_received,0
    GOTO    menu_select
    
    CALL    check_p
    CALL    check_f
    CALL    check_c
    CALL    check_r
    CALL    check_t
    
    BTFSC   word_checkH,0	    ;checks enter for P
    BSF	    state,program
    BTFSC   word_checkL,6	    ;checks enter for F
    BSF	    state,follow_colour
    BTFSC   word_checkL,4	    ;checks enter for C
    BSF	    state,calibrate
    BTFSC   word_checkL,2	    ;checks enter for R
    BSF	    state,race
    BTFSC   word_checkL,0	    ;checks enter for T
    BSF	    state,time
    
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
    GOTO    menu_select
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Program (State 2)">
program_state2
i2c_transmit_word
    CALL	SSD_clear
    MOVLW	B'00110000'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    BCF	    state,program
    BCF	    state,menu
    CLRF    word_checkL
    CLRF    word_checkH
    CLRF    i2c_adress
    
i2c_transmit_test
    BTFSS   bit_received,0
    GOTO    i2c_transmit_test
    MOVFF   WREG,i2c_data
    CALL    i2c_transmit
    CALL    check_enter
    BTFSS   word_checkL,0
    GOTO    i2c_transmit_test
    BSF	    state,menu
    BCF	    state,program
    GOTO    states
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Follow colour (State 3)">
follow_colour_state3
    CALL	SSD_clear
    MOVLW	B'01101101'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    BCF	    state,follow_colour
    BCF	    state,menu
    CLRF    word_checkL
    CLRF    word_checkH
       
colour_select
    BTFSS   bit_received,0
    GOTO    colour_select
    
    CALL    check_col_r
    CALL    check_col_b
    CALL    check_col_g
    CALL    check_col_n
    CALL    check_boom
    
    BTFSC   word_checkH,6	    ;checks enter for r
    BSF	    race_col,red
    BTFSC   word_checkH,4	    ;checks enter for g
    BSF	    state,menu
    BTFSC   word_checkH,2	    ;checks enter for b
    BSF	    state,menu
    BTFSC   word_checkH,0	    ;checks enter for n
    BSF	    state,menu
    BTFSC   word_checkL,0	    ;checks for boom
    BSF	    state,menu
    
    BTFSS   state,menu
    GOTO    colour_select
    GOTO    states
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Calibrate (State 4)">
calibrate_state4
    CALL	SSD_clear
    MOVLW	B'01111001'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    
    BCF	    state,calibrate
    BSF	    state,menu
    CLRF    word_checkL
    CLRF    word_checkH
    
    GOTO    states
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Race (State 5)">
race_state5
    CALL	SSD_clear
    MOVLW	B'00110011'
    MOVFF	WREG,SSD
    CALL	SSD_display
    
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    CALL    delay_loop_333
    
    BCF	    state,race
    BSF	    state,menu
    CLRF    word_checkL
    CLRF    word_checkH
    
    GOTO    states
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="Time (State 7)">
time_state7
    goto    states
;</editor-fold>
;========== Subroutines ==========
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
    CALL    delay_10ms
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
    
    BSF		TRISB,0		;TRIS-'1'=input pin/'0'=output pin
    BCF 	ANSELB,0	;ANSEL-'1'=analog pin/'0'=digital pin
    
    ;Initialize Interrupts
    CLRF	INTCON		;button interrputs
    BSF 	INTCON,INT0IE	;
    BSF		INTCON,GIE	;
    
    MOVLB	0x00
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
    
    BSF		INTCON,PEIE	;serial reception interrputs
    BSF		PIE1,RC1IE	;sets the RCxIF bit when data transfers from the 
				;RSR to the receive buffer RCREGx; ISR occurs
    
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
;<editor-fold defaultstate="collapsed" desc="I2C Transmission">
i2c_transmit
    
    BSF	    SSP1CON2,SEN	    ;send start condition to eeprom
    BTFSS   PIR1,SSP1IF		    ;
    BRA	    $-2			    ;
    BCF	    PIR1,SSP1IF		    ;

    MOVLW   B'10100000'		    ;send control byte to eeprom
    MOVWF   SSP1BUF		    ;

    BTFSC   SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA	    $-2			    ;sent

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif, which must be 
    BCF	    PIR1,SSP1IF		    ;cleared in software

    MOVFF   i2c_adress,SSP1BUF	    ;send target adress to eeprom

    BTFSC   SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA	    $-2			    ;sent

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif, which must be 
    BCF	    PIR1,SSP1IF		    ;cleared in software

    MOVFF   i2c_data,SSP1BUF	    ;send data to eeprom

    BTFSC   SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA	    $-2			    ;sent

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif
    BCF	    PIR1,SSP1IF		    ;

    BSF	    SSP1CON2,PEN	    ;stop condition

    BTFSS   PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA	    $-2			    ;module sets the sspxif, which must be 
    BCF	    PIR1,SSP1IF		    ;cleared in software

    INCF    i2c_adress
    call    delay_10ms
    call    delay_10ms

    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="I2C Reception">
i2c_receive
    BSF		    SSP1CON2,RSEN   	    ;send start condition to eeprom
					    ;(use RSEN for a continuous read)
				    
    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		    $-2			    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    MOVLW	    B'10100000'		    ;send write control byte to eeprom
    MOVWF	    SSP1BUF		    ;

    BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
    BRA		    $-2			    ;sent

    BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
    BRA		     $-2		    ;module sets the sspxif, which must be
    BCF		    PIR1,SSP1IF		    ;cleared in software

    MOVFF	    i2c_adress,SSP1BUF	    ;send target adress to eeprom

    BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
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

    BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
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
;<editor-fold defaultstate="collapsed" desc="Clear words">
clear_word
    CLRF    word_checkL
    CLRF    word_checkH
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""Boom!<Enter>" Check">
check_boom
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
    
    
test_B_boom
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkL,5
    RETURN
    
test_o1_boom
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    word_checkL,4
    RETURN
    
test_o2_boom
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'o'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    word_checkL,3
    RETURN
    
test_m_boom
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'm'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    word_checkL,2
    RETURN
    
test_excl_boom
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '!'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    word_checkL,1
    RETURN
    
test_enter_boom
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   '\r'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,menu
    BSF	    word_checkL,0
    BCF	    state,power_on
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
    MOVLW   '('
    CALL    transmit
    CLRF    WREG
    MOVLW   's'
    CALL    transmit
    CLRF    WREG
    MOVLW   'l'
    CALL    transmit
    CLRF    WREG
    MOVLW   'o'
    CALL    transmit
    CLRF    WREG
    MOVLW   'g'
    CALL    transmit
    CLRF    WREG
    MOVLW   'a'
    CALL    transmit
    CLRF    WREG
    MOVLW   'n'
    CALL    transmit
    CLRF    WREG
    MOVLW   ')'
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
    MOVLW   '0'
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
;<editor-fold defaultstate="collapsed" desc=""P<Enter>" Check">
check_p
    BTFSS   word_checkH,1
    GOTO    test_P_p
    BTFSS   word_checkH,0
    GOTO    test_enter_p
    
    
    
test_P_p
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'P'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkH,1
    RETURN

test_enter_p
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,program
    BSF	    word_checkH,0
    BCF	    state,menu
    RETURN
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc=""F<Enter>" Check">
check_f
    BTFSS   word_checkL,7
    GOTO    test_F_f
    BTFSS   word_checkL,6
    GOTO    test_enter_f
    
test_F_f
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'F'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkL,7
    RETURN

test_enter_f
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,follow_colour
    BSF	    word_checkL,6
    BCF	    state,menu
    RETURN
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc=""C<Enter>" Check">
check_c
    BTFSS   word_checkL,5
    GOTO    test_C_c
    BTFSS   word_checkL,4
    GOTO    test_enter_c
    
test_C_c
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'C'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkL,5
    RETURN

test_enter_c
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,calibrate
    BSF	    word_checkL,4
    BCF	    state,menu
    RETURN
;</editor-fold> 
;<editor-fold defaultstate="collapsed" desc=""R<Enter>" Check">
check_r
    BTFSS   word_checkL,3
    GOTO    test_R_r
    BTFSS   word_checkL,2
    GOTO    test_enter_r
    
test_R_r
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'R'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkL,3
    RETURN

test_enter_r
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,race
    BSF	    word_checkL,2
    BCF	    state,menu
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""T<Enter>" Check">
check_t
    BTFSS   word_checkL,1
    GOTO    test_T_t
    BTFSS   word_checkL,0
    GOTO    test_enter_t
    
test_T_t
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'T'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkL,1
    RETURN

test_enter_t
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,time
    BSF	    word_checkL,0
    BCF	    state,menu
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
;<editor-fold defaultstate="collapsed" desc=""R" Check">
check_col_r
    BTFSS   word_checkH,7
    GOTO    test_col_r
    BTFSS   word_checkH,6
    GOTO    test_enter_col_r
    
test_col_r
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'R'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkH,7
    RETURN

test_enter_col_r
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,menu
    BSF	    word_checkH,6
    BSF	    race_col,red
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""G" Check">
check_col_g
    BTFSS   word_checkH,5
    GOTO    test_col_g
    BTFSS   word_checkH,4
    GOTO    test_enter_col_g
    
test_col_g
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'G'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkH,5
    RETURN

test_enter_col_g
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,menu
    BSF	    word_checkH,4
    BSF	    race_col,green
    RETURN
;</editor-fold>  
;<editor-fold defaultstate="collapsed" desc=""B" Check">
check_col_b
    BTFSS   word_checkH,3
    GOTO    test_col_b
    BTFSS   word_checkH,2
    GOTO    test_enter_col_b
    
test_col_b
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'B'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkH,3
    RETURN

test_enter_col_b
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,menu
    BSF	    word_checkH,2
    BSF	    race_col,blue
    RETURN
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc=""n" Check">
check_col_n
    BTFSS   word_checkH,1
    GOTO    test_col_n
    BTFSS   word_checkH,0
    GOTO    test_enter_col_n
    
test_col_n
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   'n'
    CPFSEQ  letter
    RETURN
    BSF	    word_checkH,1
    RETURN

test_enter_col_n
    BCF	    bit_received,0
    MOVFF   WREG,letter
    MOVLW   B'00001101'
    CPFSEQ  letter
    GOTO    clear_word
    BSF	    state,menu
    BSF	    word_checkH,0
    BSF	    race_col,black
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
;<editor-fold defaultstate="collapsed" desc="Serial Reception">
receive					;GIE = '0'
    BSF		bit_received,0
    BTFSS	PIR1,RC1IF		;interrput handler
    BRA		$-2
    MOVFF	RCREG1,WREG
    CALL	transmit
    
    RETFIE				;GIE = '1'
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
   