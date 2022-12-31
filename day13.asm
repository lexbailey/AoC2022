    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "wait.asm"
    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db "13"

iy_cache:
    db 0, 0

ia:
    dw 0xa000
ib:
    dw 0xa000

p2_res:
    db 1,0,0,0
tmp:
    db 0,0,0,0
tmp2:
    db 0,0,0,0

s:
    db 0,0,0,0
ia2:
    dw 0xa000
ib2:
    dw 0xa000
i_:
    db 0,0,0,0
n_indexes:
    db 0,0,0,0
end_index:
    db 0,0
next_index:
    db 0,0

debug_y:
    db 0,0,0,0

; to check if is digit
;    sub 48
;    cp 10
;    ; check if C set

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

compare_numbers:
    push hl
    push bc
    ld hl, (ia)
    call parse_2digit_byte
    ld (ia), hl
    ld b, a
    ld hl, (ib)
    call parse_2digit_byte
    ld (ib), hl
    cp b
    ld a, 1
    jp nc, compare_numbers_not_bgta
    ld a, 255
compare_numbers_not_bgta:
    jp nz, compare_numbers_done
    ld a, 0
compare_numbers_done:
    pop bc
    pop hl
    ret

compare_lists:
    push hl
compare_lists_loop:
    ld hl, (ia)
    ld a, (hl)
    cp ']'
    jp z, compare_lists_end_one
    ld hl, (ib)
    ld a, (hl)
    cp ']'
    jp z, compare_lists_end_one

    sub 48
    cp 10
    jp nc, compare_lists_end_one
    ld hl, (ia)
    ld a, (hl)
    sub 48
    cp 10
    jp nc, compare_lists_end_one
    
    ; both items are numbers
    call compare_numbers
    cp 0
    jp nz, compare_lists_num_not_zero

    ld hl, (ia)
    ld a, (hl)
    cp ','
    jp nz, compare_lists_a_not_comma
    inc hl
    ld (ia), hl
compare_lists_a_not_comma:
    ld hl, (ib)
    ld a, (hl)
    cp ','
    ;jp nz, compare_lists_b_not_comma
    jp nz, compare_lists_loop
    inc hl
    ld (ib), hl
compare_lists_b_not_comma:
    jp compare_lists_loop
compare_lists_end_one:
    ld hl, (ia)
    ld a, (hl)
    cp ']'
    jp nz, compare_lists_end_minone
    ld hl, (ib)
    ld a, (hl)
    cp ']'
    jp z, compare_lists_end_minone
    ld a, 1
    pop hl
    ret
compare_lists_end_minone:
    ld hl, (ib)
    ld a, (hl)
    cp ']'
    jp nz, compare_lists_end_defer
    ld hl, (ia)
    ld a, (hl)
    cp ']'
    jp z, compare_lists_end_defer
    ld a, 255
    pop hl
    ret
compare_lists_end_defer:
    pop hl
    jp compare ; tail call
compare_lists_num_not_zero:
    pop hl
    ret

skip_rsqbr: ; skip right square brackets
    push af
    push hl
    ld hl, (ia)
skip_rsqbr_loop:
    ld a, (hl)
    cp ']'
    jp nz, skip_done
    ld hl, (ib)
    ld a, (hl)
    cp ']'
    jp nz, skip_done
    inc hl
    ld (ib), hl
    ld hl, (ia)
    inc hl
    ld (ia), hl
    jp skip_rsqbr_loop
skip_done:
    pop hl
    pop af
    ret

check_list_end:
    push hl
check_list_end_a:
    ld hl, (ia)
    ld a, (hl)
    cp ']'
    jp nz, check_list_end_b
    ld hl, (ib)
    ld a, (hl)
    cp ','
    jp nz, check_list_end_b
    ld a, 1
    pop hl
    ret
