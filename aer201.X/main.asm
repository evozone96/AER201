; ********************************************************************************
; Barrel Inspection Machine
; Ming Kun Yang (1001262224)
; ********************************************************************************


#include <p18f4620.inc>
    list P=18F4620, F=INHX32, C=160, N=80, ST=OFF, MM=OFF, R=DEC

; ********************************************************************************
; Configuration bits
; ********************************************************************************

    config OSC  = HS, FCMEN = OFF, IESO = OFF
    config PWRT = OFF, BOREN = SBORDIS, BORV = 3
    config WDT  = OFF, WDTPS = 32768
    config MCLRE = ON, LPT1OSC = OFF, PBADEN = OFF, CCP2MX = PORTC
    config STVREN = ON, LVP = OFF, XINST = OFF
    config DEBUG = OFF
    config CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CPB = OFF, CPD = OFF
    config WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF
    config WRTB = OFF, WRTC = OFF, WRTD = OFF
    config EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF, EBTRB = OFF
    
; ********************************************************************************
; Definitions
; ********************************************************************************
#define	 MOTOR_BASE PORTC, 1
#define  LCD_RS	    PORTD, 2	
#define  LCD_E	    PORTD, 3


; ********************************************************************************
; General Purpose Register Assignments
; ********************************************************************************

Temp0                       equ 0x20;
Temp1                       equ 0x21;
Temp2                       equ 0x22;
DelayCounter0		    equ 0x25;
DelayCounter1		    equ 0x26;

; ********************************************************************************
; Macros
; ********************************************************************************


ifequal  macro  Var, Value, Label
    movlw   Value
    subwf   Var, 0                      ; check if Var-Value=0
    bz      Label
    endm

ifnequal macro  Var, Value, Label
    movlw   Value
    subwf   Var, 0                      ; check if Var-Value!=0
    bnz     Label
    endm

store macro Destination, Value
    movlw   Value
    movwf   Destination
    endm
    
printline macro  TableName, LineNumber
    movlw   LineNumber                 
    call    WriteInstToLCD              
    movlw   upper TableName             
    movwf   TBLPTRU
    movlw   high TableName
    movwf   TBLPTRH
    movlw   low TableName
    movwf   TBLPTRL
    ; Do 16 Loops to display all 16 characters in the TableName
    call    Write16DataToLCD
    endm

printch  macro Char, Position, LineNumber 
    movlw   LineNumber                 
    call    WriteInstToLCD
    movlw   Position
    call    WriteInstToLCD
    movlw   Char
    call    WriteDataToLCD
    endm
 
; ********************************************************************************
; Variables for Assembler
; ********************************************************************************
Line0           set 10000000
Line1           set 11000000

Char00          set 10000000
Char01          set 10000001
Char02          set 10000010
Char03          set 10000011
Char04          set 10000100
Char05          set 10000101
Char06          set 10000110
Char07          set 10000111
Char08          set 10001000
Char09          set 10001001
Char0A          set 10001010
Char0B          set 10001011
Char0C          set 10001100
Char0D          set 10001101
Char0E          set 10001110
Char0F          set 10001111
Char10          set 11000000
Char11          set 11000001
Char12          set 11000010
Char13          set 11000011
Char14          set 11000100
Char15          set 11000101
Char16          set 11000110
Char17          set 11000111
Char18          set 11001000
Char19          set 11001001
Char1A          set 11001010
Char1B          set 11001011
Char1C          set 11001100
Char1D          set 11001101
Char1E          set 11001110
Char1F          set 11001111
; ********************************************************************************
; Vector Table
; ********************************************************************************

    org     0x0000                  ; Reset vector
    goto    Main
    org     0x0008                  ; When Low Priority Interrupt occurs
    goto    Interrupt
    org     0x0018                  ; When High Priority Interrupt occurs    
    retfie
    
; ********************************************************************************
; Tables
; ********************************************************************************
TableMenuTitle0             db  "<     START    >", 0
TableMenuTitle1             db  "<   DATA LOG   >", 0

TableMenuTitle00            db  "INSPECTING.     ", 0
TableMenuTitle01            db  "INSPECTING..    ", 0
TableMenuTitle02            db  "INSPECTING...   ", 0
TableMenuTitle03            db  "INSPECTING....  ", 0
TableMenuTitle04            db  "INSPECTING..... ", 0
TableMenuTitle05            db  "INSPECTING......", 0
TableMenuTitle06            db  "----COMPLETE----", 0
TableMenuTitle07            db  "<1>    SAVE DATA", 0
TableMenuTitle08            db  "<2>INSPECT AGAIN", 0

