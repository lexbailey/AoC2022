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
    db " 9"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0

bitmap_start: equ 0xc800
bwidth: equ 336 ; must by multiple of 8
bheight: equ 336 ; can be any integer

line_step: equ bwidth/8

bitmap_size: equ line_step * bheight


clear_bitmap:
    push hl
    push de
    push bc
    ld hl, bitmap_start
    ld (hl), 0
    ld de, bitmap_start+1
    ld bc, bitmap_size-1
    ldir
    pop bc
    pop de
    pop hl
    ret

popcount_lut:
    db 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2
    db 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2, 2, 3, 2, 3
    db 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3
    db 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4
    db 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5
    db 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4
    db 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5
    db 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8

popcount:
    push hl
    push bc
    ld hl, popcount_lut
    ld c, a
    ld b, 0
    add hl, bc
    ld a, (hl)
    pop bc
    pop hl
    ret

step_lut:
    db 255,255, 255,255
    db 255,255, 255,255
    db 255,255,  0,0
    db 255,255,  1,0
    db 255,255,  1,0
    db 255,255, 255,255
    db  0,0, 0,0
    db  0,0, 0,0
    db  0,0, 0,0
    db 255,255,  1,0
    db  0,0, 255,255
    db  0,0,  0,0
    db  0,0,  0,0
    db  0,0,  0,0
    db  0,0,  1,0
    db  1,0, 255,255
    db  0,0,  0,0
    db  0,0,  0,0
    db  0,0,  0,0
    db  1,0,  1,0
    db  1,0, 255,255
    db  1,0, 255,255
    db  1,0,  0,0
    db  1,0,  1,0
    db  1,0,  1,0 

twelve:
    db 12, 0

step_lookup:
    push ix
    push iy
    push de
    push bc
    push af

    ; lookup value in the lut
    ; expression for offset into table is (x * 5) + y + 12


    ld ix, tmp
    ld iy, sx
    ld a, (iy)
    ld (ix), a
    ld a, (iy+1)
    ld (ix+1), a

    call dbl16le
    call dbl16le
    ld iy, sx
    call add16le
    ld iy, sy
    call add16le
    ld iy, twelve
    call add16le

    ld hl, (tmp)
    ld de, step_lut
    add hl, hl
    add hl, hl
    add hl, de
    ; hl now points to the value to add to x

    pop af
    pop bc
    pop de
    pop iy
    pop ix
    
    ret

offset_x: equ 126
offset_y: equ 19

chain:
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

init_chain:
    push hl
    push bc
    ld hl, chain
    ld b, 10
init_chain_loop:
    ld (hl), offset_x
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), offset_y
    inc hl
    ld (hl), 0
    inc hl
    djnz init_chain_loop
    pop bc
    pop hl
    ret
    
parse_2digit_byte:
    push bc
    ld a, (hl)
    sub 48
    inc hl
    ld b, a
    ld a, (hl)
    sub 48
    cp 10
    jp nc, parse_2digit_byte_done
    sla b
    add b
    sla b
    sla b
    add b
    pop bc
    inc hl
    ret
parse_2digit_byte_done:
    ld a, b
    pop bc
    ret

chain_len:
    db 2,0

dx:
    db 0,0
dy:
    db 0,0

get_dir:
    push bc
    ld bc, 0
    ld (dx), bc
    ld (dy), bc
    cp 'U'
    jp z, get_dir_u
    cp 'D'
    jp z, get_dir_d
    cp 'R'
    jp z, get_dir_r
    cp 'L'
    jp z, get_dir_l
    ; should be unreachable with valid input
    pop bc
    ret
get_dir_u:
    ld bc, 1
    ld (dy), bc
    pop bc
    ret
get_dir_d:
    ld bc, 0xffff
    ld (dy), bc
    pop bc
    ret
get_dir_r:
    ld bc, 1
    ld (dx), bc
    pop bc
    ret
get_dir_l:
    ld bc, 0xffff
    ld (dx), bc
    pop bc
    ret

hx_:
    db 0,0
hy_:
    db 0,0

tx:
    db 0,0
ty:
    db 0,0

sx:
    db 0,0
