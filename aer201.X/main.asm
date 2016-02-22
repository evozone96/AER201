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
#define LCD_RS	    PORTB, 2	
#define LCD_E	    PORTB, 3
    
; PORTA 0-1 are ports for motor on/off (output)

; PORTB 0-1 are ports for motor directions (output)
; PORTB 2-7 are ports for LCD output 
; PORTC 0 is for LED lighting up when barrel detected
; PORTC 1 is for arm distance optical encoder
; PORTC 2 to select barrel input
; PORTC 3-4 ports are for I2C
; PORTC 5 port for distance optical encoder
; PORTC 6-7 ports are for EUART
; PORTD 0-3 are ports for push button input 
; PORTD 4-7 are ports for barrel water level input
; PORTE 0 port for obstacle IR input
; PORTE 1 port for barrel IR input
; PORTE 2 port for tall/short barrel identification
; 


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
DelayCounter2		    equ 0x27;
DelayCounter3		    equ	0x28;
DelayCounter4		    equ 0x29;
DelayCounter5		    equ 0x2A;
DelayCounter6		    equ	0x2B;
DelayCounter7		    equ	0x2C;
DelayCounter8		    equ	0x2D;
		    
		     
MenuLocation		    equ 0x30;
OperatingMode		    equ 0x31;
CurrButtonState		    equ	0x32;
PrevButtonState		    equ 0x33;	
ButtonPushed		    equ 0x34;
LinePositionTracker	    equ 0x35;
CurrSenState1		    equ 0x36;
PrevSenState1		    equ	0x37;
CurrSenState2		    equ	0x38;
PrevSenState2		    equ	0x39;
LineStartTracker	    equ	0x3A;
CurrOpState		    equ 0x3B;
PrevOpState		    equ	0x3C;

BarrelHeightOne		    equ	0x40;
BarrelHeightTwo		    equ	0x41;
BarrelHeightThree	    equ	0x42;
BarrelHeightFour	    equ	0x43;
BarrelHeightFive	    equ	0x44;
BarrelHeightSix		    equ	0x45;
BarrelHeightSeven	    equ	0x46;
	    
WaterHeightOne		    equ	0x47;
WaterHeightTwo		    equ 0x48;
WaterHeightThree	    equ	0x49;
WaterHeightFour		    equ	0x4A;
WaterHeightFive		    equ	0x4B;
WaterHeightSix		    equ	0x4C;
WaterHeightSeven	    equ	0x4D;
	    
NumReg			    equ 0x50;
NumReg256		    equ	0x51;
NumBarrels		    equ	0x52;
BarrelNumber		    equ	0x53;
CurrDistance		    equ 0x54;
		    
BarrelDistance256	    equ 0x60;
BarrelDistanceOne	    equ	0x61;
BarrelDistanceTwo	    equ	0x62;
BarrelDistanceThree	    equ	0x63;
BarrelDistanceFour	    equ	0x64;
BarrelDistanceFive	    equ	0x65;
BarrelDistanceSix	    equ	0x66;
BarrelDistanceSeven	    equ	0x67;
BCDRegOne		    equ 0x68;
BCDRegTwo		    equ 0x69;
BCDRegThree		    equ	0x6A;		    

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

printch  macro Char, PositionReg, LineNumber 
    movf    PositionReg, w       
    iorlw   LineNumber
    call    WriteInstToLCD
    movlw   Char
    call    WriteDataToLCD
    endm
    
printnum macro NumReg, PositionReg, LineNumber 
    movf    PositionReg, w       
    iorlw   LineNumber 
    call    WriteInstToLCD
    movf    NumReg, w
    addlw   B'110000'
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

