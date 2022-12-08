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

buffer14:
    db 0,0,0,0,0,0,0,0,0,0
buffer14_4:
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
    call intro_p2
    jp compute2


check_unique_14:
    push hl
    push bc
    ld hl, buffer14
    ld b, 13
check_outer:
    ld c, (hl)
    inc hl
    call check_unique_14_part
    cp 0
    jp z, check_outer_fail
    djnz check_outer
    ld a, 1
    pop bc
    pop hl
    ret
check_outer_fail:
    pop bc
    pop hl
    ld a, 0
    ret

check_unique_14_part:
    push hl
    push bc
check_loop:
    ld a, (hl)
    inc hl
    cp c
    jp z, check_unique_14_fail
    djnz check_loop
    pop bc
    pop hl
    ld a, 1
    ret
check_unique_14_fail:
    pop bc
    pop hl
    ld a, 0
    ret
    

compute2:
    ; fill the 14 item ring buffer
    ld hl, 0xa000
    ld de, buffer14
    ld bc, 14
    ldir

compute2_next:
    ld b, 14
    ld de, buffer14
compute2_loop:
    call check_unique_14
    cp 1
    jp z, found_start
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    djnz compute2_loop
    jp compute2_next


found_start:
    ld bc, 0xa000
    xor a
    sbc hl, bc
    ld ix, result
    ld (ix), l
    ld (ix+1), h
output2:
    ld iy,(iy_cache)
    ld ix, result
    call p2_result   
    


end:
    jp end

prog_end:
    savebin "day6.bin",prog_start,prog_end-prog_start
    labelslist "day6.labels"

