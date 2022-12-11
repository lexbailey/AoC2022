    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 8"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0

width:
    db 0,0,0,0
height:
    db 0,0,0,0

flag:
    db 0
tot_trees:
    db 0,0,0,0
prod:
    db 0,0,0,0

max_prod:
    db 0,0,0,0


cur_tree:
    db 0
cur_x:
    db 0,0,0,0
cur_y:
    db 0,0,0,0
dx:
    db 0,0,0,0
dy:
    db 0,0,0,0

tx:
    db 0,0,0,0
ty:
    db 0,0,0,0

ptr:
    db 0,0,0,0

get_tree: ; looks up cur_x, cur_y in the input file
    push ix
    push iy
    push hl
    push bc
    ld ix, ptr
    ld (ix), 1
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld iy, width
    call add32le
    ld iy, cur_y
    call mul32le
    ld iy, cur_x
    call add32le
    ld hl, 0xa000
    ld bc, (ix)
    add hl, bc
    ld a, (hl)
    pop bc
    pop hl
    pop iy
    pop ix
    ret

line_count:
    db 0, 0, 0, 0
check_line: ; iterates along a line checking the height of the trees as it goes
    push af
    push ix
    push iy
    push bc
    push de
    ld ix, line_count
    ld (ix), 0
    call get_tree ; get the tree for _this_ location
    ld e, a
check_line_loop:
    ; check if we hit the edge of the forrest
        ; x == 0?
        ld a, (cur_x)
        cp 0
        jp z, line_end_reached
        ; y == 0?
        ld a, (cur_y)
        cp 0
        jp z, line_end_reached
        ; x == width - 1
        ld a, (width)
        dec a
        ld b, a
        ld a, (cur_x)
        cp b
        jp z, line_end_reached
        ; y == height - 1
        ld a, (height)
        dec a
        ld b, a
        ld a, (cur_y)
        cp b
        jp z, line_end_reached


    ; line_count += 1
    ld ix, line_count
    inc (ix)

    ; add dx to cur_x
    ld a, (cur_x)
    ld b, a
    ld a, (dx)
    add a, b
    ld (cur_x), a

    ; add dy to cur_y
    ld a, (cur_y)
    ld b, a
    ld a, (dy)
    add a, b
    ld (cur_y), a


    ; lookup this tree and see if its bigger
    call get_tree
    cp e
    jp nc, bigger_tree_hit

    jp check_line_loop
line_end_reached:
    ld a, 1
    ld (flag), a
bigger_tree_hit:
    ld ix, prod
    ld iy, line_count
    call mul32le
    pop de
    pop bc
    pop iy
    pop ix
    pop af
    ret

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
    call intro_p2
compute:
    ; first get size of input grid (assume it fits in 0-255)
    ld hl, 0xa000
    ld a, (hl)
    ld c, 0
width_loop:
    inc c
    inc hl
    ld a, (hl)
    cp 10 ; newline
    jp nz, width_loop
    ld ix, width
    ld (ix), c
    ld b, 0
    ld d, 1 ; already skipped past the first line while counting the width
    inc hl
height_loop:
    add hl, bc
    inc d
    inc hl
    ld a, (hl)
    cp 0 ; null
    jp nz, height_loop
    ld ix, height
    ld (ix), d
    ; width and height are now known
    jp iterate_trees

stash_xy:
    ld a, (cur_x)
    ld (tx), a
    ld a, (cur_y)
    ld (ty), a
    ret

unstash_xy:
    ld a, (tx)
    ld (cur_x), a
    ld a, (ty)
    ld (cur_y), a
    ret

dir1:
    ld a, 1
    ld (dx), a
    ld a, 0
    ld (dy), a
    ret
dir2:
    ld a, -1
    ld (dx), a
    ld a, 0
    ld (dy), a
    ret
dir3:
    ld a, 0
    ld (dx), a
    ld a, 1
    ld (dy), a
    ret
dir4:
    ld a, 0
    ld (dx), a
    ld a, -1
    ld (dy), a
    ret
    


iterate_trees:
    ld hl, height
    ld a, (hl)
    dec a
    ld (cur_y), a
    ld b, a
    inc b
outer_loop:
    push bc
    ld hl, width
    ld a, (hl)
    dec a
    ld (cur_x), a
    ld b, a
    inc b
inner_loop:
    push bc
    ; prod = 1
    ld a, 1
    ld (prod), a
    ; flag = 0
    ld a, 0
    ld (flag), a
    call stash_xy
       
    ; four different directions to search
    call dir1
    call check_line
    call unstash_xy
    
    call dir2
    call check_line
    call unstash_xy
    
    call dir3
    call check_line
    call unstash_xy
   
    call dir4
    call check_line
    call unstash_xy

    ld a, (flag)
    cp 1
    jp nz, no_flag
    ld ix, tot_trees
    ld iy, dec_one
    call add32le
no_flag:
    ld ix, prod
    ld iy, max_prod
    call gt32le
    cp 1
    jp nz, notbigger
    ld de, max_prod
    ld hl, prod
    ld bc, 4
    ldir
notbigger:
    pop bc
    ld hl, cur_x
    dec (hl)
    djnz inner_loop
    pop bc
    ld hl, cur_y
    dec (hl)
    djnz outer_loop
output:
    ld iy,(iy_cache)
    ld ix, tot_trees
    call p1_result   
    ld ix, max_prod
    call p2_result   
end:
    jp end

prog_end:
    savebin "day8.bin",prog_start,prog_end-prog_start
    labelslist "day8.labels"

