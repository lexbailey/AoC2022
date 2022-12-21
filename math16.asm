add16le: ; (ix) = (ix) + (iy)
    push af
    ld a,(ix)
    add a,(iy)
    ld (ix), a
    ld a, (ix+1)
    adc a,(iy+1)
    ld (ix+1), a
    pop af
    ret

one16le:
    db 1, 0

inv16le: ; (ix) = -(ix)
    push af
    ld a, (ix)
    cpl
    ld (ix), a
    ld a, (ix+1)
    cpl
    ld (ix+1), a
    pop af
    push iy
    ld iy, one16le
    call add16le
    pop iy
    ret

sub16le: ; (ix) = (ix) - (iy)
    push ix
    push iy
    pop ix
    call inv16le
    pop ix
    call add16le
    push ix
    push iy
    pop ix
    call inv16le
    pop ix
    ret

sra16le: ; (ix) = (ix)>>1
    sra (ix+1)
    rr (ix)
    ret

sra16le_iy: ; (iy) = (iy)>>1
    sra (iy+1)
    rr (iy)
    ret

dbl16le: ; (ix) = (ix) << 1
    sla (ix)
    rl (ix+1)
    ret

dbl16le_iy: ; (iy) = (iy) << 1
    sla (iy)
    rl (iy+1)
    ret

mul16le: ; (ix) = (ix) * (iy)
    push bc
    push de
    push hl
    push iy
    ; Copy (ix) to (tmp2)
    ld bc, 2
    push ix
    pop hl
    ld de, mul16le_tmp2
    ldir
    ; Copy (iy) to (tmp1)
    ld bc, 2
    push iy
    pop hl
    ld de, mul16le_tmp1
    ldir
    ; set (ix) to 0
    ld (ix+0), 0
    ld (ix+1), 0
    ; 16 step multiply loop
    ld b, 16
mul16le_loop:
    ld iy, mul16le_tmp1 ; 20
    call sra16le_iy 
    ld iy, mul16le_tmp2 ; 20
    call c, add16le
    call dbl16le_iy
    djnz mul16le_loop
    pop iy
    pop hl
    pop de
    pop bc
    ret
mul16le_tmp1:
    db 0,0
mul16le_tmp2:
    db 0,0


eq16le: ; a = (ix) == (iy)
    push bc
    ld a, (ix+0)
    ld c, (iy+0)
    cp c
    jp nz, eq16le_noteq
    ld a, (ix+1)
    ld c, (iy+1)
    cp c
    jp nz, eq16le_noteq
    pop bc
    ld a, 1
    ret
eq16le_noteq:
    pop bc
    ld a, 0
    ret

gt16le: ; a = (ix) > (iy)
    push bc
    ld a, (iy+1)
    ld c, (ix+1)
    cp c
    jp c, gt16le_gt
    jp nz, gt16le_ngt

    ld a, (iy)
    ld c, (ix)
    cp c
    jp c, gt16le_gt
gt16le_ngt:
    pop bc
    ld a, 0
    ret
gt16le_gt:
    pop bc
    ld a, 1
    ret

gte16le:
    call gt16le
    cp 1
    ret z
    jp eq16le ; tail call


; Optimised multiply by 10
; (ix) = (ix) * 10
; decomposes 10 into sum of powers of two
; x * 10 === (x * 2) + (x * 8) === dbl(x) + dbl(dbl(dbl(x)))
; three doubles plus an add
multen16le:
    push bc
    push de
    push hl
    push iy
    ; (ix) = (ix) * 2
    call dbl16le
    ; (tmp1) = (ix)
    ld bc, 2
    push ix
    pop hl
    ld de, multen16le_tmp1
    ldir
    ; (ix) = (ix) * 2
    call dbl16le
    ; (ix) = (ix) * 2
    call dbl16le
    ; (ix) = (ix) + (tmp1)
    ld iy, multen16le_tmp1
    call add16le
    pop iy
    pop hl
    pop de
    pop bc
    ret
multen16le_tmp1:
    db 0,0

parse16le: ; takes a buffer (hl) and consumes digits until a non-digit is reached, leaves hl at the end of the parsed number, stores number at (ix)
    ; this function works by multiplying by 10 and adding the next char as unit value until it finds an unrecognised char
    push af
    push iy
    ; (ix) = 0
    ld (ix), 0
    ld (ix+1), 0
    ld iy, parse16le_tmp1
parse16le_loop:
    ; get next char
    ld a, (hl)
    ; ascii zero to number 0
    sub 48
    ; is number less than 10?
    cp 10
    jp nc, parse16le_done ; if greater than 10 then we're done
    ; multiply (ix) by 10
    call multen16le
    ; add the next digit
    ld (parse16le_tmp1), a
    call add16le
    ; loop
    inc hl
    jp parse16le_loop
parse16le_done:
    pop iy
    pop af
    ret
parse16le_tmp1:
    db 0,0
