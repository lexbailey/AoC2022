    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 6"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0

buffer:
    db 0,0,0,0

check_unique:
    push af
    push ix
    push bc
    push de
    ld ix, buffer
    ld c, (ix+1)
    ld a, (ix+0)
    cp c
    jp z, check_unique_fail
    ld d, (ix+2)
    cp d
    jp z, check_unique_fail
    ld e, (ix+3)
    cp e
    jp z, check_unique_fail
    ld a, (ix+1)
    cp d
    jp z, check_unique_fail
    cp e
    jp z, check_unique_fail
    ld a, (ix+2)
    cp e
    jp z, check_unique_fail
    pop de
    pop bc
    pop ix
    pop af
    ld a, 1
    ret   
check_unique_fail:
    pop de
    pop bc
    pop ix
    pop af
    ld a, 0
    ret

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ld bc, 4
    ld hl, 0xa000
    ld a, (hl)
    ld (buffer), a
    inc hl
    ld a, (hl)
    ld (buffer+1), a
    inc hl
    ld a, (hl)
    ld (buffer+2), a
    inc hl
    ld a, (hl)
    ld (buffer+3), a
    inc hl
loop:
    ld a, (hl)
    ld (buffer), a
    inc hl
    inc bc
    call check_unique
    cp 1
    jp z, found

    ld a, (hl)
    ld (buffer+1), a
    inc hl
    inc bc
    call check_unique
    cp 1
    jp z, found
    ld a, (hl)

    ld (buffer+2), a
    inc hl
    inc bc
    call check_unique
    cp 1
    jp z, found
    ld a, (hl)

    ld (buffer+3), a
    inc hl
    inc bc
    call check_unique
    cp 1
    jp z, found

    jp loop

found:
    ld ix, result
    ld (ix), c
    ld (ix+1), b
output:
    ld iy,(iy_cache)
    ld ix, result
    call p1_result   
end:
    jp end

prog_end:
    savebin "day6.bin",prog_start,prog_end-prog_start
    labelslist "day6.labels"

