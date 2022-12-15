
add48le: ; (ix) = (ix) + (iy)
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

    ld a, (ix+4)
    adc a,(iy+4)
    ld (ix+4), a

    ld a, (ix+5)
    adc a,(iy+5)
    ld (ix+5), a
    pop af
    ret

one48le:
    db 1, 0, 0, 0, 0, 0

inv48le: ; (ix) = -(ix)
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

    ld a, (ix+4)
    cpl
    ld (ix+4), a

    ld a, (ix+5)
    cpl
    ld (ix+5), a

    pop af
    push iy
    ld iy, one48le
    call add48le
    pop iy
    ret

sub48le: ; (ix) = (ix) - (iy)
    push ix
    push iy
    pop ix
    call inv48le
    pop ix
    call add48le
    push ix
    push iy
    pop ix
    call inv48le
    pop ix
    ret

sra48le: ; (ix) = (ix)>>1
    sra (ix+5)
    rr (ix+4)
    rr (ix+3)
    rr (ix+2)
    rr (ix+1)
    rr (ix)
    ret

sra48le_iy: ; (iy) = (iy)>>1
    sra (iy+5)
    rr (iy+4)
    rr (iy+3)
    rr (iy+2)
    rr (iy+1)
    rr (iy)
    ret

dbl48le: ; (ix) = (ix) << 1
    sla (ix)
    rl (ix+1)
    rl (ix+2)
    rl (ix+3)
    rl (ix+4)
    rl (ix+5)
    ret

dbl48le_iy: ; (iy) = (iy) << 1
    sla (iy)
    rl (iy+1)
    rl (iy+2)
    rl (iy+3)
    rl (iy+4)
    rl (iy+5)
    ret

mul48le: ; (ix) = (ix) * (iy)
    push bc
    push de
    push hl
    push iy
    ; Copy (ix) to (tmp2)
    ld bc, 6
    push ix
    pop hl
    ld de, mul48le_tmp2
    ldir
    ; Copy (iy) to (tmp1)
    ld bc, 6
    push iy
    pop hl
    ld de, mul48le_tmp1
    ldir
    ; set (ix) to 0
    ld (ix+0), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld (ix+4), 0
    ld (ix+5), 0
    ; 48 step multiply loop
    ld b, 48
    ;ld de, 4
mul48le_loop:
    ld iy, mul48le_tmp1 ; 20
    call sra48le_iy 
    ld iy, mul48le_tmp2 ; 20
    call c, add48le
    call dbl48le_iy
    djnz mul48le_loop
    pop iy
    pop hl
    pop de
    pop bc
    ret
mul48le_tmp1:
    db 0,0,0,0,0,0
mul48le_tmp2:
    db 0,0,0,0,0,0

; Optimised multiply by 10
; (ix) = (ix) * 10
; decomposes 10 into sum of powers of two
; x * 10 === (x * 2) + (x * 8) === dbl(x) + dbl(dbl(dbl(x)))
; three doubles plus an add
multen48le:
    push bc
    push de
    push hl
    push iy
    ; (ix) = (ix) * 2
    call dbl48le
    ; (tmp1) = (ix)
    ld bc, 6
    push ix
    pop hl
    ld de, multen48le_tmp1
    ldir
    ; (ix) = (ix) * 2
    call dbl48le
    ; (ix) = (ix) * 2
    call dbl48le
    ; (ix) = (ix) + (tmp1)
    ld iy, multen48le_tmp1
    call add48le
    pop iy
    pop hl
    pop de
    pop bc
    ret
multen48le_tmp1:
    db 0,0,0,0,0,0

; TODO extract this to a separate file, it doesn't need to be duplicated
hexit48: ; Converts a from a number in the range 0-15 to an ascii value 0-9A-F
    cp 10
    jp m, lt10
    add a, 7
lt1048:
    add a, 48
    ret
    
