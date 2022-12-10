    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db "10"

iy_cache:
    db 0, 0

x_reg:
    db 1,0,0,0
tmp:
    db 0,0,0,0
result:
    db 0,0,0,0

time:
    db 0xec, 0xff, 0xff, 0xff
time_total:
    db 0,0,0,0
strength:
    db 0,0,0,0
twenty:
    db 20,0,0,0
fourty:
    db 40,0,0,0

prod:
    db 0,0,0,0

step:
    push af
    push ix
    push iy
    ld ix, time
    ld iy, dec_one
    call add32le
    ld ix, time_total
    call add32le
    ld ix, time
    ld iy, dec_zero
    call eq32le
    cp 1
    jp nz, dont_add_strength
    ld ix, time
    ld iy, fourty
    call sub32le
    ld ix, prod
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld iy, time_total
    call add32le
    ld iy, x_reg
    call mul32le
    ld iy, prod
    ld ix, strength
    call add32le
dont_add_strength:
    pop iy
    pop ix
    pop af
    ret

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
    call intro_p2
compute:
    ld bc, 5
    ld hl, 0xa000
parse_loop:
    ld a, (hl)
    cp 0
    jp z, parse_done
    add hl, bc
    call step
    cp 0x61 ; 'a'
    jp nz, parse_loop
    call step
    ld ix, tmp
    call parses32le
    ld iy, ix
    ld ix, x_reg
    call add32le
    inc hl
    jp parse_loop
parse_done:
    
output:
    ld iy,(iy_cache)
    ld ix,strength 
    call p1_result   
end:
    jp end

prog_end:
    savebin "day10.bin",prog_start,prog_end-prog_start
    labelslist "day10.labels"

