
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

sra32le: ; (ix) = (ix)>>1, clobbers a and leaves the carry flag with the previous lsb
    ld a,(ix+3)
    sra a
    ld (ix+3),a
    ld a,(ix+2)
    rr a
    ld (ix+2),a
    ld a,(ix+1)
    rr a
    ld (ix+1),a
    ld a,(ix+0)
    rr a
    ld (ix+0),a
    ret

dbl32le: ; (ix) = (ix) + (ix)
    push iy
    push ix
    pop iy
    call add32le
    pop iy
    ret

mul32le: ; (ix) = (ix) * (iy)
    ; Copy (ix) to (tmp1)
    push bc
    push de
    push hl
    push iy
    ld bc, 4
    push ix
    pop hl
    ld de, mul32le_tmp1
    ldir
    ; Copy (iy) to (tmp2)
    ld bc, 4
    push iy
    pop hl
    ld de, mul32le_tmp2
    ldir
    ; set (ix) to 0
    ld (ix+0), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ; 32 step multiply loop
    ld b, 32
    ld iy, mul32le_tmp2
mul32le_loop:
    push ix
    ld ix, mul32le_tmp1
    call sra32le
    pop ix
    call c, add32le
    push ix
    push iy
    pop ix
    call dbl32le
    pop ix
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
    db 0x0a, 0x00, 0x00, 0x00
dec_last:
    db 0x01, 0x00, 0x00, 0x00

; x.xxx.xxx.xxx

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
str32le_space_pad_loop:
    cp (hl)
    jp nz, str32le_done
    ld (hl), 32
    inc hl
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