check_list_end_b:
    ld hl, (ib)
    ld a, (hl)
    cp ']'
    jp nz, check_list_end_none
    ld hl, (ia)
    ld a, (hl)
    cp ','
    jp nz, check_list_end_none
    ld a, 255
    pop hl
    ret
check_list_end_none:
    ld a, 0
    pop hl
    ret


compare:
    call skip_rsqbr
    call check_list_end
    cp 0
    ret nz
    push af
    push bc
    push hl
    push de
    ; at least one is still a list
    ld b, 1 ; will track if both are lists
    ld hl, (ia)
    ld de, hl
    ld a, (hl)
    cp '['
    jp z, compare_a_is_list
    cp  ','
    jp z, compare_a_is_list
    jp compare_a_not_list
compare_a_is_list:
    inc hl
    ld (ia), hl
    jp compare_a_check_done
compare_a_not_list:
    ld b, 0
compare_a_check_done:
    ld hl, (ib)
    ld a, (hl)
    cp '['
    jp z, compare_b_is_list
    cp  ','
    jp z, compare_b_is_list
    jp compare_b_not_list
compare_b_is_list:
    inc hl
    ld (ib), hl
    jp compare_b_check_done
compare_b_not_list:
    ld b, 0
compare_b_check_done:
    ; if both are lists then defer to compare_lists
    ld a, b
    cp 1
    jp z, compare_defer_lists
    ; otherwise pretend one item is a list
    ;ld hl, (ia)
    ;dec hl
    ld a, (de)
    cp '['
    jp nz, compare_asym_a_not_list


compare_listify_b:
    ; copy the b string to the temp string location
    ld hl, (ib)
    ld de, tmp_str_b+1
compare_copy_b_loop:
    ldi
    ld a, (hl)
    sub 48
    cp 10
    jp c, compare_copy_b_loop
    ld a, ']'
    ld (de), a
    inc de
compare_copy_b_loop2:    
    ldi
    ld a, (hl)
    cp 10
    jp nz, compare_copy_b_loop2
    ld hl, de
    ld (hl), 10
    ld hl, tmp_str_b2
    ld (ib), hl
    ld hl, ia
    ld de, (hl)
    dec de
    ld (hl), de
    ld de, tmp_str_b2
    ld hl, tmp_str_b
    ld bc, 300 ; TODO this can be smaller
    ldir
    pop de
    pop hl
    pop bc
    pop af
    jp compare ; tail call
compare_asym_a_not_list:



compare_listify_a:
    ; copy the a string to the temp string location
    ld hl, (ia)
    ld de, tmp_str_a+1
compare_copy_a_loop:
    ldi
    ld a, (hl)
    sub 48
    cp 10
    jp c, compare_copy_a_loop
    ld a, ']'
    ld (de), a
    inc de
compare_copy_a_loop2:    
    ldi
    ld a, (hl)
    cp 10
    jp nz, compare_copy_a_loop2
    ld hl, de
    ld (hl), 10
    ld hl, tmp_str_a2
    ld (ia), hl
    ld hl, ib
    ld de, (hl)
    dec de
    ld (hl), de
    ld de, tmp_str_a2
    ld hl, tmp_str_a
    ld bc, 300 ; TODO this can be smaller
    ldir
    pop de
    pop hl
    pop bc
    pop af
    jp compare ; tail call
compare_defer_lists:
    pop de
    pop hl
    pop bc
    pop af
    jp compare_lists ; tail call

one:
    db 1,0,0,0

part1:
    push hl
    ld hl, next_index
    ld de, indexes
    ld (hl), de
part1_loop:
    ld ix, i_
    ld iy, one
    call add32le

    ld hl, (ib2)
scan_b_start_loop:
    ld a, (hl)
    cp 10
    inc hl
    jp nz, scan_b_start_loop
    ld (ib2), hl
    ld (ib), hl
    ld hl, (ia2)
    ld (ia), hl
    

    ld hl, ia
    ld de, (next_index)
    ld bc, 4
    ldir
    ld (next_index), de

    call compare
    cp 1
    jp nz, p1_not1
    ld ix, s
    ld iy, i_
    call add32le
