    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "wait.asm"
    include "print.asm"
    include "math.asm"
    include "math16.asm"
    include "intro.asm"

; 550 x 180

day:
    db "14"

iy_cache:
    db 0, 0



grid: equ 0xc800 ; Where the cost values are stored

gridx:
    db 0,0
gridy:
    db 0,0
grid_start:
    db 0,0,0,0
grid_line_step:
    db 0,0,0,0
grid_index:
    db 0,0,0,0
grid_bit:
    db 0,0

grid_max:
    db 0,0,0,0

sx:
    db 0,0
sy:
    db 0,0
cx:
    db 0,0
cy:
    db 0,0

done:
    db 0

maxx:
    db 0,0
maxy:
    db 0,0
width:
    db 0,0
height:
    db 0,0
miny_left:
    db 0,0,0,0
miny_right:
    db 0,0,0,0

startx:
    db 0,0
starty:
    db 0,0
stopx:
    db 0,0
stopy:
    db 0,0

tri_in:
    db 0,0,0,0
tri_out:
    db 0,0,0,0

tmp:
    db 0,0,0,0

result:
    db 0,0,0,0


parsed_input_ptr:
    db 0,0
parsed_input_end:
    db 0,0


calc_grid_index:
    push hl
    push de
    push bc
    push af
    push ix
    push iy
    ;grid_index = gridy
    ld de, grid_index
    ld hl, gridy
    ld bc, 2
    ldir
    ;grid_index *= grid_line_step
    ld ix, grid_index
    ld (ix+2), 0
    ld (ix+3), 0
    ld iy, grid_line_step
    call mul32le
    ;grid_index += grid_start
    ld iy, grid_start
    call add32le
    ;grid_index += gridx
    ld de, tmp
    ld hl, gridx
    ld bc, 2
    ldir
    ld iy, tmp
    ld (iy+2), 0
    ld (iy+3), 0
    call add32le
    ;grid_bit = grid_index
    ld de, grid_bit
    ld hl, grid_index
    ld bc, 2
    ldir
    ;grid_bit &= 7
    ld ix, grid_bit
    ld (ix+1), 0
    ld a, (ix)
    and 0x7
    ld (ix), a
    ;grid_index >>= 3
    ld ix, grid_index
    call sra32le
    call sra32le
    call sra32le
    pop iy
    pop ix
    pop af
    pop bc
    pop de
    pop hl
    ret


grid_get: ; result in a
    push hl
    push de
    push bc
    call calc_grid_index
    ld hl, grid
    ld de, (grid_index)
    add hl, de
    ld a, (hl)
    ld hl, grid_bit
    ld b, (hl)
    inc b
    jp shift_loop_end
shift_loop:
    srl a
shift_loop_end:
    djnz shift_loop
    and 1
    pop bc
    pop de
    pop hl
    ret

grid_set:
    push hl
    push de
    push bc
    call calc_grid_index
    ld hl, grid
    ld de, (grid_index)
    add hl, de
    push hl
    ld hl, grid_bit
    ld b, (hl)
    inc b
    ld a, 1
    jp shift_loop2_end
shift_loop2:
    sla a
shift_loop2_end:
    djnz shift_loop2
    pop hl
    or (hl)
    ld (hl), a
    pop bc
    pop de
    pop hl
    ret

zero:
    db 0,0,0,0
one:
    db 1,0,0,0
two:
    db 2,0,0,0

tri:
    push hl
    push de
    push bc
    ld hl, tri_in
    ld de, tri_out
    ld bc, 4
    ldir
    ld hl, tri_in
    ld de, tmp
    ld bc, 4
    ldir
    ld ix, tmp
    ld iy, one
    call add32le
    ld ix, tri_out
    ld iy, tmp
    call mul32le
    call sra32le
    pop bc
    pop de
    pop hl
    ret

drop_sand:
    push af
    push hl
    push de
    push bc
    push ix
    push iy
drop_loop:
    ld de, gridx
    ld hl, sx
    ld bc, 4
    ldir
    ld ix, gridy
    ld iy, one
    call add16le
    ld iy, height
    call gte16le
    cp 1
    jp z, drop_end_done
    call grid_get
    cp 1
    jp nz, drop_loop_continue
    ld ix, gridx
    ld iy, zero
    call eq16le
    cp 1
    jp z, drop_end_done
    ld iy, one
    call sub16le
    call grid_get
    cp 1
    jp nz, drop_loop_continue
    ld iy, two
    call add16le
    ld iy, width
    call gte16le
    cp 1
    jp z, drop_end_done
    call grid_get
    cp 1
    jp nz, drop_loop_continue
    jp drop_end ; final break
