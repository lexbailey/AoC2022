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

