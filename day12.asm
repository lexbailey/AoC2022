    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "wait.asm"
    include "print.asm"
    include "math.asm"
    include "math16.asm"
    include "intro.asm"

day:
    db "12"

iy_cache:
    db 0, 0


x:
    db 0,0
y:
    db 0,0
sx:
    db 0,0
sy:
    db 0,0

tx:
    db 0,0
ty:
    db 0,0

from:
    db 0
width:
    db 0,0
height:
    db 0,0

grid_size:
    db 0,0

max_cost:
    db 0,0,0,0

cost_from:
    db 0,0,0,0
cost_to:
    db 0,0,0,0

prev_cost:
    db 0,0

moves_read_ptr:
    db 0,0
moves_write_ptr:
    db 0,0
max_moves: 
    db 0,0

tmp:
    db 0,0

init_moves_fifo:
    push hl
    push de
    ld hl, moves_start
    ld (moves_read_ptr), hl
    ld (moves_write_ptr), hl
    ld de, 1600
    add hl, de
    ld (max_moves), hl
    pop de
    pop hl
    ret

add_move:
    push hl
    push bc
    push de
    ld de, (moves_write_ptr)
    ld hl, x
    ld bc, 8
    ldir
    ld (moves_write_ptr), de

    ld ix, moves_write_ptr
    ld iy, max_moves
    call eq16le
    cp 1
    jp nz, no_reset_add
    ; loop to start of ring buffer
    ld hl, moves_write_ptr
    ld (hl), (moves_start & 0xff)
    inc hl
    ld (hl), ((moves_start >> 8) & 0xff)
no_reset_add:
    pop de
    pop bc
    pop hl
    ret

next_move:
    push hl
    push bc
    push de

    ld ix, moves_read_ptr
    ld iy, moves_write_ptr
    call eq16le
    cp 1
    jp nz, no_collision
    jp end
no_collision:

    ld hl, (moves_read_ptr)
    ld de, x
    ld bc, 8
    ldir
    ld (moves_read_ptr), hl

    ld ix, moves_read_ptr
    ld iy, max_moves
    call eq16le
    cp 1
    jp nz, no_reset_next
    ; loop to start of ring buffer
    ld hl, moves_read_ptr
    ld (hl), (moves_start & 0xff)
    inc hl
    ld (hl), ((moves_start >> 8) & 0xff)
no_reset_next:
    pop de
    pop bc
    pop hl
    ret

get_size:
    push af
    push hl
    push ix
    push de
    ld hl, 0xa000
    ld ix, width
width_loop:
    ld a, (hl)
    inc hl
    cp 0x0a
    jp z, width_done
    inc (ix)
    jp width_loop
width_done:
    ld d, 0
    ld e, (ix)
    inc hl
    ld ix, height
    inc (ix)
height_loop:
    add hl, de
    ld a, (hl)
    cp 0
    jp z, height_done
    inc (ix)
    jp height_loop
height_done:
    ; now calculate the highest possible cost value
    ld de, max_cost
    ld hl, width
    ld bc, 2
    ldir
    ld ix, max_cost
    ld iy, height
    call mul16le
    pop de
    pop ix
    pop hl
    pop af
    ret

find_end:
    push af
    push iy
    push ix
    push hl
    ld iy, y
    ld ix, x
    ld (iy), 0
    ld (ix), 0
    ld hl, 0xa000
find_loop:
    ld a, (hl)
    cp 0x0a ; newline
    jp nz, nonewline
    inc (iy)
    ld (ix), 0
nonewline:
    cp 'E'
    jp z, found_end
    inc hl
    inc (ix)
    jp find_loop
found_end:
    dec (ix)
    pop hl
    pop ix
    pop iy
    pop af
    ret

init_cost_grid:
    push hl
    push de
    push bc
    ld hl, max_cost
    ld de, cost_grid
    ld bc, 2
    ldir
    ld hl, height
    ld de, grid_size
    ld bc, 2
    ldir
    ld ix, grid_size
    ld iy, width
    call mul16le
    call dbl16le
    ld c, (ix)
    ld b, (ix+1)
    ld hl, cost_grid
    ld de, cost_grid + 2
    ldir ; this will go one step too far, but that's fine, there's spare space anyway
    pop bc
    pop de
    pop hl
    ret

one:
    db 1,0

    nop
get_t_grid_char:
    push hl
    push de
    push bc
    ld de, tmp
    ld hl, width
    ld bc, 2
    ldir
    ld ix, tmp
    ld iy, one
    call add16le
    ld iy, ty
    call mul16le
    ld iy, tx
    call add16le
    ld de, (tmp)
    ld hl, 0xa000
    add hl, de
    ld a, (hl)
    pop bc
    pop de
    pop hl
    ret

get_cur_grid_char:
    push hl
    push de
    push bc
    ld de, tmp
    ld hl, width
    ld bc, 2
    ldir
    ld ix, tmp
    ld iy, one
    call add16le
    ld iy, y
    call mul16le
    ld iy, x
    call add16le
    ld de, (tmp)
    ld hl, 0xa000
    add hl, de
    ld a, (hl)
    pop bc
    pop de
    pop hl
    ret

set_cur_grid_char:
    push hl
    push de
    push bc
    ld de, tmp
    ld hl, width
    ld bc, 2
    ldir
    ld ix, tmp
    ld iy, one
    call add16le
    ld iy, y
    call mul16le
    ld iy, x
    call add16le
    ld de, (tmp)
    ld hl, 0xa000
    add hl, de
    ld (hl), a
    pop bc
    pop de
    pop hl
    ret