TableMenuTitle10            db  "<1>      DATA #1", 0
TableMenuTitle11            db  "<2>      DATA #2", 0
TableMenuTitle12            db  "<3>      DATA #3", 0


    
    
; ********************************************************************************
; Executable Code 
; ********************************************************************************
    
Main
    ; initialization
    clrf    TRISA                   ; sets all ports as output
    clrf    TRISB
    clrf    TRISC
    clrf    TRISD
    clrf    TRISE
    
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE

    ; EEPROM initialization $%^&$%^&
    
    
    call    InitializeLCD
    
TopMenuOne
    call    ClearLCD
    printline TableMenuTitle0, B'10000000'
    
Pause
    bra     Pause
    
    
; ********************************************************************************
; LCD Functions 
; ********************************************************************************

; InitializeLCD: set configuration for the LCD Display
; Input: None                       Output: None
InitializeLCD
    call        Delay5ms
    call        Delay5ms
    movlw       B'00110011'         ; set for 8 bit twice
    call        WriteInstToLCD
    movlw       B'00110011'         ; set for 8 bit
    call        WriteInstToLCD
    movlw       B'00110011'         ; set for 8 bit once again, then 4 bit
    call        WriteInstToLCD
    movlw       B'00101000'         ; 4 bits, 2 lines, 5x8
    call        WriteInstToLCD
    movlw       B'00001100'         ; display on/off
    call        WriteInstToLCD
    movlw       B'00000110'         ; entry mode
    call        WriteInstToLCD
    movlw       B'00000001'         ; clear ram
    call        WriteInstToLCD
    return
    
    
; WriteInstToLCD: sequences of command to modify the config of LCD
; Input: W                         Output: None
WriteInstToLCD
    bcf     LCD_RS                  ; clear RS to enter instruction mode
    movwf   Temp0                   ; store into Temporary register
    call    MoveMSB
    bsf     LCD_E                   ; pulse LCD high
    nop
    bcf     LCD_E                   ; pulse LCD low
    swapf   Temp0, W                ; swap nibbles
    call    MoveMSB
    bsf     LCD_E                   ; pulse LCD high
    nop                             ; wait
    bcf     LCD_E                   ; pulse LCD low
    call    Delay5ms
    return
    
; WriteDataToLCD: sequences of command to display a character on LCD
; Input: W                          Output: None
WriteDataToLCD
    bsf     LCD_RS                  ; set RS for data mode
    movwf   Temp0       ; store into temporary register
    call    MoveMSB
    bsf     LCD_E                   ; pulse LCD high
    nop
    bcf     LCD_E                   ; pulse LCD low
    swapf   Temp0, W                ; swap nibbles
    call    MoveMSB
    bsf     LCD_E                   ; pulse LCD high
    nop                             ; wait
    bcf     LCD_E                   ; pulse LCD low
    call    Delay44us
    return
    
; Write16DataToLCD: Take 16 Character from the table, and display them one by
;                   one, by invoking the subroutine WriteDataToLCD for 16 times
; Input: tblrd (Table Pointer)      Output: None
Write16DataToLCD
    tblrd*                          ; read first character in table
    movf    TABLAT, W
    Loop16LCD
        call    WriteDataToLCD
        tblrd+*                     ; increment pointer then read
        movf    TABLAT, W
        bnz     Loop16LCD
    return
    
; MoveMSB: Move the upper 4 bits of W into PORTD without affecting current
;          values in it
; Input: W                       Output: None
MoveMSB
    movff   PORTD, Temp1
    andlw   0xF0
    iorwf   Temp1,F                 ; OR operation and store it in File Reg
    iorlw   0x0F
    andwf   Temp1,F                 ; AND operation and store it in File Reg
    movff   Temp1, PORTD
    return

; ClearLCD: Clear the entire LCD
; Input: None                   Output: None
ClearLCD
    movlw   B'11000000'             ; 2nd line
    call    WriteInstToLCD
    movlw   B'00000001'             ; clear 2nd line
    call    WriteInstToLCD
    movlw   B'10000000'             ; 1st line
    call    WriteInstToLCD
    movlw   B'00000001'             ; clear 1st line
    call    WriteInstToLCD
    return
    
Delay5ms
    store   DelayCounter1, d'110'
    Delay5msLoop
        call    Delay44us
        decfsz  DelayCounter1, 1
        bra     Delay5msLoop
    return
    
Delay44us
    store   DelayCounter0, 0x23
    Delay44usLoop
        decfsz  DelayCounter0, 1
        bra     Delay44usLoop
    return
    
Interrupt
    bra	    Interrupt
    
end