drop_loop_continue:
    ld de, sx
    ld hl, gridx
    ld bc, 4
    ldir
    jp drop_loop
drop_end_done:
    ld hl, done
    ld (hl), 1
drop_end:
    ld de, gridx
    ld hl, sx
    ld bc, 4
    ldir
    call grid_set
    pop iy
    pop ix
    pop bc
    pop de
    pop hl
    pop af
    ret

two_zeros:
    db 0,0,0,0

init_grid:
    ; First pass is just to determine the extents of the grid
    ld de, parsed_input
    ld (parsed_input_ptr), de
    ld hl, 0x9000
init_loop_first_pass:
    ld a, (hl)
    cp 0
    jp z, init_loop_first_pass_complete

    ld ix, sx
    call parse16le
    inc hl
    ld ix, sy
    call parse16le

    push hl

    ld hl, sx
    ld de, (parsed_input_ptr)
    ld bc, 4
    ldir
    ld (parsed_input_ptr), de

    ld ix, sx
    ld iy, maxx
    call gt16le
    cp 1
    jp nz, sx_not_gt_maxx
    ld hl, sx
    ld de, maxx
    ld bc, 2
    ldir
sx_not_gt_maxx:
    ld ix, sy
    ld iy, maxy
    call gt16le
    cp 1
    jp nz, sy_not_gt_maxy
    ld hl, sy
    ld de, maxy
    ld bc, 2
    ldir
sy_not_gt_maxy:
    pop hl
    ld a, (hl)
    cp ' '
    jp nz, not_space:
    ld bc, 4
    add hl, bc
    jp init_loop_first_pass
not_space:
    inc hl

    ; coords 0,0 indicate end of line
    push hl
    ld hl, two_zeros
    ld de, (parsed_input_ptr)
    ld bc, 4
    ldir
    ld (parsed_input_ptr), de
    pop hl

    jp init_loop_first_pass
init_loop_first_pass_complete:
    ld de, (parsed_input_ptr)
    ld (parsed_input_end), de
    ; record the grid size info
    ld hl, one
    ld de, grid_start
    ld bc, 2
    ldir
    
    ld hl, maxx
    ld de, width
    ld bc, 4
    ldir
    ld iy, one
    ld ix, width
    call add16le
    ld ix, height
    call add16le
    ld hl, width
    ld de, grid_line_step
    ld bc, 2
    ldir
    ld ix, grid_line_step
    ld iy, two
    call add16le
    ld hl, height
    ld de, miny_left
    ld bc, 2
    ldir
    ld ix, miny_left
    ld iy, one
    call sub16le
    ld hl, miny_left
    ld de, miny_right
    ld bc, 2
    ldir

    ld hl, height
    ld de, grid_max
    ld bc, 2
    ldir
    ld ix, grid_max
    ld iy, one
    call add16le
    ld iy, grid_line_step
    call mul32le
    call sra32le
    call sra32le
    call sra32le
    ld iy, one
    call add16le

    ; blank the grid (it uses space where the input text was)
    ld hl, 0xc800
    ld (hl), 0
    ld de, 0xc801
    ld bc, (grid_max)
    ldir

    ; Now it's time for the second pass over the input text, to initialise the grid
    ld de, parsed_input
    ld (parsed_input_ptr), de
init_loop_second_pass:
    ld ix, parsed_input_ptr
    ld iy, parsed_input_end
    call eq16le
    cp 1
    jp z, init_loop_second_pass_complete

    ld de, cx
    ld hl, (parsed_input_ptr)
    ld bc, 4
    ldir
    ld (parsed_input_ptr), hl
init_inner_loop_second_pass:

    ld de, sx
    ld hl, (parsed_input_ptr)
    ld bc, 4
    ldir
    ld (parsed_input_ptr), hl


    ld ix, sx
    ld iy, zero
    call eq16le
    cp 1
    jp z, init_loop_second_pass

    ld hl, cx
    ld de, startx
    ld bc, 2
    ldir
    ld hl, sx
    ld de, stopx
    ld bc, 2
    ldir
    ld ix, startx
    ld iy, sx
    call gt16le
    cp 1
    jp nz, not_startx_gt_sx
    ld hl, sx
    ld de, startx
    ld bc, 2
    ldir
    ld hl, cx
    ld de, stopx
    ld bc, 2
    ldir
