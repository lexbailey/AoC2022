; From http://www.breakintoprogram.co.uk/hardware/computers/zx-spectrum/assembly-language/z80-tutorials/print-in-assembly-language
;
; ROM routine addresses
;
ROM_CLS                 EQU  0x0DAF             ; Clears the screen and opens channel 2
ROM_OPEN_CHANNEL        EQU  0x1601             ; Open a channel
ROM_PRINT               EQU  0x203C             ; Print a string 
;
; PRINT control codes - work with ROM_PRINT and RST 0x10
;
INK                     EQU 0x10
PAPER                   EQU 0x11
FLASH                   EQU 0x12
BRIGHT                  EQU 0x13
INVERSE                 EQU 0x14
OVER                    EQU 0x15
AT                      EQU 0x16
TAB                     EQU 0x17
CR                      EQU 0x0C

