
big_loop: ; iy should contain the max value, ix should point to a counter variable, hl should contain a pointer to a function to be a loop body
    ld (big_loop_dest), hl
    ;init the counter
    ld (ix), 0
    ld (ix+0), 0
    ld (ix+1), 0
    ld (ix+2), 0
    push hl
big_loop_start:
    db 0xCD
big_loop_dest:
    db 0,0
    pop hl
    push iy
    ld iy, dec_one
    call add32le
    pop iy
    call eq32le
    cp 1
    ret z
    ld (big_loop_dest), hl
    push hl
    jp big_loop_start
