
large_delay:
    push hl
    push bc
    ld hl, 0
    ld bc, 1
large_delay_loop:
    add hl, bc
    jp c, large_delay_done
    jp large_delay_loop
large_delay_done:
    pop bc
    pop hl
    ret
