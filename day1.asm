    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 1"

iy_cache:
    db 0, 0
start:
p1:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ld hl, 0xa000 ; location of input text
elfloop:
    ld a, (hl)
    cp 10
    jp z, nextelf
    ld ix, next
    call parse32le
    ld ix, this
    ld iy, next
    call add32le
    inc hl
    jp elfloop
nextelf:
    ; see if this number is bigger than the previous one
    ld iy, max
    call gt32le
    cp 1
    jp nz, notbigger
    ld bc, 4
    ld de, max
    push hl
    ld hl, this
    ldir
    pop hl
notbigger:
    inc hl
    ld a, (hl)
    cp 0
    jp z, output
    ld a, 0
    ld (this), a
    ld (this+1), a
    ld (this+2), a
    ld (this+3), a
    jp elfloop
output:
    ld ix, max
    ld iy,(iy_cache)
    call p1_result
endp1:
    jp p2

max:
    db 0,0,0,0
this:
    db 0,0,0,0
next:
    db 0,0,0,0


p2:
    ld (iy_cache),iy
    call intro_p2
compute2:
    ld hl, 0xa000 ; location of input text
    ld a, 0
    ld (this), a
    ld (this+1), a
    ld (this+2), a
    ld (this+3), a
elfloop2:
    ld a, (hl)
    cp 10
    jp z, nextelf2
    ld ix, next
    call parse32le
    ld ix, this
    ld iy, next
    call add32le
    inc hl
    jp elfloop2
nextelf2:
    ; see if this number is bigger than the previous one
    ld iy, max3
    call gt32le
    cp 1
    jp nz, notbigger2
    ; determine where to place this number
    ld iy, max2
    call gt32le
    cp 1
    jp nz, replace_max3
    ld iy, max1
    call gt32le
    cp 1
    jp nz, replace_max2
    jp replace_max1
replace_max1:
    push hl
    ld bc, 4
    ld hl, max2
    ld de, max3
    ldir
    ld bc, 4
    ld hl, max1
    ld de, max2
    ldir
    pop hl
    ld de, max1
    jp replace
replace_max2:
    ld bc, 3
    push hl
    ld hl, max2
    ld de, max3
    ldir
    pop hl
    ld de, max2
    jp replace
replace_max3:
    ld de, max3
replace:
    ld bc, 4
    push hl
    ld hl, this
    ldir
    pop hl

    
notbigger2:
    inc hl
    ld a, (hl)
    cp 0
    jp z, sum2
    ld a, 0
    ld (this), a
    ld (this+1), a
    ld (this+2), a
    ld (this+3), a
    jp elfloop2
sum2:
    ld ix, max1
    ld iy, max2
    call add32le
    ld iy, max3
    call add32le
output2:
    ld iy,(iy_cache)
    call p2_result   
end:
    jp end

max1:
    db 0,0,0,0
max2:
    db 0,0,0,0
max3:
    db 0,0,0,0

prog_end:
    savebin "day1.bin",prog_start,prog_end-prog_start

