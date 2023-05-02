    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
    CONFIG  FOSC = INTIO67
    CONFIG  WDTEN = OFF
    CONFIG  MCLRE = EXTMCLR       ; MCLR Pin Enable bit (MCLR pin enabled, RE3 input pin disabled)
    CONFIG  LVP = ON              ; Single-Supply ICSP Enable bit (Single-Supply ICSP enabled if MCLRE is also 1)
    
;========== Variable definitions ==========
cblock 0x20
	i2c_adress;0x20
	i2c_data;0x21
	delay_var1;0x22
	delay_var2;0x23
	delay_var3;0x24
	endc
;========== Reset vector ==========
	org 	00h
	goto 	Setup  
    
;========== Interrupt vector ==========
	org 	08h
	GOTO 	ISR 
	
;========== Initialization ==========
;<editor-fold defaultstate="collapsed" desc="Setup">

Setup
    ;Initialize Ports
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
    
    ;Initialize Interupt ports
    BSF		TRISB,0
    BCF 	ANSELB,0
    
    ;Initialize Interrupts
    CLRF	INTCON		;button interrputs
    BSF 	INTCON,INT0IE	;
    BSF		INTCON,GIE	;
    
    ;Initialize oscillator
    BSF	    OSCCON,IRCF0
    BCF	    OSCCON,IRCF1
    BSF	    OSCCON,IRCF2	; IRCF<2:0> = '101' = 4Mhz
    
    ;Initialize I2C master mode
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
    GOTO	start
 ;</editor-fold>
; -------------	
; PROGRAM START	
; -------------
start


;========== Subroutines ==========
;i2c_transmission
i2c_write
 BSF	    SSP1CON2,SEN	    ;start condition
 BTFSS	    PIR1,SSP1IF		    ;
 BRA	    $-2			    ;
 BCF	    PIR1,SSP1IF		    ;
 
 MOVLW	    B'10100000'		    ;control byte
 MOVWF	    SSP1BUF		    ;
 
 BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
 BRA	    $-2			    ;sent
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 MOVFF	    i2c_adress,SSP1BUF	    ;writes to eeprom adress
 
 BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
 BRA	    $-2			    ;sent
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 MOVFF	    i2c_data,SSP1BUF	    ;data sent to eeprom
   
 BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
 BRA	    $-2			    ;sent
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 BSF	    SSP1CON2,PEN	    ;stop condition
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 call ten_ms_delay
 call ten_ms_delay
 
 RETURN
 
 ;i2c_reception
i2c_read
 BSF	    SSP1CON2,RSEN   	    ;start condition(RSEN for a continuous read)
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 MOVLW	    B'10100000'		    ;write control byte
 MOVWF	    SSP1BUF		    ;
 
 BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
 BRA	    $-2			    ;sent
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 MOVFF	    i2c_adress,SSP1BUF	    ;reads from eeprom adress
 
 BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
 BRA	    $-2			    ;sent
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 BSF	    SSP1CON2,RSEN	    ;restart condition
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;

 MOVLW	    B'10100001'		    ;read control byte
 MOVWF	    SSP1BUF		    ;
 
 BTFSC	    SSP2CON2,ACKSTAT	    ;acknowlagement, from the eeprom, of data
 BRA	    $-2			    ;sent
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 BSF	    SSP1CON2,RCEN	    ;begins reception from stated eeprom adress
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;
 
 MOVFF	    SSP1BUF,i2c_data	    ;stores recieved data in a file register
 
 BSF	    SSP1CON2,ACKDT	    ;master sets a not acknowlege. 
 BSF	    SSP1CON2,ACKEN	    ;master sends the not acknowlege
 
 BTFSS	    PIR1,SSP1IF		    ;after transmission is complete, msspx 
 BRA	    $-2			    ;module sets the sspxif
 BCF	    PIR1,SSP1IF		    ;

 RETURN
;========== Interrupt service routines ==========
;<editor-fold defaultstate="collapsed" desc="Interrupt Service Routines">
ISR	;GIE = '0'
    
    RETFIE	;GIE = '1'
;</editor-fold>

    end
   