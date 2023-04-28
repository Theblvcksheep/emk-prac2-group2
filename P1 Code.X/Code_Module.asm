    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
    CONFIG  FOSC = INTIO67
    CONFIG  WDTEN = OFF
    CONFIG  MCLRE = EXTMCLR       ; MCLR Pin Enable bit (MCLR pin enabled, RE3 input pin disabled)
    CONFIG  LVP = ON              ; Single-Supply ICSP Enable bit (Single-Supply ICSP enabled if MCLRE is also 1)
    
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
        
    BSF		INTCON,PEIE	;serial reception interrputs
    BSF		PIE1,RC1IE	;sets the RCxIF bit when data transfers from the 
				;RSR to the receive buffer RCREGx; ISR occurs
    ;Initialize oscillator
    BSF	    OSCCON,IRCF0
    BCF	    OSCCON,IRCF1
    BSF	    OSCCON,IRCF2	; IRCF<2:0> = '101' = 4Mhz
    
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
    GOTO	start
 ;</editor-fold>
; -------------	
; PROGRAM START	
; -------------
start


;========== Subroutines ==========
serial_transmission
    MOVLW   D'6'		;data to be transmitted
    MOVWF   TXREG1
    BTFSS   TXSTA1,TRMT		;check status of the transmission,
    BRA	    $-2			;TRMRT cleared if in progress, set if done
    RETURN

;========== Interrupt service routines ==========
;<editor-fold defaultstate="collapsed" desc="Interrupt Service Routines">
serial_reception_ISR	;GIE = '0'
    BTFSS	PIR1,RC1IF     ;interrput handler
    BRA		$-2
    MOVFF	RCREG1,WREG
    CALL	serial_transmission
    RETFIE	;GIE = '1'
;</editor-fold>

    end
   