    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db "10"

iy_cache:
    db 0, 0

x_reg:
    db 1,0,0,0
tmp:
    db 0,0,0,0
result:
    db 0,0,0,0

time:
    db 0xec, 0xff, 0xff, 0xff
time_total:
    db 0,0,0,0
strength:
    db 0,0,0,0
twenty:
    db 20,0,0,0
forty:
    db 40,0,0,0

prod:
    db 0,0,0,0

minus_two:
    db 0xfe, 0xff, 0xff, 0xff
two:
    db 2,0,0,0

vram_line:
    dw 0x4080
vram_cell:
    dw 9 ; start at cell 9
vram_pix:
    db 7

do_pixel:
    push hl
    push bc
    ld hl, vram_pix
    ld b, (hl)
    inc b
    jp shift_pixel_end
shift_pixel_loop:
    sla a
shift_pixel_end:
    djnz shift_pixel_loop
    push af
    dec (hl)
    ld a, (hl)
    cp 0xff
    jp nz, no_reset
    ld b, 7
    ld (hl), b
no_reset:
    ld hl, (vram_line)
    ld bc, (vram_cell)
    add hl, bc
    pop af
    ld b, (hl)
    or b
    ld (hl), a
    push af
    ld hl, vram_pix
    ld a, (hl)
    cp 7 ; just reset pixel count, go to next cell
    jp nz, no_next_cell
    ld hl, vram_cell
    inc (hl)
no_next_cell:
    pop af
    pop bc
    pop hl
    ret

next_line:
    push hl
    ld hl, vram_line
    inc hl
    inc (hl)
    ld hl, vram_cell
    ld (hl), 8
    inc hl
    ld (hl), 0
    ld hl, vram_pix
    ld (hl), 8
    pop hl
    ret

step:
    push af
    push ix
    push iy
    ld ix, time
    ld iy, dec_one
    call add32le
    ld ix, time_total
    call add32le
    ld ix, time
    ld iy, dec_zero
    call eq32le
    cp 1
    jp nz, dont_add_strength
    ld ix, time
    ld iy, forty
    call sub32le
    ld ix, prod
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld iy, time_total
    call add32le
    ld iy, x_reg
    call mul32le
    ld iy, prod
    ld ix, strength
    call add32le
dont_add_strength:
; part 2 bitmap generation
    ld ix, tmp
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld iy, time
    call add32le
    ld iy, twenty
    call add32le
    ld iy, x_reg
    call sub32le
    ld iy, dec_zero
    call eq32le
    cp 1
    jp z, pixel
    ld iy, dec_one
    call eq32le
    cp 1
    jp z, pixel
    ld iy, two
    call eq32le
    cp 1
    jp z, pixel

    ;try again 40 higher
    ld iy, forty
    call add32le
    ld iy, dec_zero
    call eq32le
    cp 1
    jp z, pixel
    ld iy, dec_one
    call eq32le
    cp 1
    jp z, pixel
    ld iy, two
    call eq32le
    cp 1
    jp z, pixel



    jp no_pixel
pixel:
    ld a, 1
    call do_pixel
    jp check_line
no_pixel:
    ld a, 0
    call do_pixel
    ;jp check_line
check_line:
    ; check if we need to call next_line
    ld ix, tmp
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld iy, time
    call add32le
    ld iy, twenty
    call add32le
    ld iy, dec_one
    call add32le
    ld iy, dec_zero
    call eq32le
    cp 1
    jp nz, step_done
    call next_line
step_done:
    pop iy
    pop ix
    pop af
    ret

p2_text_custom:
    db AT, 3, 0, "Part2..."
p2_text_custom_len: equ $ - p2_text_custom
intro_p2_custom:
    push de
    push bc
    ld de, p2_text_custom
    ld bc, p2_text_custom_len
    call ROM_PRINT
    pop bc
    pop de
    ret

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
    call intro_p2_custom
compute:
    ld bc, 5
    ld hl, 0xa000
parse_loop:
    ld a, (hl)
    cp 0
    jp z, parse_done
    add hl, bc
    call step
    cp 0x61 ; 'a'
    jp nz, parse_loop
    call step
    ld ix, tmp
    call parses32le
    ld iy, ix
    ld ix, x_reg
    call add32le
    inc hl
    jp parse_loop
parse_done:
    
output:
    ld iy,(iy_cache)
    ld ix,strength 
    call p1_result
end:
    jp end

prog_end:
    savebin "day10.bin",prog_start,prog_end-prog_start
    labelslist "day10.labels"