TableMenuTitle100	    db	"NUM BARRELS     ", 0
TableMenuTitle101	    db	"BARREL DISTANCE ", 0
TableMenuTitle102	    db	"BARREL HEIGHT   ", 0
TableMenuTitle103	    db	"WATER LEVEL	 ", 0
    
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
    
    bsf		TRISC, 5
    store	TRISD, B'11111111'
    bsf		TRISE, 0
    bsf		TRISE, 1
    bsf		TRISE, 2
    
    
    ; EEPROM initialization $%^&$%^&
    store	MenuLocation, B'01000000'
    call	InitializeLCD
    call	UpdateDisplay
    clrf	DelayCounter0
    clrf	DelayCounter1
    clrf	DelayCounter2
    clrf	DelayCounter3
    clrf	DelayCounter4
    clrf	DelayCounter5
    clrf	DelayCounter6
    clrf	DelayCounter7
    clrf	DelayCounter8
    
    MainLoop
	; polls sensors values
	movff	PORTC, CurrOpState
	movff	PORTD, CurrSenState1
	movff	PORTE, CurrSenState2
	
	
	ifequalf	OperatingMode, B'1', ScrollDisplay
	ifequalf	OperatingMode, B'10', Forward
	ifequalf	OperatingMode, B'100', Shrink
	ifequalf	OperatingMode, B'1000', ForwardSE
	ifequalf	OperatingMode, B'10000', Extend
	
	; polls push buttons
	movff	CurrSenState1, CurrButtonState
	btfsc	CurrButtonState, 2
	call	SelectedPushed
	btfsc	CurrButtonState, 0
	call	LeftPushed
	btfsc	CurrButtonState, 1
	call	RightPushed  
	btfsc	CurrButtonState, 3
	call	QuitPushed
	btfsc	ButtonPushed, 0 
	call	UpdateDisplay
	bcf	ButtonPushed, 0
	
	movff	CurrOpState, PrevOpState
	movff	CurrSenState1, PrevSenState1
	movff	CurrSenState2, PrevSenState2
	movff	CurrButtonState, PrevButtonState
	bra	MainLoop
	
; ScrollDisplay: updates the position tracker if a line longer than 16 
; characters is displayed for data
; Input: LinePositionTracker
ScrollDisplay
    incf	DelayCounter3
    movlw	B'11111111'
    subwf	DelayCounter3, W
    btfss	STATUS, 2
    return
    movlw	0
    movwf	DelayCounter3
    incf	DelayCounter7
    movlw	B'11111111'
    subwf	DelayCounter7, W
    btfss	STATUS, 2
    return
    movlw	0
    movwf	DelayCounter7
    incf	DelayCounter8
    movlw	B'100'
    subwf	DelayCounter8, W
    btfss	STATUS, 2
    return  
    
    movlw	B'10001'
    subwf	LineStartTracker, W
    btfsc	STATUS, 2
    call	ResetLine
    decf	LineStartTracker
    return
    
ResetLine
    movlw	B'1'
    movwf	LineStartTracker
    return

	
; Forward: Moves forward for a fixed amount of time, at a fixed speed, polls 
; sensors and logs distance travelled and barrel data.
; Input: DelayCounter2		    Output: OperatingMode
Forward
    bcf		LATA, 1
    movlw	B'11110001'		; needs testing
    subwf	DelayCounter2, W                      
    btfsc	STATUS, 2
    bra		StopMotor
    movlw	B'111100'			     
    subwf	DelayCounter2, W
    btfsc	STATUS, 2
    bra		StartMotor
    bra		Continue
    
StartMotor
    bsf		LATA, 0
    bsf		LATB, 0			    ; may be bcf
    bra		Continue
    
StopMotor
    bsf		LATC, 0
    movlw	B'0'		    ; Start:Stop = 4:1
    movwf	DelayCounter2
    bcf		LATA, 0
    bra		Continue
    
Continue	
    incf	DelayCounter2
    bra		PollObsta
    
PollObsta
    btfss	PORTE, 0
    bra		PollBarrel
    
    store	OperatingMode, B'100'
    bra		AddLog
    
PollBarrel
    btfss	CurrSenState2, 1
    bra		AddLog
    btfsc	PrevSenState2, 1
    bra		AddLog
    
    movff	CurrDistance, POSTINC0
    btfss	PORTE, 2
    bra		TallBarrel
    bra		ShortBarrel
    
