; Archivo: labs.S
; Dispositivo: PIC16F887
; Autor: Diana Alvarado
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: Contador de 4 bits con un delay de 100ms
; Hardware: LEDs en el puerto A, push pull down en RB0 y RB1
;
; Creado: 9 ago, 2021
; Última modificación: 9 ag, 2021

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_CLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
;-------variables--------
  
PSECT udata_bank0 ;common memory
  cont: DS 1 ; 2 bytes
  conta: DS 1  
  cont_small: DS 1 ; 1 byte
    ;--------vector reset------------
    
PSECT resVect, class=CODE, abs, delta=2
ORG 00h  ;posición 0000h para el reset
    
resetVec:
    PAGESEL main
    goto main
 
PSECT code, delta=2, abs
ORG 100h  ; posición para el código 
;--------- Tabla ------
tabla: 
    clrf PCLATH 
    bsf PCLATH, 0 
    andlw 0x0f
    addwf PCL
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
    
 ; -------configuración---------
 main:
    call    config_io
    call    config_reloj
    call    config_tmr0
    banksel PORTA
    
; ------loop principal--------
loop:
    
    btfss   T0IF
    goto    $-1
    call    reiniciar_tmr0
    
   /* incf    PORTA
    btfsc   PORTA, 4	
    clrf    PORTA	
    call    offf*/	
    call contador_timer0
    
    
    btfsc PORTB, 0
    call inc_portc
    btfsc PORTB, 1
    call dec_portc
    
    movf conta, W
    call tabla 
    movwf PORTC
    call comparar
    goto    loop

; ------sub rutinas-------
config_reloj:
    banksel OSCCON
    bcf	    IRCF2	; IRCF = 010, 250kHz
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS		;RELOJ INTERNO
    return 

config_io:
    banksel ANSEL	;banco 11
    clrf    ANSEL ;pines digitales
    clrf    ANSELH
    
    banksel TRISA	;banco 01
    clrf    TRISA
    clrf TRISD
    bsf TRISB, 0
    bsf TRISB, 1
    bcf TRISB, 2
    clrf TRISA ; port A como salida
    clrf TRISC ;portC como salida
    clrf TRISD ;port D como salida 
    
    banksel PORTA	;banco 00
    clrf PORTA
    clrf PORTB
    clrf PORTC
    
    return
    
config_tmr0:
    banksel TRISA
    bcf	    T0CS	;este es reloj interno
    bcf	    PSA		;prescaler
    bsf	    PS2
    bsf	    PS1	    
    bsf	    PS0	    ;PS = 111, 1:256
    banksel PORTA
    call    reiniciar_tmr0
    return 
    
offf:
    bcf	conta,  4	;bits que se apagarán
    bcf	conta,  5
    bcf	conta,  6
    bcf	conta,  7
    return

    
reiniciar_tmr0:
    movlw   232	    ; 100ms = 4*(4*10^(-6))*(256-TMR0) *256 Depejando  TMR0=231.6
    movwf   TMR0
    bcf	    T0IF
    return

inc_portc:
    btfss PORTB, 0
    goto $-1
    btfsc PORTB, 0 
    goto $-1
    incf conta
    btfsc conta, 4
    clrf conta  
    
    return
    
dec_portc:
    btfss PORTB, 1
    goto $-1
    btfsc PORTB, 1
    goto $-1
    decf conta, F
    btfsc conta, 7
    call coun
    return
    
coun:
    bcf conta, 4
    bcf conta, 5
    bcf conta, 6
    bcf conta, 7
    return
    
contador_timer0:
    incf PORTA
    movlw 10
    subwf  PORTA, 0
    btfsc STATUS, 2
    call contador_seg
    return 
    
contador_seg:
    clrf PORTA
    incf PORTD
    btfsc PORTD, 4
    clrf PORTD
    return
    
comparar:
    movf PORTD, W ;mueve el puerto d a w
    subwf conta, 0 ;resta la variable conta a w
    btfsc STATUS, 2 ; si es 0 la resta 
    call alarma_encendida ;se ejecuta para encender la led
    return
    
alarma_encendida:
    clrf PORTD ;limpia el puerto d
    bsf PORTB, 2 ; enciende la led
    call delay_small ;espera
    bcf PORTB, 2 ;apaga el led
    

delay_small:
    movlw 500 ; valor inicial del contador (((500-1-1-1)/3=165)
    movwf cont_small
    decfsz cont_small, 1 ; decrementar el contador 
    goto $-1 ; ejecutar línea anterior
    return
 end 
