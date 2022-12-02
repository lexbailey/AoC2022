    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 
    include "print.asm"
    include "math.asm"

iy_cache:
    db 0, 0
start:
    ld (iy_cache),iy
    call ROM_CLS
    ld de, text
    ld bc, text_len
    call ROM_PRINT
    ; TODO computation goes here
done:
    ; TODO printing of result goes here
    ld ix, number1
    ld iy, strvar
    call str32le
    ld iy,(iy_cache)
    ld bc, 10
    ld de, strvar 
    call ROM_PRINT
end:
    jp end

number1:
    ;db 0x55, 0x00, 0x00, 0x00
    db 0x5d, 0xcb, 0x74, 0x00
;number2:
;    db 0x05, 0x05, 0x00, 0x01
strvar:
    db "testtest.."
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

text:
    db AT, 0, 0, INK, 8 
text_len: equ $ - text

prog_end:
    savebin "day1.bin",prog_start,prog_end-prog_start

