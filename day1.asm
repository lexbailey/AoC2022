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
    ld hl, strvar
    call parse32le
    ld iy, number2
    call add32le
    ld iy, strvar
    call str32le
    ld iy,(iy_cache)
    ld bc, 10
    ld de, strvar 
    call ROM_PRINT
end:
    jp end

number1:
    db 0,0,0,0
number2:
    db 2,0,0,0
strvar:
    db "1234      "

text:
    db AT, 0, 0, INK, 8 
text_len: equ $ - text

prog_end:
    savebin "day1.bin",prog_start,prog_end-prog_start

