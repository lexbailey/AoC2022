    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "wait.asm"
    include "print.asm"
    include "math.asm"
    include "intro.asm"
    include "bigloops.asm"

day:
    db " 5"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0

four:
    db 4,0,0,0
to_zero:
four_n_stacks:
    db 0,0,0,0
four_stack:
    db 0,0,0,0
hmax_mi:
    db 0,0,0,0
grid_offset:
    db 0,0,0,0
row_offset:
    db 0,0,0,0
stack_start:
    db 0,0,0,0
input_offset:
    db 0,0,0,0

counter_a:
    db 0,0,0,0
counter_b:
    db 0,0,0,0
n_stacks: ; number of stacks in the diagram
    db 0,0,0,0
n_crates: ; number of crates in total
    db 0,0,0,0
h_max: ; height of the tallest stack (only used for parsing)
    db 0,0,0,0
grid_size:
    db 0,0,0,0
extended_grid_size:
    db 0,0,0,0

grid_start:
    db 0,0


to_zero_len: equ $ - to_zero

re_zero:
    push af
    push hl
    push bc
    push de
    ld a, 0
    ld de, to_zero
    ld (de), a
    inc de
    ld hl, to_zero
    ld bc, to_zero_len
    dec bc
    ldir
    pop de
    pop bc
    pop hl
    pop af
    ret



start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ld hl, 0xa000
    ld b, 1
scan_stacks:
    ld a, (hl)
    inc hl
    inc b
    cp 10
    jp nz, scan_stacks
    srl b
    srl b
    ld hl, n_stacks
    ld (hl), b
    ld hl, grid_size ; for doing multiplication later
    ld (hl), b
    ; n_stacks has now been calculated
    ld hl, 0xa001
    ld b, -1
    ld de, 4
scan_crates:
    ld a, (hl)
    add hl, de
    cp 32
    jp z, not_a_crate
    inc b
not_a_crate:
    cp 49
    jp nz, scan_crates
    ld hl, n_crates
    ld (hl), b
    ; n_crates has now been calculated
    ld hl, 0xa000
    ld b, 0
scan_lines:
    ld a, (hl)
    inc hl
    cp 49
    jp z, done_lines
    cp 10
    jp nz, scan_lines
    inc b
    jp scan_lines
done_lines:
    ld hl, h_max
    ld (hl), b
    ; h_max has now been calculated
    ; -----
    ; now it's time to parse the grid
    ld ix, grid_size ; n_stacks
    ld iy, n_crates
    call mul32le
    ld hl, grid
    ld (grid_start), hl
    ld hl, (grid_size)
    ld bc, (n_crates)
    add hl, bc
    ld bc, hl
    ld a, 0x20
    ld hl, (grid_start)
    ld (hl), a
    ld de, (grid_start)
    inc de
    ldir
    jp do_transform
do_transform:
    ld bc, 4
    ld de, four_n_stacks
    ld hl, n_stacks
    ldir
    ld ix, four_n_stacks
    ld iy, four
    call mul32le
    ld iy, n_stacks
    ld hl, transform_stacks
    ld ix, counter_a
    call big_loop
    jp done_transform
transform_stacks:
;for stack in 0..n_stacks:
	push ix
	push iy
	ld bc, 4
	ld de, four_stack
    push ix
	pop hl
	ldir
	ld bc, 4
	ld de, stack_start
    push ix
	pop hl
	ldir
	ld ix, four_stack
	ld iy, four
	call mul32le
	ld ix, stack_start
	ld iy, n_crates
	call mul32le
	ld hl, transform_one_row
	ld iy, h_max
    ld ix, counter_b
	call big_loop
	jp done_row
transform_one_row:
		push ix
		push iy
		push ix
		ld bc, 4
		ld de, hmax_mi
		ld hl, h_max
		ldir
		ld ix, hmax_mi
        ld iy, dec_one
        call sub32le
		pop iy ; iy = i
		call sub32le
		ld bc, 4
		ld de, grid_offset
		ld hl, stack_start
		ldir
		ld ix, grid_offset
		; iy is already i
		call add32le
		ld bc, 4
		ld de, row_offset
		ld hl, four_n_stacks
		ldir
		ld ix, row_offset
		ld iy, hmax_mi
		call mul32le
		ld iy, dec_one
		call add32le
		ld bc, 4
		ld de, input_offset
		ld hl, row_offset
		ldir
		ld ix, input_offset
		ld iy, four_stack
		call add32le
		ld hl, (input_offset)
		ld bc, 0xa000
		add hl, bc
		ld a, (hl)
		ld hl, (grid_offset)
		ld bc, (grid_start)
		add hl, bc
		ld (hl), a
		pop iy
		pop ix
		ret
done_row:
	pop iy
	pop ix
	ret
done_transform:
    ld hl, 0xa000
find_instr_start:
    ld a, (hl)
    cp 10
    jp z, one_nl
    inc hl
    jp find_instr_start
one_nl:
    inc hl
    ld a, (hl)
    cp 10
    jp z, found_instr_start
    jp find_instr_start