hexstr48le: ; converts (ix) to a string, iy points to the buffer where the string will be placed
    push af
    push bc
    push ix
    push iy
    ld (iy), '0'
    ld (iy+1), 'x'
    ld b, 6
    ld c, 0xf
hexstrloop48:
    ld a, (ix+3)
    and c
    call hexit48
    ld (iy+3), a
    ld a, (ix+3)
    srl a
    srl a
    srl a
    srl a
    call hexit48
    ld (iy+2), a
    inc iy
    inc iy
    dec ix
    djnz hexstrloop48
    pop iy
    pop ix
    pop bc
    pop af
    ret

eq48le: ; a = (ix) == (iy)
    push bc

    ld a, (ix+0)
    ld c, (iy+0)
    cp c
    jp nz, eq48le_noteq

    ld a, (ix+1)
    ld c, (iy+1)
    cp c
    jp nz, eq48le_noteq

    ld a, (ix+2)
    ld c, (iy+2)
    cp c
    jp nz, eq48le_noteq

    ld a, (ix+3)
    ld c, (iy+3)
    cp c
    jp nz, eq48le_noteq

    ld a, (ix+4)
    ld c, (iy+4)
    cp c
    jp nz, eq48le_noteq

    ld a, (ix+5)
    ld c, (iy+5)
    cp c
    jp nz, eq48le_noteq

    pop bc
    ld a, 1
    ret
eq48le_noteq:
    pop bc
    ld a, 0
    ret

gt48le: ; a = (ix) > (iy)
    push bc

    ld a, (iy+5)
    ld c, (ix+5)
    cp c
    jp c, gt48le_gt
    jp nz, gt48le_ngt
 
    ld a, (iy+4)
    ld c, (ix+4)
    cp c
    jp c, gt48le_gt
    jp nz, gt48le_ngt
 
    ld a, (iy+3)
    ld c, (ix+3)
    cp c
    jp c, gt48le_gt
    jp nz, gt48le_ngt
    
    ld a, (iy+2)
    ld c, (ix+2)
    cp c
    jp c, gt48le_gt
    jp nz, gt48le_ngt

    ld a, (iy+1)
    ld c, (ix+1)
    cp c
    jp c, gt48le_gt
    jp nz, gt48le_ngt

    ld a, (iy)
    ld c, (ix)
    cp c
    jp c, gt48le_gt
gt48le_ngt:
    pop bc
    ld a, 0
    ret
gt48le_gt:
    pop bc
    ld a, 1
    ret

gte48le:
    call gt48le
    cp 1
    ret z
    jp eq48le ; tail call
    
dec48_consts:
    db 0x00, 0x40, 0x7a, 0x10, 0xf3, 0x5a
    db 0x00, 0xa0, 0x72, 0x4e, 0x18, 0x09
    db 0x00, 0x10, 0xa5, 0xd4, 0xe8, 0x00
    db 0x00, 0xe8, 0x76, 0x48, 0x17, 0x00
    db 0x00, 0xe4, 0x0b, 0x54, 0x02, 0x00
    db 0x00, 0xca, 0x9a, 0x3b, 0x00, 0x00
    db 0x00, 0xe1, 0xf5, 0x05, 0x00, 0x00
    db 0x80, 0x96, 0x98, 0x00, 0x00, 0x00
    db 0x40, 0x42, 0x0f, 0x00, 0x00, 0x00
    db 0xa0, 0x86, 0x01, 0x00, 0x00, 0x00
    db 0x10, 0x27, 0x00, 0x00, 0x00, 0x00
    db 0xe8, 0x03, 0x00, 0x00, 0x00, 0x00
    db 0x64, 0x00, 0x00, 0x00, 0x00, 0x00
dec48_ten:
    db 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00
dec48_one:
dec48_last:
    db 0x01, 0x00, 0x00, 0x00, 0x00, 0x00
dec48_zero:
    db 0,0,0,0,0,0

