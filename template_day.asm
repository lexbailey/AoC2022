    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db "??" ; TODO fill in day number

iy_cache:
    db 0, 0

result:
    db 0,0,0,0

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ; TODO
output:
    ld iy,(iy_cache)
    ld ix, result
    call p1_result   
end:
    jp end

prog_end:
    ; TODO fill in day number
    savebin "dayXX.bin",prog_start,prog_end-prog_start
    ;labelslist "dayXX.labels"