found_instr_start:
    inc hl
instr_loop:
    ; hl now points to the start of the instruction list
    ; Skip past "move "
    ld bc, 5
    add hl, bc
    ; parse number here
    call parse8
    ; a is now the parsed number
    ; this is the number of times to repeat the action
    ld d, a
    ; now parse the source number
    ld bc, 6
    add hl, bc ; skip over the " from "
    call parse8
    ; a is now the source stack
    dec a
    ld e, a
    ; now parse the dest
    ld bc, 4
    add hl, bc
    call parse8
    ; a is now the dest stack
    dec a
    ld b, d
    ; b is the number of repetitions
    ; e is the source
    ; a is the dest
    push bc
delete_for_p2:
    jp repeat_poppush
    jp repeat_poppush2
repeat_poppush:
    push af
    ld a, e
    call pop_stack
    ld d, a
    pop af
    call push_stack
    djnz repeat_poppush
    pop bc
    inc hl
    push af
    ld a, (hl)
    cp 0
    jp z, done_poppush
    pop af
    jp instr_loop
done_poppush:
    pop af
    jp output

repeat_poppush2:

    push af
    ld a, e
    call pop_stack
    ld d, a
    push hl
    ld hl, n_stacks
    ld a, (hl)
    pop hl
    call push_stack
    pop af
    djnz repeat_poppush2

repeat_poppush2_2:

    push af
    push hl
    ld hl, n_stacks
    ld a, (hl)
    pop hl
    call pop_stack
    ld d, a
    pop af
    call push_stack
    djnz repeat_poppush2_2

    pop bc
    inc hl
    push af
    ld a, (hl)
    cp 0
    jp z, done_poppush2
    pop af
    jp instr_loop
done_poppush2:
    pop af
    jp output2


stack_num:
    db 0,0,0,0
pop_stack:
    push hl
    push de
    push bc
    ld bc, 4
    ld de, grid_offset
    ld hl, n_crates
    ldir
    ld ix, grid_offset
    ld iy, stack_num
    ld (iy), a
    ;ld (iy+1), 0
    ;ld (iy+2), 0
    ;ld (iy+3), 0
    call mul32le
    ld hl, (grid_start)
    ld bc, (grid_offset)
    add hl, bc
    call search_top
    ld a, (hl)
    ld (hl), 0x20
    pop bc
    pop de
    pop hl
    ret

push_stack: ; pushes d onto stack a
    push af
    push hl
    push bc
    push de
    ld bc, 4
    ld de, grid_offset
    ld hl, n_crates
    ldir
    ld ix, grid_offset
    ld iy, stack_num
    ld (iy), a
    ;ld (iy+1), 0
    ;ld (iy+2), 0
    ;ld (iy+3), 0
    call mul32le
    ld hl, (grid_start)
    ld bc, (grid_offset)
    add hl, bc
    call search_top
    inc hl
    pop de
    ld (hl), d
    pop bc
    pop hl
    pop af
    ret

search_top:
    ld a, (hl)
    inc hl
    cp 0x20
    jp z, found_stack_top
    jp search_top
found_stack_top:
    dec hl
    dec hl
    ret



result1_text:
    db AT, 2, 0, "              ", AT, 2, 4
result1_text_len: equ $ - result1_text
result2_text:
    db AT, 4, 0, "              ", AT, 4, 4
result2_text_len: equ $ - result2_text

output:
    ld iy, (iy_cache)
    ld de, result1_text
    ld bc, result1_text_len
    call ROM_PRINT
    ld hl, n_stacks
    ld b, (hl)
    ld de, (n_crates)
    ld hl, (grid_start)
output_loop:
    push hl
    call search_top
    ld a, (hl)
    rst 0x10
    pop hl
    add hl, de
    djnz output_loop
part2:
    ld iy, (iy_cache)
    call intro_p2
    ld ix, delete_for_p2
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    call re_zero
    jp compute
output2:
    ld iy, (iy_cache)
    ld de, result2_text
    ld bc, result2_text_len
    call ROM_PRINT
    ld hl, n_stacks
    ld b, (hl)
    ld de, (n_crates)
    ld hl, (grid_start)
output_loop2:
    push hl
    call search_top
    ld a, (hl)
    rst 0x10
    pop hl
    add hl, de
    djnz output_loop2
    call large_delay
end:
    jp end


parse8:
    push bc
    ld b, 0
    ld a, (hl)
parse8_loop:    
    sub 48
    inc hl
    ld c, b
    sla b
    sla b
    sla b
    sla c
    add a, b
    add a, c
    ld b, a
    ld a, (hl)
    ; space or newline char will end the number
    cp 0x20
    jp z, parse8_done
    cp 0x0A
    jp z, parse8_done
    jp parse8_loop
parse8_done:    
    ld a, b
    pop bc
    ret

grid:
    db 0 ; ... this is the end of the program in memory, and this is where the ""heap"" starts

prog_end:
    savebin "day5.bin",prog_start,prog_end-prog_start
    labelslist "day5.labels"

