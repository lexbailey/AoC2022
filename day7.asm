    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 7"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0

root_ptr:
    dw 0,0

node_ptr:
    dw 0,0

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ld hl, tree
    ld (next_space), hl
    call new_node
    ld (root_ptr), hl
    ld bc, (root_ptr) ; bc points to the current node
    ld (node_ptr_stack), bc
    ld iy, node_ptr_stack ; iy points to the pointer to the top node on the stack
    ld hl, 0xa000
parse_loop:
    ld a, (hl)
    inc hl
    cp 0x24 ; if a == '$'
    jp nz, not_dollar
        inc hl
        ld a, (hl)
        inc hl
        inc hl
        inc hl
        cp 0x63 ; if a == 'c'
;        jp nz, not_c
        jp nz, parse_loop
            ld a, (hl)
            cp 0x2f ; if a == '/'
            jp nz, not_slash
                inc hl
                inc hl
                jp parse_loop
not_slash:
            cp 0x2e ; else if a == '.'
            jp nz, not_dot
                dec iy
                dec iy
                inc hl
                inc hl
                inc hl
                ld c, (iy)
                ld b, (iy+1)
                jp parse_loop
not_dot:
            ; not a / or a ., must be a normal dir
            inc iy
            inc iy
            push ix
            push bc
            push hl
            call new_node
            ld bc, hl
            ;ld b, h
            ;ld c, l
            ld ix, hl
            ld (iy), l
            ld (iy+1), h
            pop hl
            pop ix ; pops what was in bc
            ; ix points to old block
            ; bc points to new block
            push af
            inc ix
            inc ix
find_next_space:
            inc ix
            inc ix
            ld a, (ix+0)
            cp 0
            jp nz, find_next_space
            ld a, (ix+1)
            cp 0
            jp nz, find_next_space
            ld (ix), c
            ld (ix+1), b 

            pop af
            pop ix
skip_line_loop:
            ld a, (hl)
            inc hl
            cp 0x0a
            jp nz, skip_line_loop
            jp parse_loop
;not_c:
;        jp parse_loop
not_dollar:
    cp 0x64 ; if a == 'd'
    jp nz, not_d
        inc hl
        inc hl
        inc hl
skip_line_loop2:
        ld a, (hl)
        inc hl
        cp 0x0a
        jp nz, skip_line_loop2
        jp parse_loop
not_d:
        ; parse the number
        ld ix, tmp
        dec hl
        call parse32le
        push iy
        push ix
        ld ix, bc
        pop iy
        call add32le
        pop iy
skip_line_loop3:
        ld a, (hl)
        inc hl
        cp 0x0a
        jp nz, skip_line_loop3
        ld a, (hl)
        cp 0
        jp z, parse_done
        jp parse_loop

tmp:
    db 0,0,0,0
parse_done:


output:
    ld iy,(iy_cache)
    ld ix, result
    call p1_result   
end:
    jp end

next_space:
    dw 0

new_node:
    ld hl, (next_space)
    push hl
    push bc
    ld bc, 24 ; size of a node
    add hl, bc
    pop bc
    ld (next_space), hl
    pop hl
    ret

node_ptr_stack:
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; 20 item stack space for node pointers (probably enough)

tree:
    db 0 ; tree structure goes here

prog_end:
    savebin "day7.bin",prog_start,prog_end-prog_start
    labelslist "day7.labels"