p1_not1:
    ld hl, (ib2)
    ld (ia2), hl
scan_a_start_loop:
    ld a, (hl)
    cp 10
    inc hl
    jp nz, scan_a_start_loop
    ld a, (hl)
    cp 0
    jp z, p1_complete
    inc hl
    ld (ia2), hl
    ld (ib2), hl
    jp part1_loop
p1_complete:
    ;ld (ia2), hl
    ;ld (end_index), hl
    ld de, n_indexes
    ld hl, i_
    ld bc, 4
    ldir
    ld ix, n_indexes
    pop hl
    jp dbl32le ; tail call

; align these so that the high bytes of their addresses are equal, saves a comparison in the search loop
    ALIGN 4
additional_1:
    db "[[2]]", 10
additional_2:
    db "[[6]]", 10

additional_prefix: equ (additional_1 >> 8) & 0xff
additional_s1: equ additional_1 & 0xff
additional_s2: equ additional_2 & 0xff

part2:
    ld hl, (next_index)
    ld de, additional_1
    ld (hl), de
    inc hl
    inc hl
    ld de, additional_2
    ld (hl), de
    ld hl, (n_indexes)
    inc hl
    inc hl
    ld (n_indexes), hl


    ld bc, (n_indexes)
p2_xloop:
    dec bc
    push bc
    ld bc, (n_indexes)
    dec bc
p2_yloop:
    dec bc

    ld hl, indexes
    add hl, bc
    add hl, bc
    ld de, (hl)
    ld (ia), de
    ld (ia2), de
    inc hl
    inc hl
    ld de, (hl)
    ld (ib), de
    ld (ib2), de
    call compare
    cp 255
    jp nz, p2_noswap
debug_stuff:
    push hl
    ld hl, debug_y
    ld (hl), bc
    pop hl
end_debug_stuff:
    push bc
    ld de, (hl)
    dec hl
    dec hl
    ld bc, (hl)
    ld (hl), de
    inc hl
    inc hl
    ld (hl), bc
    pop bc

p2_noswap:
    ld a, c
    cp 0
    jp nz, p2_yloop
    ld a, b
    cp 0
    jp nz, p2_yloop

    pop bc
    ld a, c
    cp 0
    jp nz, p2_xloop
    ld a, b
    cp 0
    jp nz, p2_xloop
    ld hl, indexes
p2_search_loop:
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ld a, 0
    cp d
    jp nz, p2_search_noskip
    cp e
    jp z, p2_search_done
p2_search_noskip:
    ld a, additional_prefix
    cp d
    jp nz, p2_search_loop
    ld a, additional_s1
    cp e
    jp z, p2_special
    ld a, additional_s2
    cp e
    jp z, p2_special
    jp p2_search_loop
p2_special:
    ld ix, tmp
    ld (ix), l
    ld (ix+1), h
    ld iy, tmp2
    ld (iy), indexes & 0xff
    ld (iy+1), (indexes >> 8) & 0xff
    call sub32le
    call sra32le
    ld iy, tmp
    ld ix, p2_res
    call mul32le
    jp p2_search_loop
p2_search_done:
    ret

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    call part1
output:
    ld iy,(iy_cache)
    ld ix, s
    call p1_result   
    call intro_p2
    call part2
    ld iy,(iy_cache)
    ld ix, p2_res
    call p2_result

    call large_delay
end:
    jp end

; TODO make these labels be calculated and then remove padding
tmp_str_a:
    db '['
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
tmp_str_b:
    db '['
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
tmp_str_a2:
    db '['
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
tmp_str_b2:
    db '['
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

indexes:
    db 0

prog_end:
    savebin "day13.bin",prog_start,prog_end-prog_start
    labelslist "day13.labels"

