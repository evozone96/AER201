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
#define LCD_RS	    PORTD, 2	
#define LCD_E	    PORTD, 3
    
#define	LEFT_B	    PORTC, 0
#define	RIGHT_B	    PORTC, 1
#define SELECT_B    PORTC, 2
#define QUIT_B	    PORTC, 3


; ********************************************************************************
; General Purpose Register Assignments
; ********************************************************************************

Temp0                       equ 0x20;
Temp1                       equ 0x21;
Temp2                       equ 0x22;
Temp3			    equ 0x23;
Temp4			    equ 0x24;

DelayCounter0		    equ 0x25;
DelayCounter1		    equ 0x26;
		    
DisplayMode		    equ 0x30;
OperatingMode		    equ 0x31;
PrevButtonState		    equ 0x32;	
ButtonPushed		    equ 0x33;		    
; ********************************************************************************
; Macros
; ********************************************************************************


ifequalf  macro  Var, Value, Label	; if Label ends with return instruction
    movlw   Value
    subwf   Var, 0                      ; check if Var-Value=0
    btfsc   STATUS, 2
    call    Label
    endm
    
ifequalb  macro  Var, Value, Label	; if Label ends with branch instruction
    movlw   Value
    subwf   Var, 0                      ; check if Var-Value=0
    btfsc   STATUS, 2
    goto    Label
    endm

ifnequalf macro  Var, Value, Label	; if Label ends with return instruction
    movlw   Value
    subwf   Var, 0                      ; check if Var-Value!=0
    btfss   STATUS, 2
    call    Label
    endm

ifnequalb macro  Var, Value, Label	; if Label ends with branch instruction
    movlw   Value
    subwf   Var, 0                      ; check if Var-Value!=0
    btfss   STATUS, 2
    goto    Label
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
TableMenuTitle0             db  "      START    >", 0
TableMenuTitle1             db  "<   DATA LOG   >", 0
TableMenuTitle2             db  "< RESET MEMORY >", 0
TableMenuTitle3             db  "< SET DATE/TIME ", 0

TableMenuTitle00            db  "INSPECTING.     ", 0
TableMenuTitle01            db  "INSPECTING..    ", 0
TableMenuTitle02            db  "INSPECTING...   ", 0
TableMenuTitle03            db  "INSPECTING....  ", 0
TableMenuTitle04            db  "INSPECTING..... ", 0
TableMenuTitle05            db  "INSPECTING......", 0
TableMenuTitle06            db  "----COMPLETE----", 0
TableMenuTitle07            db  "   SAVE DATA   >", 0
TableMenuTitle08            db  "<INSPECT AGAIN  ", 0

TableMenuTitle10            db  "     DATA #1   >", 0
TableMenuTitle11            db  "<    DATA #2   >", 0
TableMenuTitle12            db  "<    DATA #3    ", 0
	    
TableMenuTitle20	    db	" ARE YOU SURE?  ", 0


    
    
; ********************************************************************************
; Executable Code 
; ********************************************************************************
    
Main
    ; initialization
    clrf	TRISA                   ; sets all ports as output
    clrf	TRISB
    clrf	TRISC
    clrf	TRISD
    clrf	TRISE
    
    clrf        PORTA
    clrf	PORTB
    clrf	PORTC
    clrf	PORTD
    clrf	PORTE
    
    store	TRISC, B'1111'
    
    ; EEPROM initialization $%^&$%^&
    store	DisplayMode, B'1100'
    call	InitializeLCD
    call	UpdateDisplay
    
    MainLoop
	; polls push buttons
	btfsc	SELECT_B
	call	SelectedPushed
	btfsc	LEFT_B
	call	LeftPushed
	btfsc	RIGHT_B
	call	RightPushed  
	btfsc	QUIT_B
	call	QuitPushed
	btfsc	ButtonPushed, 0 
	call	UpdateDisplay
	bcf	ButtonPushed, 0
	movff	PORTC, PrevButtonState
	movff	PrevButtonState, LATB
	bra	MainLoop
    
; UpdateDisplay: Updates display when user of the machine has changed modes
; Input: DisplayMode		    Output: None
UpdateDisplay 
    call ClearLCD
    
    ifequalf	DisplayMode, B'00', TopMenu0
    ifequalf	DisplayMode, B'01', TopMenu1
    ifequalf	DisplayMode, B'10', TopMenu2
    ifequalf	DisplayMode, B'11', TopMenu3
    ifequalf	DisplayMode, B'100', SubMenu00
    ifequalf	DisplayMode, B'1000', SubMenu01
    ifequalf	DisplayMode, B'1100', SubMenu02
    ifequalf	DisplayMode, B'10000', SubMenu03
    ifequalf	DisplayMode, B'10100', SubMenu04
    ifequalf	DisplayMode, B'11000', SubMenu05
    ifequalf	DisplayMode, B'11100', SubMenu06
    ifequalf	DisplayMode, B'100000', SubMenu07 
    ifequalf	DisplayMode, B'100100', SubMenu08 
    ifequalf	DisplayMode, B'101', SubMenu10
    ifequalf	DisplayMode, B'1001', SubMenu11
    ifequalf	DisplayMode, B'1101', SubMenu12
    ifequalf	DisplayMode, B'0110', SubMenu20
    return
    
