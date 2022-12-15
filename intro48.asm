
p1_text:
    db AT, 0, 0, INK, 8, "AoC2022 Day "
daynum:
    db "__", AT, 1, 0, "Part1...", AT, 2, 0, "    Working..."
p1_text_len: equ $ - p1_text
intro_p1:
    push af
    push de
    push bc
    ld a, (hl)
    ld (daynum), a
    inc hl
    ld a, (hl)
    dec hl
    ld (daynum+1), a
    ld de, p1_text
    ld bc, p1_text_len
    call ROM_PRINT
    pop bc
    pop de
    pop af
    ret

p1_result_text:
    db AT
y_coord: db 2, 0, "    "
p1_result_buffer: db "               "
p1_result_text_len: equ $ - p1_result_text
p1_result:
    push de
    push bc
    push iy
    ld iy, p1_result_buffer
    call str48le
    ld de, p1_result_text
    ld bc, p1_result_text_len
    pop iy
    call ROM_PRINT
    pop bc
    pop de
    ret

p2_text:
    db AT, 3, 0, "Part2...", AT, 4, 0, "    Working..."
p2_text_len: equ $ - p2_text
intro_p2:
    push de
    push bc
    ld de, p2_text
    ld bc, p2_text_len
    call ROM_PRINT
    pop bc
    pop de
    ret

    
p2_result:
    push af
    ld a, 4
    ld (y_coord), a
    call p1_result
    ld a, 2
    ld (y_coord), a
    pop af
    ret