TallBarrel
    bsf		POSTINC1, 0
    bsf		LATC, 2
    bra		Read
    
ShortBarrel
    bcf		POSTINC1, 0
    bcf		LATC, 2
    bra		Read
    
Read
    btfss	CurrSenState1, 4
    bra		Empty
    btfss	CurrSenState1, 5
    bra		Half
    bra		Full
    btfss	CurrSenState1, 6
    bra		Empty
    btfss	CurrSenState1, 7
    bra		Half
    bra		Full

Empty
    bsf		POSTINC2, 0
    bra		AddLog
    
Half
    bsf		POSTINC2, 1
    bra		AddLog
    
Full
    bsf		POSTINC2, 2
    bra		AddLog
    
AddLog
    call	InspectingDelay
    btfss	CurrOpState, 5
    return
    btfsc	PrevOpState, 5
    return
    incf	CurrDistance
    
    return
    
Shrink
    bcf		LATA, 0
    bsf		LATA, 1
    bsf		LATB, 1
    btfss	CurrOpState, 1
    bra		AddLog
    btfsc	PrevOpState, 1
    bra		AddLog
    store	OperatingMode, B'1000'
    bra		AddLog
    
Extend
    bcf		LATA, 0
    bsf		LATA, 1
    bcf		LATB, 1
    btfss	CurrOpState, 1
    bra		AddLog
    btfsc	PrevOpState, 1
    bra		AddLog
    store	OperatingMode, B'10'
    bra		AddLog
    
ForwardSE
    bsf		LATA, 0
    bsf		LATB, 0
    bcf		LATA, 1
    bra		AddLog
    
Backward
    bsf		LATA, 0
    bcf		LATB, 0
    bcf		LATA, 1
    call	InspectingDelay
    
    return
    
    
; UpdateDisplay: Updates display when user of the machine has changed modes
; Input: MenuLocation		    Output: None
UpdateDisplay 
    
    call ClearLCD
    
    ifequalf	MenuLocation, B'11111100', TopMenu0
    ifequalf	MenuLocation, B'11111101', TopMenu1
    ifequalf	MenuLocation, B'11111110', TopMenu2
    ifequalf	MenuLocation, B'11111111', TopMenu3
    ifequalf	MenuLocation, B'11000000', SubMenu00
    ifequalf	MenuLocation, B'11000001', SubMenu01
    ifequalf	MenuLocation, B'11000010', SubMenu02
    ifequalf	MenuLocation, B'11000011', SubMenu03
    ifequalf	MenuLocation, B'11000100', SubMenu04
    ifequalf	MenuLocation, B'11000101', SubMenu05
    ifequalf	MenuLocation, B'11000110', SubMenu06
    ifequalf	MenuLocation, B'11000111', SubMenu07 
    ifequalf	MenuLocation, B'11001000', SubMenu08 
    ifequalf	MenuLocation, B'11010000', SubMenu10
    ifequalf	MenuLocation, B'11010001', SubMenu11
    ifequalf	MenuLocation, B'11010010', SubMenu12
    ifequalf	MenuLocation, B'11100000', SubMenu20
    ifequalf	MenuLocation, B'11110000', SubMenu30
    ifequalf	MenuLocation, B'01000000', SubMenu100
    ifequalf	MenuLocation, B'01000001', SubMenu101
    ifequalf	MenuLocation, B'01000010', SubMenu102
    ifequalf	MenuLocation, B'01000011', SubMenu103
    ifequalf	MenuLocation, B'01000100', SubMenu100
    ifequalf	MenuLocation, B'01000101', SubMenu101
    ifequalf	MenuLocation, B'01000110', SubMenu102
    ifequalf	MenuLocation, B'01000111', SubMenu103
    ifequalf	MenuLocation, B'01001000', SubMenu100
    ifequalf	MenuLocation, B'01001001', SubMenu101
    ifequalf	MenuLocation, B'01001010', SubMenu102
    ifequalf	MenuLocation, B'01001011', SubMenu103
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
    
