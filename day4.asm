    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 4"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0
result2:
    db 0,0,0,0


range_a:
    db 0,0,0,0
range_b:
    db 0,0,0,0
range_c:
    db 0,0,0,0
range_d:
    db 0,0,0,0

check_overlap:
    push bc
    ld bc, 4
    call gte32le
    cp 1
    jp nz, check_overlap_no
    push ix
    add ix, bc
    call gte32le
    pop ix
    cp 1
    jp nz, check_overlap_no
    add iy, bc
    call gt32le
    cp 1
    jp z, check_overlap_no
    add ix, bc
    call gt32le
    cp 1
    jp z, check_overlap_no
    ld a, 1
    pop bc
    ret
check_overlap_no:
    ld a, 0
    pop bc
    ret

check_overlap2: ; ix is a, iy is c, d
    push bc
    ld bc, 4
    call gte32le
    cp 1
    jp nz, check_overlap2_no
    add iy, bc
    call gt32le
    cp 1
    jp z, check_overlap2_no
    ld a, 1
    pop bc
    ret
check_overlap2_no:
    ld a, 0
    pop bc
    ret



start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ld hl, 0xa000
loop:
    ld ix, range_a
    call parse32le
    inc hl
    ld ix, range_b
    call parse32le
    inc hl
    ld ix, range_c
    call parse32le
    inc hl
    ld ix, range_d
    call parse32le
    inc hl
    ; parsed four numbers, check overlaps
    ld ix, range_a
    ld iy, range_c
    call check_overlap
    cp 1
    jp z, yes_overlap
    ld ix, range_c
    ld iy, range_a
    call check_overlap
    cp 1
    jp z, yes_overlap
    jp no_overlap
yes_overlap:
    ld ix, result
    ld iy, dec_one
    call add32le
no_overlap:    
    ld a, (hl)
    cp 0
    jp z, output
    jp loop
output:
    ld iy,(iy_cache)
    ld ix, result
    call p1_result   
    call intro_p2
compute_part2:
    ld hl, 0xa000
loop2:
    ld ix, range_a
    call parse32le
    inc hl
    ld ix, range_b
    call parse32le
    inc hl
    ld ix, range_c
    call parse32le
    inc hl
    ld ix, range_d
    call parse32le
    inc hl
    ; parsed four numbers, check overlaps
    ld ix, range_a
    ld iy, range_c
    call check_overlap2
    cp 1
    jp z, yes_overlap2
    ld ix, range_c
    ld iy, range_a
    call check_overlap2
    cp 1
    jp z, yes_overlap2
    jp no_overlap2
yes_overlap2:
    ld ix, result2
    ld iy, dec_one
    call add32le
no_overlap2:    
    ld a, (hl)
    cp 0
    jp z, output2
    jp loop2
output2:
    ld iy,(iy_cache)
    ld ix, result2
    call p2_result       
end:
    jp end

prog_end:
    savebin "day4.bin",prog_start,prog_end-prog_start

