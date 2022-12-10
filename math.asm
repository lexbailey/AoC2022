
add32le: ; (ix) = (ix) + (iy)
    push af
    or a
    ld a,(ix)
    adc a,(iy)
    ld (ix), a
    ld a, (ix+1)
    adc a,(iy+1)
    ld (ix+1), a
    ld a, (ix+2)
    adc a,(iy+2)
    ld (ix+2), a
    ld a, (ix+3)
    adc a,(iy+3)
    ld (ix+3), a
    pop af
    ret

one32le:
    db 1, 0, 0, 0

inv32le: ; (ix) = -(ix)
    push af
    ld a, (ix)
    cpl
    ld (ix), a
    ld a, (ix+1)
    cpl
    ld (ix+1), a
    ld a, (ix+2)
    cpl
    ld (ix+2), a
    ld a, (ix+3)
    cpl
    ld (ix+3), a
    pop af
    push iy
    ld iy, one32le
    call add32le
    pop iy
    ret

sub32le: ; (ix) = (ix) - (iy)
    push ix
    push iy
    pop ix
    call inv32le
    pop ix
    call add32le
    push ix
    push iy
    pop ix
    call inv32le
    pop ix
    ret

sra32le: ; (ix) = (ix)>>1
    sra (ix+3)
    rr (ix+2)
    rr (ix+1)
    rr (ix)
    ret

sra32le_iy: ; (iy) = (iy)>>1
    sra (iy+3)
    rr (iy+2)
    rr (iy+1)
    rr (iy)
    ret

dbl32le: ; (ix) = (ix) << 1
    sla (ix)
    rl (ix+1)
    rl (ix+2)
    rl (ix+3)
    ret

dbl32le_iy: ; (iy) = (iy) << 1
    sla (iy)
    rl (iy+1)
    rl (iy+2)
    rl (iy+3)
    ret

mul32le: ; (ix) = (ix) * (iy)
    push bc
    push de
    push hl
    push iy
    ; Copy (ix) to (tmp2)
    ld bc, 4
    push ix
    pop hl
    ld de, mul32le_tmp2
    ldir
    ; Copy (iy) to (tmp1)
    ld bc, 4
    push iy
    pop hl
    ld de, mul32le_tmp1
    ldir
    ; set (ix) to 0
    ld (ix+0), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ; 32 step multiply loop
    ld b, 32
    ;ld iy, mul32le_tmp2
    ld de, 4
mul32le_loop:
    ld iy, mul32le_tmp1 ; 20
    call sra32le_iy 
    ld iy, mul32le_tmp2 ; 20
    call c, add32le
    call dbl32le_iy
    djnz mul32le_loop
    pop iy
    pop hl
    pop de
    pop bc
    ret
mul32le_tmp1:
    db 0,0,0,0
mul32le_tmp2:
    db 0,0,0,0

; Optimised multiply by 10
; (ix) = (ix) * 10
; decomposes 10 into sum of powers of two
; x * 10 === (x * 2) + (x * 8) === dbl(x) + dbl(dbl(dbl(x)))
; three doubles plus an add
multen32le:
    push bc
    push de
    push hl
    push iy
    ; (ix) = (ix) * 2
    call dbl32le
    ; (tmp1) = (ix)
    ld bc, 4
    push ix
    pop hl
    ld de, multen32le_tmp1
    ldir
    ; (ix) = (ix) * 2
    call dbl32le
    ; (ix) = (ix) * 2
    call dbl32le
    ; (ix) = (ix) + (tmp1)
    ld iy, multen32le_tmp1
    call add32le
    pop iy
    pop hl
    pop de
    pop bc
    ret
multen32le_tmp1:
    db 0,0,0,0

hexit: ; Converts a from a number in the range 0-15 to an ascii value 0-9A-F
    cp 10
    jp m, lt10
    add a, 7
lt10:
    add a, 48
    ret
    
hexstr32le: ; converts (ix) to a string, iy points to the buffer where the string will be placed
    push af
    push bc
    push ix
    push iy
    ld (iy), '0'
    ld (iy+1), 'x'
    ld b, 4
    ld c, 0xf
hexstrloop:
    ld a, (ix+3)
    and c
    call hexit
    ld (iy+3), a
    ld a, (ix+3)
    srl a
    srl a
    srl a
    srl a
    call hexit
    ld (iy+2), a
    inc iy
    inc iy
    dec ix
    djnz hexstrloop
    pop iy
    pop ix
    pop bc
    pop af
    ret