check_move:
    push af
    push hl
    push bc

    ld hl, tx+1
    ld a, (hl)
    and 0x80
    jp nz, invalid_move

    ld hl, ty+1
    ld a, (hl)
    and 0x80
    jp nz, invalid_move

    ld ix, tx
    ld iy, width
    call gte16le
    cp 1
    jp z, invalid_move

    ld ix, ty
    ld iy, height
    call gte16le
    cp 1
    jp z, invalid_move

    call get_t_grid_char
    cp 'S'
    jp nz, not_s
    ld a, 'a'
not_s:
    inc a
    ld hl, from
    ld b, (hl)
    cp b
    jp c, invalid_move
    call add_move
invalid_move:
    pop bc
    pop hl
    pop af
    ret

two:
    db 2,0

get_valid_moves:
    push af
    push hl
    push de
    push bc
    push ix
    push iy
    call get_cur_grid_char
    cp 'E'
    jp nz, not_e
    ld a, 'z'
not_e:
    ld hl, from
    ld (hl), a

    ld ix, sx
    ld (ix), 0
    ld (ix+1), 0
    ld ix, sy
    ld (ix), 1
    ld (ix+1), 0

    ld hl, x
    ld de, tx
    ld bc, 2
    ldir

    ld hl, y
    ld de, ty
    ld bc, 2
    ldir

    ld ix, ty
    ld iy, sy
    call add16le

    call check_move

    ld ix, sy
    ld (ix), 0xff
    ld (ix+1), 0xff
    
    ld ix, ty
    ld iy, two
    call sub16le

    call check_move

    ld ix, sy
    ld (ix), 0
    ld (ix+1), 0
    ld ix, sx
    ld (ix), 1
    ld (ix+1), 0
    
    ld hl, x
    ld de, tx
    ld bc, 2
    ldir
    ld hl, y
    ld de, ty
    ld bc, 2
    ldir

    ld ix, tx
    ld iy, sx
    call add16le

    call check_move
    
    ld ix, sx
    ld (ix), 0xff
    ld (ix+1), 0xff
    ld ix, tx
    ld iy, two
    call sub16le
    call check_move

    pop iy
    pop ix
    pop bc
    pop de
    pop hl
    pop af
    ret ; This just yeets us off into the wild



cost_grid_cur_addr_calc:
    push bc
    push de
    push ix
    push iy
    ld de, tmp
    ld hl, y
    ld bc, 2
    ldir

    ld ix, tmp
    ld iy, width
    call mul16le
    ld iy, x
    call add16le
    call dbl16le

    ld hl, cost_grid
    ld de, (tmp)
    add hl, de
    pop iy
    pop ix
    pop de
    pop bc
    ret

cost_grid_t_addr_calc:
    push bc
    push de
    push ix
    push iy
    ld de, tmp
    ld hl, ty
    ld bc, 2
    ldir

    ld ix, tmp
    ld iy, width
    call mul16le
    ld iy, tx
    call add16le
    call dbl16le

    ld hl, cost_grid
    ld de, (tmp)
    add hl, de
    pop iy
    pop ix
    pop de
    pop bc
    ret
    

search:
    call cost_grid_cur_addr_calc
    ld (hl), 0
    inc hl
    ld (hl), 0
    call get_valid_moves
search_loop:
    call next_move
    ; copy x,y into tx,ty
    ld hl, x
    ld de, tx
    ld bc, 4
    ldir
    ; add step values
    ld ix, tx
    ld iy, sx
    call add16le
    ld ix, ty
    ld iy, sy
    call add16le
    call cost_grid_cur_addr_calc
    ld de, cost_from
    ld bc, 2
    ldir

    ld de, cost_to
    ld hl, cost_from
    ld bc, 2
    ldir
    ld ix, cost_to
    ld iy, one
    call add16le

    call get_t_grid_char
    cp 'a'
    jp nz, no_new_max_cost
    ld ix, max_cost
    ld iy, cost_to
    call gt16le
    cp 1
    jp nz, no_new_max_cost
    ld de, max_cost
    ld hl, cost_to
    ld bc, 2
    ldir
no_new_max_cost:
    cp 'S'
    jp z, search_complete

    call cost_grid_t_addr_calc
    ld de, prev_cost
    ld bc, 2
    ldir

    ld ix, prev_cost
    ld iy, cost_to
    call gt16le
    cp 1
    jp nz, search_loop
    call cost_grid_t_addr_calc
    ld de, hl
    ld hl, cost_to
    ld bc, 2
    ldir
    ld a, '~'
    call set_cur_grid_char
    ld de, x
    ld hl, tx
    ld bc, 4
    ldir
    call get_valid_moves
    jp search_loop

search_complete:
    ret

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
    call intro_p2
compute:
    call init_moves_fifo
    call get_size
    call find_end
    call init_cost_grid
    call search
output:
    ld iy,(iy_cache)
    ld ix, cost_to
    call p1_result   
    ld ix, max_cost
    call p2_result   
    call large_delay
end:
    jp end

moves_start:
    db 0
cost_grid: equ 0xc800 ; Where the cost values are stored

prog_end:
    savebin "day12.bin",prog_start,prog_end-prog_start
    labelslist "day12.labels"


; 515
; 502