TopMenu0 
    printline	TableMenuTitle0, B'10000000'
    return
    
TopMenu1 
    printline	TableMenuTitle1, B'10000000'
    return
    
TopMenu2 
    printline	TableMenuTitle2, B'10000000'
    return
    
TopMenu3 
    printline	TableMenuTitle3, B'10000000'
    return
    
SubMenu00
    printline	TableMenuTitle00, B'10000000'
    return
    
SubMenu01
    printline	TableMenuTitle01, B'10000000'
    return
    
SubMenu02
    printline	TableMenuTitle02, B'10000000'
    return
    
SubMenu03
    printline	TableMenuTitle03, B'10000000'
    return
    
SubMenu04
    printline	TableMenuTitle04, B'10000000'
    return
    
SubMenu05
    printline	TableMenuTitle05, B'10000000'
    return
    
SubMenu06
    printline	TableMenuTitle06, B'10000000'
    return
    
SubMenu07
    printline	TableMenuTitle07, B'10000000'
    return
    
SubMenu08
    printline	TableMenuTitle08, B'10000000'
    return
    
SubMenu10
    printline	TableMenuTitle10, B'10000000'
    return
    
SubMenu11
    printline	TableMenuTitle11, B'10000000'
    return
    
SubMenu12
    printline	TableMenuTitle12, B'10000000'
    return
    
SubMenu20
    printline	TableMenuTitle20, B'10000000'
    return
    
; QuitPushed
; Input: PrevButtonState	    Output: OperatingMode, DisplayMode, ButtonPushed
QuitPushed
    btfsc   PrevButtonState, 3
    return
    ButtonJustPressed
	clrf	DisplayMode
	bsf	ButtonPushed, 0
	return
	
; RightPushed
; Input: PrevButtonState	    Output: OperatingMode, DisplayMode, ButtonPushed
RightPushed
    btfsc   PrevButtonState, 1
    return
    RightButtonJustPressed
	ifequalb DisplayMode, B'00', ScrollDownOne
	ifequalb DisplayMode, B'01', ScrollDownTwo
	ifequalb DisplayMode, B'10', ScrollDownThree
	ifequalb DisplayMode, B'10000', ScrollDownFour
	ifequalb DisplayMode, B'0101', ScrollDownFive
	ifequalb DisplayMode, B'1001', ScrollDownSix
	return
	EndIfScrollRight
	bsf	ButtonPushed, 0
	return
	
ScrollDownOne
    store   DisplayMode, B'01'
    bra	    EndIfScrollRight 
    
ScrollDownTwo
    store   DisplayMode, B'10'
    bra	    EndIfScrollRight
    
ScrollDownThree
    store   DisplayMode, B'11'
    bra	    EndIfScrollRight
    
ScrollDownFour
    store   DisplayMode, B'10000'
    bra	    EndIfScrollRight 
    
ScrollDownFive
    store   DisplayMode, B'1001'
    bra	    EndIfScrollRight
    
ScrollDownSix
    store   DisplayMode, B'1101'
    bra	    EndIfScrollRight
    
; LeftPushed
; Input: PrevButtonState	    Output: OperatingMode, DisplayMode, ButtonPushed
LeftPushed
    btfsc   PrevButtonState, 0
    return
    LeftButtonJustPressed
	ifequalb DisplayMode, B'01', ScrollUpOne
	ifequalb DisplayMode, B'10', ScrollUpTwo
	ifequalb DisplayMode, B'11', ScrollUpThree
	ifequalb DisplayMode, B'11000', ScrollUpFour
	ifequalb DisplayMode, B'1001', ScrollUpFive
	ifequalb DisplayMode, B'1101', ScrollDownSix
	return
	EndIfScrollLeft
	bsf	ButtonPushed, 0
	return
	
ScrollUpOne
    store   DisplayMode, B'00'
    bra	    EndIfScrollLeft
    
ScrollUpTwo
    store   DisplayMode, B'1'
    bra	    EndIfScrollLeft
    
ScrollUpThree
    store   DisplayMode, B'10'
    bra	    EndIfScrollLeft
    
; SelectedPushed
; Input: PrevButtonState	    Output: OperatingMode, DisplayMode, ButtonPushed
SelectedPushed
    btfsc   PrevButtonState, 2
    return

    SelectButtonJustPressed
	ifequalb    DisplayMode, B'0', EnterOne
	ifequalb    DisplayMode, B'1', EnterTwo
	ifequalb    DisplayMode, B'1011', EnterThree
	ifequalb    DisplayMode, B'1100', EnterFour
	ifequalb    DisplayMode, B'1101', EnterFive
	return
	EndIfEnter
	bsf	    ButtonPushed, 0
	return
	
EnterOne
    store   DisplayMode, B'10'
    bra	    EndIfEnter

EnterTwo
    store   DisplayMode, B'1011'
    bra	    EndIfEnter
    
EnterThree
    bra	    EndIfEnter
    
EnterFour
    bra	    EndIfEnter
    
EnterFive
    bra	    EndIfEnter
    

    
    
    
    
    
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
    movwf   Temp0		    ; store into temporary register
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
    
PowerOff    
    end