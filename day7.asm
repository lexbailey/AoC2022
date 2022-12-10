    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "wait.asm"
    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 7"

iy_cache:
    db 0, 0

result1:
    db 0,0,0,0
result2:
    db 0x80, 0x1d, 0x2c, 0x04 ; initially 70000000
to_free:
    db 0,0,0,0
space:
    db 0x00, 0x5a, 0x62, 0x02 ; subtracted from used space to find out how much to free

root_ptr:
    dw 0,0

node_ptr:
    dw 0,0

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
    call intro_p2
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
    ; tree structure has been built, now reduce the tree recursively
    ld hl, tree ; pointer to root of tree
    call reduce_tree
    jp calculate_results
    

reduce_tree:
    ; hl points to the current node
    push af
    push bc
    push hl
    push ix
    ld ix, hl
    inc hl
    inc hl
    inc hl
    inc hl
    ; hl now points to the first child pointer
reduce_children:
    ; first reduce the child node if it exists
    ld a, 0
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    cp c
    jp nz, reduce_child
    cp b
    jp nz, reduce_child
    jp children_done
reduce_child:
    push hl
    ld hl, bc
    call reduce_tree
    ; child has been reduced, now we can add its value to this node
    ld iy, bc
    call add32le
    pop hl
    jp reduce_children
children_done:
    pop ix
    pop hl
    pop bc
    pop af
    ret

calculate_results:
    ; nodes are now reduced, time to calculate the result values
    ; Copy the root value to to_free
    ld hl, tree ; first node
    ld de, to_free
    ld bc, 4
    ldir
    ; subtract the space value
    ld ix, to_free
    ld iy, space
    call sub32le
    ; to_free is now correc6t
    ld bc, 24 ; size of a node
    ld hl, tree ; first node
iter_nodes:
    call do_node
    add hl, bc
    ld ix, hl
    ld iy, dec_zero
    call eq32le
    cp 1
    jp nz, iter_nodes
    jp output

threshold:
    db 0xa0, 0x86, 0x01, 0x00 ; 100000

do_node:
    ; hl points to a node to do computation on
    push hl
    push ix
    push iy
    push bc
    ld ix, hl
    ld iy, threshold
    call gt32le
    cp 1
    jp z, p1done_node
    ld ix, result1
    ld iy, hl
    call add32le
p1done_node:
    ld ix, hl
    ld iy, result2
    call gte32le
    cp 1
    jp z, p2done_node
    ld iy, to_free
    call gte32le
    cp 1
    jp nz, p2done_node
    ld de, result2
    ld bc, 4
    ldir
p2done_node:
    pop bc
    pop iy
    pop ix
    pop hl
    ret

output:
    ld iy,(iy_cache)
    ld ix, result1
    call p1_result   
    ld ix, result2
    call p2_result   
    call large_delay
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
    push hl
    push bc
    ld b, 24
blank_node:
    ld (hl), 0
    inc hl
    djnz blank_node
    pop bc
    pop hl
    ret

node_ptr_stack:
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; 20 item stack space for node pointers (probably enough)

tree:
    db 0 ; tree structure goes here

prog_end:
    savebin "day7.bin",prog_start,prog_end-prog_start
    labelslist "day7.labels"