sy:
    db 0,0

tmp:
    db 0,0
tmp2:
    db 0,0

eval_step:
    push hl
    push de
    push bc

    ld de, sx
    ld hl, hx_
    ld bc, 4
    ldir

    ld ix, sx
    ld iy, tx
    call sub16le
    ld ix, sy
    ld iy, ty
    call sub16le

    call step_lookup
    ; hl is pointing to the mx,my pair
    ld ix, tx
    ld iy, hl
    call add16le
    ld ix, ty
    inc iy
    inc iy
    call add16le

    pop bc
    pop de
    pop hl
    ret

eval_all_steps:
    push hl
    push bc
    push de
    ; move the head by the step value
    ld ix, chain
    ld iy, dx
    call add16le
    ld ix, chain+2
    ld iy, dy
    call add16le

    ld hl, (chain)
    ld (hx_), hl

    ld hl, (chain+2)
    ld (hy_), hl

    ld hl, chain+4

    push hl
    ld hl, chain_len
    ld b, (hl)
    dec b
    pop hl
step_loop: ; this loop has one iteration per item in the chain
    push bc
    push hl
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    ld (tx), bc
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    ld (ty), bc
    call eval_step
    ld de, hx_
    ld hl, tx
    ld bc, 4
    ldir
    pop hl
    ld de, hl
    push hl
    ld hl, tx
    ld bc, 4
    ldir
    pop hl
    inc hl
    inc hl
    inc hl
    inc hl
    pop bc
    djnz step_loop
update_visited:
    ld ix, tmp
    ld (ix), line_step
    ld (ix+1), 0

    ld iy, ty
    call mul16le

    ld ix, tmp2
    ld (ix), 0
    ld (ix+1), 0

    ld iy, tx
    call add16le
    call sra16le
    call sra16le
    call sra16le
    ld ix, tmp
    ld iy, tmp2
    call add16le
    ; tmp is now the byte offset into the bitmap
    ld a, (tx)
    and 0x7
    ld b, a
    inc b
    ld a, 1
    jp shiftloop_end
shiftloop:
    sla a
shiftloop_end:
    djnz shiftloop
    ; a is now the value to or into the memory location
    ld hl, (tmp)
    ld de, bitmap_start
    add hl, de
    or (hl)
    ld (hl), a

    pop de
    pop bc
    pop hl
    ret

eval_chain:
    ld hl, 0xa000
eval_chain_loop:
    ld a, (hl)
    call get_dir
    inc hl
    inc hl
    call parse_2digit_byte
    ; a is now the number of repetitions for this direction
    ld b, a
steps_loop: ; this loop does n iterations where n is the number read from the file
    call eval_all_steps
    djnz steps_loop
    inc hl
    ld a, (hl)
    cp 0
    jp nz, eval_chain_loop
    ret

total:
    db 0,0,0,0
this_count:
    db 0,0,0,0

count_visited:
    push hl
    push bc
    push ix
    push iy
    ld hl, bitmap_start
    ld a, 0
    ld (this_count+1), a
    ld (this_count+2), a
    ld (this_count+3), a
    ld (total), a
    ld (total+1), a
    ld (total+2), a
    ld (total+3), a
    ld ix, total
    ld iy, this_count
    ld bc, bitmap_size
count_loop:
    ld a, (hl)
    inc hl
    call popcount
    ld (this_count), a
    call add32le
    dec bc
    ld a, 0
    cp b
    jp nz, count_loop
    cp c
    jp nz, count_loop
    pop iy
    pop ix
    pop bc
    pop hl
    ret
    
start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    call clear_bitmap
    call init_chain
    call eval_chain
    call count_visited
    ld iy, (iy_cache)
    ld ix, total
    call p1_result   
compute2:
    call intro_p2
    ld hl, chain_len
    ld (hl), 10
    call clear_bitmap
    call init_chain
    call eval_chain
    call count_visited
    ld iy,(iy_cache)
    ld ix, total
    call p2_result   

    call large_delay
end:
    jp end

prog_end:
    savebin "day9.bin",prog_start,prog_end-prog_start
    labelslist "day9.labels"