InspectingDelay
    
    
    incf	DelayCounter4
    movlw	B'11111111'
    subwf	DelayCounter4, W
    btfss	STATUS, 2
    return
    
    clrf	DelayCounter4
    incf	DelayCounter5
    movlw	B'111111'
    subwf	DelayCounter5, W
    btfss	STATUS, 2
    return
    
    clrf	DelayCounter5
    incf	DelayCounter6
    movlw	B'10'
    subwf	DelayCounter6, W
    btfss	STATUS, 2
    return
    
    clrf	DelayCounter6
    movlw	B'11000101'
    subwf	MenuLocation, W
    btfsc	STATUS, 2
    bra		ResetInspect
    incf	MenuLocation
    call	UpdateDisplay
    return
    
ResetInspect
    store	MenuLocation, B'11000000'
    call	UpdateDisplay
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
    
SubMenu30
    return
    
SubMenu100
    printline	TableMenuTitle100, B'10000000'
    return
    
SubMenu101
    printline	TableMenuTitle101, B'10000000'
    return

SubMenu102
    printline	TableMenuTitle102, B'10000000'
    movff	LineStartTracker, LinePositionTracker
    movff	NumBarrels, BarrelNumber
    movlw	B'1001111'
    movwf	NumReg256
    scrollLoop
	movlw	    B'1001111'
	movwf	    NumReg
	call	    numregtobcdreg
	printnum    BCDRegOne, LinePositionTracker, B'10000000'
	incf	    LinePositionTracker
	printnum    BCDRegTwo, LinePositionTracker, B'10000000'
	incf	    LinePositionTracker
	printnum    BCDRegThree, LinePositionTracker, B'10000000'
	incf	    LinePositionTracker
	printch	    B'01100011', LinePositionTracker, B'10000000'
	incf	    LinePositionTracker
	printch	    B'01101101', LinePositionTracker, B'10000000'
	incf	    LinePositionTracker
	incf	    LinePositionTracker
	rrcf	    NumReg256
	decfsz	    BarrelNumber
	bra	    scrollLoop
    return
    
SubMenu103
    printline	TableMenuTitle103, B'10000000'
    return
    
; QuitPushed
; Input: PrevButtonState	    Output: OperatingMode, MenuLocation, ButtonPushed
QuitPushed
    btfsc   PrevButtonState, 3
    return
    QuitButtonJustPressed
	ifequalb    MenuLocation, B'11000000', BackAndQuit
	ifequalb    MenuLocation, B'11000001', BackAndQuit
	ifequalb    MenuLocation, B'11000010', BackAndQuit
	ifequalb    MenuLocation, B'11000011', BackAndQuit
	ifequalb    MenuLocation, B'11000100', BackAndQuit
	ifequalb    MenuLocation, B'11000101', BackAndQuit
	ifequalb    MenuLocation, B'11000111', BackAndQuit
	ifequalb    MenuLocation, B'11001000', BackAndQuit
	ifequalb    MenuLocation, B'11010000', QuitOne
	ifequalb    MenuLocation, B'11010001', QuitOne
	ifequalb    MenuLocation, B'11010011', QuitOne
	ifequalb    MenuLocation, B'11100000', QuitOne
	ifequalb    MenuLocation, B'11110000', QuitOne
	ifequalb    MenuLocation, B'01000000', QuitTwo
	ifequalb    MenuLocation, B'01000001', QuitTwo
	ifequalb    MenuLocation, B'01000010', QuitTwo
	ifequalb    MenuLocation, B'01000011', QuitTwo
	ifequalb    MenuLocation, B'01010000', QuitTwo
	ifequalb    MenuLocation, B'01010001', QuitTwo
	ifequalb    MenuLocation, B'01010010', QuitTwo
	ifequalb    MenuLocation, B'01010011', QuitTwo
	ifequalb    MenuLocation, B'01100000', QuitTwo
	ifequalb    MenuLocation, B'01100001', QuitTwo
	ifequalb    MenuLocation, B'01100010', QuitTwo
	ifequalb    MenuLocation, B'01100011', QuitTwo
	
	return
	EndIfQuit
	bsf	ButtonPushed, 0
	return