str48le: ; converts (ix) to a string, iy points to the buffer where the string will be placed
    push af
    push bc
    push de
    push hl
    push iy
    push iy
    ; Copy (ix) to (tmp1)
    ld bc, 6
    push ix
    pop hl
    ld de, str48le_tmp1
    ldir
    push iy
    pop hl
    ld iy, dec48_consts
    ld ix, str48le_tmp1
    ld d, 48
    ld bc, 6
str48le_digit_loop:
    call gte48le
    cp 1
    jp nz, str48le_digit_done
    call sub48le
    inc d
    jp str48le_digit_loop
str48le_digit_done:
    add iy, bc
    ld (hl), d
    inc hl
    ld d, 48
    ld ix, dec48_last
    call eq48le
    cp 1
    ld ix, str48le_tmp1
    jp z, str48le_last
    jp str48le_digit_loop
str48le_last:
    ld a, d
    add a,(ix)
    ld (hl), a
    pop hl
    ld a, 48
    ld b, 14
str48le_space_pad_loop:
    cp (hl)
    jp nz, str48le_done
    ld (hl), 32
    inc hl
    dec b
    jp z, str48le_done
    jp str48le_space_pad_loop
str48le_done:
    pop iy
    pop hl
    pop de
    pop bc
    pop af
    ret
str48le_tmp1:
    db 0,0,0,0,0,0


parse48le: ; takes a buffer (hl) and consumes digits until a non-digit is reached, leaves hl at the end of the parsed number, stores number at (ix)
    ; this function works by multiplying by 10 and adding the next char as unit value until it finds an unrecognised char
    push af
    push iy
    ; (ix) = 0
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld (ix+4), 0
    ld (ix+5), 0
    ld iy, parse48le_tmp1
parse48le_loop:
    ; get next char
    ld a, (hl)
    ; ascii zero to number 0
    sub 48
    ; is number less than 10?
    cp 10
    jp nc, parse48le_done ; if greater than 10 then we're done
    ; multiply (ix) by 10
    call multen48le
    ; add the next digit
    ld (parse48le_tmp1), a
    call add48le
    ; loop
    inc hl
    jp parse48le_loop
parse48le_done:
    pop iy
    pop af
    ret
parse48le_tmp1:
    db 0,0,0,0,0,0

parses48le:
    push af
    ld a, (hl)
    cp 0x2D ; '-'
    jp nz, parses48le_positive
    inc hl
    call parse48le
    call inv48le
    pop af
    ret
parses48le_positive:
    call parse48le
    pop af
    ret

divmod48le_quotient:
    db 0,0,0,0,0,0
divmod48le_remainder:
    db 0,0,0,0,0,0
divmod48le_tmp:
    db 0,0,0,0,0,0
divmod48le:
    push ix
    push ix
    ld ix, dec48_zero
    call eq48le
    pop ix
    cp 1
    ret z ; TODO better way to handle div by zero?
    ; zero both the quotient and the remainder
    ld hl, divmod48le_quotient
    ld (hl), 0
    ld de, divmod48le_quotient+1
    ld bc, 11
    ldir
    ; make a copy of the numerator
    push ix
    pop hl
    ld de, divmod48le_tmp
    ld bc, 6
    ldir
    ld b, 48
divmod48le_loop:
    ld ix, divmod48le_quotient
    call dbl48le
    ld ix, divmod48le_tmp
    sla (ix)
    rl (ix+1)
    rl (ix+2)
    rl (ix+3)
    rl (ix+4)
    rl (ix+5)
    ld ix, divmod48le_remainder
    rl (ix)
    rl (ix+1)
    rl (ix+2)
    rl (ix+3)
    rl (ix+4)
    rl (ix+5)
    call gte48le
    cp 1
    jp nz, divmod48le_not_gte
    call sub48le
    ld ix, divmod48le_quotient
    set 0, (ix)
divmod48le_not_gte:
    djnz divmod48le_loop
    pop ix
    push ix
    pop de
    ld hl, divmod48le_quotient
    ld bc, 6
    ldir
    ret