not_startx_gt_sx:
    ld ix, stopx
    ld iy, one
    call add16le
    ; for gridx in range(startx, stopx):
    ld de, gridx
    ld hl, startx
    ld bc, 2
    ldir
init_x_loop:
        ld de, starty
        ld hl, cy
        ld bc, 2
        ldir
        ld de, stopy
        ld hl, sy
        ld bc, 2
        ldir
        ld ix, starty
        ld iy, sy
        call gt16le
        cp 1
        jp nz, not_sy_gt_starty
            ld de, starty
            ld hl, sy
            ld bc, 2
            ldir
            ld de, stopy
            ld hl, cy
            ld bc, 2
            ldir
not_sy_gt_starty:
        ld ix, stopy
        ld iy, one
        call add16le
        ; for gridy in range(startx, stopx):
            ld de, gridy
            ld hl, starty
            ld bc, 2
            ldir
            ld ix, gridy
            ld iy, one
init_y_loop:
            call grid_set
            ld iy, one
            call add16le
            ld iy, stopy
            call eq16le
            cp 1
            jp nz, init_y_loop
    ld ix, gridx
    ld iy, one
    call add16le
    ld iy, stopx
    call eq16le
    cp 1
    jp nz, init_x_loop

    ld hl, sx
    ld de, cx
    ld bc, 4
    ldir

    jp init_inner_loop_second_pass
init_loop_second_pass_complete:
    ret

p1_start_xy:
    dw 500
    dw 0

p2_start_xy:
    dw 501
    dw 0

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    call init_grid
    ld ix, result
    ld (ix), 0
    ld (ix+1), 0
    ld hl, done
    ld (hl), 0
    ld ix, result
    ld iy, one
part1_loop:
    ld hl, done
    ld a, (hl)
    cp 0
    jp nz, part1_done
    ld hl, p1_start_xy
    ld de, sx
    ld bc, 4
    ldir
    call drop_sand
    call add32le
    jp part1_loop
part1_done:
    call sub16le
    ld iy,(iy_cache)
    call p1_result
    call intro_p2
    ld ix, width
    ld iy, two
    call add16le
    ld ix, height
    ld iy, one
    call add16le
    ld ix, grid_start
    ld (ix), 0
    ld (ix+1), 0
    ld de, grid_line_step
    ld hl, width
    ld bc, 2
    ldir
part2_loop:
    ld hl, p2_start_xy
    ld de, sx
    ld bc, 4
    ldir
    call drop_sand
    ld ix, sx
    ld iy, zero
    call eq16le
    cp 1
    jp nz, no_new_miny_left
    ld de, miny_left
    ld hl, sy
    ld bc, 2
    ldir
no_new_miny_left:
    ld de, tmp
    ld hl, width
    ld bc, 2
    ldir
    ld ix, tmp
    ld iy, one
    call sub16le
    ld iy, sx
    call eq16le
    cp 1
    jp nz, no_new_miny_right
    ld de, miny_right
    ld hl, sy
    ld bc, 2
    ldir
no_new_miny_right:
    ld ix, result
    ld iy, one
    call add32le
    ld ix, sx
    ld iy, p2_start_xy
    call eq16le
    cp 1
    jp nz, part2_loop
    ld ix, sy
    ld iy, p2_start_xy+2
    call eq16le
    cp 1
    jp nz, part2_loop
    ; loop ends

    ld de, tri_in
    ld hl, height
    ld bc, 2
    ld ix, tri_in
    ld (ix+2), 0
    ld (ix+3), 0
    ldir
    ld ix, tri_in
    ld iy, one
    call sub32le
    ld iy, miny_left
    call sub32le
    call tri
    ld ix, result
    ld iy, tri_out
    call add32le
    ld ix, tri_in
    ld iy, miny_left
    call add32le
    ld iy, miny_right
    call sub32le
    call tri
    ld ix, result
    ld iy, tri_out
    call add32le
    ld iy, (iy_cache)
    call p2_result

    call large_delay
end:
    jp end

parsed_input:
    db 0 ; parsed input text goes here, so that before the grid is initialised, the input text is gone already

prog_end:
    savebin "day14.bin",prog_start,prog_end-prog_start
    labelslist "day14.labels"