QuitOne
    store   Temp0, B'100'
    QuitOneForLoop
	bsf	    STATUS, 0
	rrcf	    MenuLocation, f
	decf	    Temp0
	ifnequalb    Temp0, B'0', QuitOneForLoop  	
    goto    EndIfQuit
    
QuitTwo
    store   OperatingMode, B'0'
    store   Temp0, B'10'
    QuitTwoForLoop
	bsf	    STATUS, 0
	rrcf	    MenuLocation, f
	decf	    Temp0
	ifnequalb   Temp0, B'0', QuitTwoForLoop  	
    goto    EndIfQuit
    
BackAndQuit
    store OperatingMode, B'0'
    goto    QuitOne
    
; RightPushed
; Input: PrevButtonState	    Output: OperatingMode, MenuLocation, ButtonPushed
RightPushed
    
    btfsc	PrevButtonState, 1
    return
    
    RightButtonJustPressed
	ifequalb    MenuLocation, B'11111100', ScrollDownOne
	ifequalb    MenuLocation, B'11111101', ScrollDownOne
	ifequalb    MenuLocation, B'11111110', ScrollDownOne
	ifequalb    MenuLocation, B'11000111', ScrollDownOne
	ifequalb    MenuLocation, B'11010000', ScrollDownOne
	ifequalb    MenuLocation, B'11010001', ScrollDownOne
	ifequalb    MenuLocation, B'01000000', ScrollDownOne
	ifequalb    MenuLocation, B'01000001', ScrollDownOne
	ifequalb    MenuLocation, B'01000010', ScrollDownOne
	ifequalb    MenuLocation, B'01000100', ScrollDownOne
	ifequalb    MenuLocation, B'01000101', ScrollDownOne
	ifequalb    MenuLocation, B'01000110', ScrollDownOne
	ifequalb    MenuLocation, B'01001000', ScrollDownOne
	ifequalb    MenuLocation, B'01001001', ScrollDownOne
	ifequalb    MenuLocation, B'01001010', ScrollDownOne
	return
	EndIfScrollRight
	bsf	ButtonPushed, 0
	return
	
ScrollDownOne
    incf	    MenuLocation
    goto	    EndIfScrollRight 
    
    
; LeftPushed
; Input: PrevButtonState	    Output: OperatingMode, MenuLocation, ButtonPushed
LeftPushed
    btfsc   PrevButtonState, 0
    return
    LeftButtonJustPressed
	ifequalb    MenuLocation, B'11111101', ScrollUpOne
	ifequalb    MenuLocation, B'11111110', ScrollUpOne
	ifequalb    MenuLocation, B'11111111', ScrollUpOne
	ifequalb    MenuLocation, B'11001000', ScrollUpOne
	ifequalb    MenuLocation, B'11010001', ScrollUpOne
	ifequalb    MenuLocation, B'11010010', ScrollUpOne
	ifequalb    MenuLocation, B'01000001', ScrollUpOne
	ifequalb    MenuLocation, B'01000010', ScrollUpOne
	ifequalb    MenuLocation, B'01000011', ScrollUpOne
	ifequalb    MenuLocation, B'01000101', ScrollUpOne
	ifequalb    MenuLocation, B'01000110', ScrollUpOne
	ifequalb    MenuLocation, B'01000111', ScrollUpOne
	ifequalb    MenuLocation, B'01001001', ScrollUpOne
	ifequalb    MenuLocation, B'01001010', ScrollUpOne
	ifequalb    MenuLocation, B'01001011', ScrollUpOne
	return
	EndIfScrollLeft
	bsf	ButtonPushed, 0
	return
	
	
ScrollUpOne
    decf   MenuLocation
    goto    EndIfScrollLeft
    

    