eq32le: ; a = (ix) == (iy)
    push bc
    ld a, (ix+0)
    ld c, (iy+0)
    cp c
    jp nz, eq32le_noteq
    ld a, (ix+1)
    ld c, (iy+1)
    cp c
    jp nz, eq32le_noteq
    ld a, (ix+2)
    ld c, (iy+2)
    cp c
    jp nz, eq32le_noteq
    ld a, (ix+3)
    ld c, (iy+3)
    cp c
    jp nz, eq32le_noteq
    pop bc
    ld a, 1
    ret
eq32le_noteq:
    pop bc
    ld a, 0
    ret

gt32le: ; a = (ix) > (iy)
    push bc
    ld a, (iy+3)
    ld c, (ix+3)
    cp c
    jp c, gt32le_gt
    jp nz, gt32le_ngt
    
    ld a, (iy+2)
    ld c, (ix+2)
    cp c
    jp c, gt32le_gt
    jp nz, gt32le_ngt

    ld a, (iy+1)
    ld c, (ix+1)
    cp c
    jp c, gt32le_gt
    jp nz, gt32le_ngt

    ld a, (iy)
    ld c, (ix)
    cp c
    jp c, gt32le_gt
gt32le_ngt:
    pop bc
    ld a, 0
    ret
gt32le_gt:
    pop bc
    ld a, 1
    ret

gte32le:
    call gt32le
    cp 1
    ret z
    jp eq32le ; tail call
    

dec_consts:
    db 0x00, 0xca, 0x9a, 0x3b
    db 0x00, 0xe1, 0xf5, 0x05
    db 0x80, 0x96, 0x98, 0x00
    db 0x40, 0x42, 0x0f, 0x00
    db 0xa0, 0x86, 0x01, 0x00
    db 0x10, 0x27, 0x00, 0x00
    db 0xe8, 0x03, 0x00, 0x00
    db 0x64, 0x00, 0x00, 0x00
dec_ten:
    db 0x0a, 0x00, 0x00, 0x00
dec_one:
dec_last:
    db 0x01, 0x00, 0x00, 0x00
dec_zero:
    db 0,0,0,0

str32le: ; converts (ix) to a string, iy points to the buffer where the string will be placed
    ; Copy (ix) to (tmp1)
    push af
    push bc
    push de
    push hl
    push iy
    push iy
    ld bc, 4
    push ix
    pop hl
    ld de, str32le_tmp1
    ldir
    push iy
    pop hl
    ld iy, dec_consts
    ld ix, str32le_tmp1
    ld d, 48
    ld bc, 4
str32le_digit_loop:
    call gte32le
    cp 1
    jp nz, str32le_digit_done
    call sub32le
    inc d
    jp str32le_digit_loop
str32le_digit_done:
    add iy, bc
    ld (hl), d
    inc hl
    ld d, 48
    ld ix, dec_last
    call eq32le
    cp 1
    ld ix, str32le_tmp1
    jp z, str32le_last
    jp str32le_digit_loop
str32le_last:
    ld a, d
    add a,(ix)
    ld (hl), a
    pop hl
    ld a, 48
    ld b, 9
str32le_space_pad_loop:
    cp (hl)
    jp nz, str32le_done
    ld (hl), 32
    inc hl
    dec b
    jp z, str32le_done
    jp str32le_space_pad_loop
str32le_done:
    pop iy
    pop hl
    pop de
    pop bc
    pop af
    ret
str32le_tmp1:
    db 0,0,0,0


parse32le: ; takes a buffer (hl) and consumes digits until a non-digit is reached, leaves hl at the end of the parsed number, stores number at (ix)
    ; this function works by multiplying by 10 and adding the next char as unit value until it finds an unrecognised char
    push af
    push iy
    ; (ix) = 0
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld iy, parse32le_tmp1
parse32le_loop:
    ; get next char
    ld a, (hl)
    ; ascii zero to number 0
    sub 48
    ; is number less than 10?
    cp 10
    jp nc, parse32le_done ; if greater than 10 then we're done
    ; multiply (ix) by 10
    call multen32le
    ; add the next digit
    ld (parse32le_tmp1), a
    call add32le
    ; loop
    inc hl
    jp parse32le_loop
parse32le_done:
    pop iy
    pop af
    ret
parse32le_tmp1:
    db 0,0,0,0
