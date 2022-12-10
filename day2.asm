    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "wait.asm"
    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 2"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0
this:
    db 0,0,0,0

rps_scores:
    ;ABC
    db 4,1,7,0
    db 8,5,2,0
    db 3,9,6,0
;XYZ

    ;  A  B  C
alt_scores:
    db 3, 1, 2, 0 ;X l
    db 4, 5, 6, 0 ;Y d
    db 8, 9, 7, 0 ;Z w
start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ld hl, 0xa000
loop:
    ld a, (hl)
    sub 65 ; ABC
    ld b,a
    inc hl
    inc hl
    ld a, (hl)
    sub 88 ; XYZ 
    inc hl
    inc hl
    sla a
    sla a
    or b
    push hl
    ld hl, rps_scores
    ld d, 0
    ld e, a
    add hl, de
    ld a,(hl)
    ld (this),a
    ld ix, result
    ld iy, this
    call add32le
    pop hl
    ld a, 0
    cp (hl)
    jp z, output
    jp loop
output:
    ld iy,(iy_cache)
    ld ix, result
    call p1_result   
    call intro_p2
    ld ix, result
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
compute_p2:
    ld hl, 0xa000
loop2:
    ld a, (hl)
    sub 65 ; ABC
    ld b,a
    inc hl
    inc hl
    ld a, (hl)
    sub 88 ; XYZ 
    inc hl
    inc hl
    sla a
    sla a
    or b
    push hl
    ld hl, alt_scores
    ld d, 0
    ld e, a
    add hl, de
    ld a,(hl)
    ld (this),a
    ld ix, result
    ld iy, this
    call add32le
    pop hl
    ld a, 0
    cp (hl)
    jp z, output2
    jp loop2
output2:
    ld iy,(iy_cache)
    ld ix, result
    call p2_result   
    call large_delay
end:
    jp end

prog_end:
    savebin "day2.bin",prog_start,prog_end-prog_start
    labelslist "day2.labels"