; SelectedPushed
; Input: PrevButtonState	    Output: OperatingMode, MenuLocation, ButtonPushed
SelectedPushed
    btfsc   PrevButtonState, 2
    return

    SelectButtonJustPressed
	ifequalb    MenuLocation, B'11111100', EnterOneAndStart
	ifequalb    MenuLocation, B'11111101', EnterOne
	ifequalb    MenuLocation, B'11111110', EnterOne
	ifequalb    MenuLocation, B'11111111', EnterOne
	ifequalb    MenuLocation, B'11000111', Save
	ifequalb    MenuLocation, B'11001000', QuitOne
	ifequalb    MenuLocation, B'11010000', EnterTwo
	ifequalb    MenuLocation, B'11010001', EnterTwo
	ifequalb    MenuLocation, B'11010010', EnterTwo
	return
	
	
	EndIfEnter
	bsf	    ButtonPushed, 0
	return

	
EnterOneAndStart
    store   OperatingMode, B'10'
    clrf    FSR0H
    movlw   0x61
    movwf   FSR0L
    clrf    FSR1H
    movlw   0x40
    movwf   FSR0L
    clrf    FSR2H
    movlw   0x47
    movwf   FSR2L    
    goto    EnterOne
	
EnterOne
    store   Temp0, B'100'
    EnterOneForLoop
	bcf	    STATUS, 0
	rlcf	    MenuLocation, f
	decf	    Temp0
	ifnequalb    Temp0, B'0', EnterOneForLoop  	
    goto    EndIfEnter
    
EnterTwo
    store   OperatingMode, B'1'
    store   Temp0, B'10'
    EnterTwoForLoop
	bcf	    STATUS, 0
	rlcf	    MenuLocation, f
	decf	    Temp0
	ifnequalb   Temp0, B'0', EnterTwoForLoop  	
    goto    EndIfEnter
    

Save
    goto    QuitOne   
    
numregtobcdreg 
    clrf    BCDRegOne
    clrf    BCDRegTwo
    clrf    BCDRegThree
    
    movlw   B'1100100'
    
    hundloop
	
	subwf   NumReg, f
	btfss   STATUS, 4
	incf	BCDRegOne
	btfss	STATUS, 4
	bra	hundloop
    addwf   NumReg, f
 
    movlw   B'1010'
    tenloop
	subwf   NumReg, f
	btfss   STATUS, 4
	incf	BCDRegTwo
	btfss	STATUS, 4
	bra	tenloop
    addwf   NumReg, f
    movlw   B'1'
    oneloop
	subwf   NumReg, f
	btfss   STATUS, 4
	incf	BCDRegThree
	btfss	STATUS, 4
	bra	oneloop
	
    btfss   NumReg256, 0
    return
    movlw   B'101'
    addwf   BCDRegThree, f
    movf    BCDRegThree, w
    movlw   B'1010'
    subwf   BCDRegThree, w
    btfsc   STATUS, 4
    bra	    Tens
    movwf   BCDRegThree
    incf    BCDRegTwo
    movf    BCDRegTwo, w
    movlw   B'1010'
    subwf   BCDRegTwo, w
    btfsc   STATUS, 4
    bra	    Tens
    movwf   BCDRegTwo
    incf    BCDRegOne
    
    Tens
    movlw   B'101'
    addwf   BCDRegTwo, f
    movf    BCDRegTwo, w
    movlw   B'1010'
    subwf   BCDRegTwo, w
    btfsc   STATUS, 4
    bra	    Huns
    movwf   BCDRegTwo
    incf    BCDRegOne
    
    Huns
    movlw   B'10'
    addwf   BCDRegOne, f
    
    store   LATA, B'11'
    return
	
    
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
    movff   PORTB, Temp1
    andlw   0xF0
    iorwf   Temp1,F                 ; OR operation and store it in File Reg
    iorlw   0x0F
    andwf   Temp1,F                 ; AND operation and store it in File Reg
    movff   Temp1, LATB
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