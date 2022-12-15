    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "math48.asm"
    include "intro48.asm"
    include "bigloops.asm"

day:
    db "11"

iy_cache:
    db 0, 0

result:
    db 0,0,0,0,0,0


add_old: ; (ix) += (ix)
    ld iy, ix
    jp add48le ; tail call

mul_old: ; (ix) *= (ix)
    ld iy, ix
    jp mul48le

add_val: equ add48le
mul_val: equ mul48le

            STRUCT monkey
op          WORD
does_div    WORD
no_div      WORD
div         BLOCK 6
val         BLOCK 6
instimes    BLOCK 6
num_items   BYTE
items       BLOCK 240 ; up to 40 48 bit integers
            ENDS

monkey_size:
    db 0,0,0,0,0,0

prod:
    db 0,0,0,0,0,0

cur_monkey:
    db 0,0

op_fn_ptr:
    db 0,0

tmp_monkey_index:
    db 0,0,0,0,0,0

parse:
    ld ix, prod
    ld (ix), 1
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ld (ix+4), 0
    ld (ix+5), 0
    ld ix, monkey_size
    ld hl, monkey
    ld (ix), hl
    ; reset to first monkey
    ld hl, monkeys
    ld (cur_monkey), hl
    ld hl, 0xa000
parse_monkey_loop:
    ld bc, 28
    add hl, bc
parse_list_loop:
    ld ix, (cur_monkey)
    ld b, (ix+monkey.num_items)
    inc b
    ld (ix+monkey.num_items), b
    push bc
    ld bc, monkey.items
    add ix, bc
    pop bc
    ld de, 6
    jp to_next_item_end
to_next_item:
    add ix, de
to_next_item_end:
    djnz to_next_item
;parse_list_loop:
    call parse48le
    add ix, de
    ld a, (hl)
    cp ','
    inc hl
    inc hl
    jp z, parse_list_loop
    ; at this point, the initial items list is parsed
    ld ix, (cur_monkey)

    ld bc, 22
    add hl, bc
    ld a, (hl)
    ; a is now the operation to do
    ld (ix+monkey.op), a
    inc hl
    inc hl
    push hl
    ld a, (ix+monkey.op)
    cp '+'
    jp nz, not_plus
    ; op is +
    ld a, (hl)
    cp 'o'
    jp nz, plus_not_old
    ld hl, add_old
    ld (ix+monkey.op), hl
    jp op_done
plus_not_old:
    ld hl, add_val
    ld (ix+monkey.op), hl
    jp op_done
not_plus:
    ; op is *
    ld a, (hl)
    cp 'o'
    jp nz, times_not_old
    ld hl, mul_old
    ld (ix+monkey.op), hl
    jp op_done
times_not_old:
    ld hl, mul_val
    ld (ix+monkey.op), hl
    jp op_done
op_done:
    pop hl
    ; zero still contains the flag from the `cp 'o'` operation
    jp z, skip_old
    ld bc, monkey.val
    add ix, bc
    call parse48le
    jp operand_done
skip_old:
    ld bc, 3
    add hl, bc
operand_done:
    ld bc, 22
    add hl, bc
    ld ix, (cur_monkey)
    ld iy, (cur_monkey)
    ld bc, monkey.div
    add ix, bc
    add iy, bc
    call parse48le
    ld ix, prod
    call mul48le
    ld bc, 30
    add hl, bc
    ld a, (hl)
    sub 0x30
    ; a is now the index of the does_div monkey
    ld ix, tmp_monkey_index
    ld (ix), a
    ld (ix+1), 0
    ld iy, monkey_size
    call mul48le
    push hl
    ld hl, (ix)
    ld bc, monkeys
    add hl, bc
    ld ix, (cur_monkey)
    ld (ix+monkey.does_div), hl
    pop hl
    
    ld bc, 32
    add hl, bc
    ld a, (hl)
    sub 0x30
    ; a is now the index of the no_div monkey
    ld ix, tmp_monkey_index
    ld (ix), a
    ld (ix+1), 0
    ld iy, monkey_size
    call mul48le
    push hl
    ld hl, (ix)
    ld bc, monkeys
    add hl, bc
    ld ix, (cur_monkey)
    ld (ix+monkey.no_div), hl
    pop hl

    ld bc, 3
    add hl, bc
    ld a, (hl)
    cp 0
    jp z, parse_done
    ld ix, (cur_monkey)
    ld de, monkey
    add ix, de
    ld (cur_monkey), ix
    jp parse_monkey_loop
parse_done:
    ret

throw_item: ; hl is the recipient monkey, ix points to the number to receive
    push de
    push hl
    push bc
    ld de, monkey.num_items
    add hl, de
    inc (hl) ; one more item now
    ld b, (hl) ; load one more than the item because the loop skips one
    inc hl ; now at items
    ld de, 6
    jp find_item_loop_end
find_item_loop:
    add hl, de
find_item_loop_end:
    djnz find_item_loop
    ld de, hl
    ld hl, ix
    ld bc, 6
    ldir
    pop bc
    pop hl
    pop de
    ret

tmp_rem:
    db 0,0,0,0,0,0

do_round:
    push ix
    push iy
    ; reset to first monkey
    ld ix, monkeys
    ld (cur_monkey), ix
monkey_round_loop:
    ld b, (ix+monkey.num_items)
    inc b
    ld ix, (cur_monkey)
    ld de, monkey.items
    add ix, de
    jp item_loop_end
item_loop:
    push bc
    push ix
    ld ix, (cur_monkey)
    ld de, monkey.instimes
    add ix, de
    ld iy, dec48_one
    call add48le
    pop ix
    ld iy, (cur_monkey)
    ld de, monkey.val
    add iy, de
    ; call the monkey.op function
    ld hl, (cur_monkey)
    ;ld de, monkey.op ; monkey.op is...
    ;add hl, de       ; ... the first item anyway
    ld c, (hl)
    inc hl
    ld h, (hl)
    ld l, c
    ; This is a call, even though it doesn't look like it
    ld bc, op_complete
    push bc ; return address
    jp (hl) ; call to op func
op_complete:
    ; now div by 3
    ld iy, three
delete_for_no_div3:
    call divmod48le
    ; now modulo prod
    ld iy, prod
    call divmod48le
    push ix
    pop de
    ld hl, divmod48le_remainder
    ld bc, 6
    ldir
    ; check if divisible by div and throw to the appropriate monkey
    ; Copy result to tmp
    push ix
    pop hl
    ld de, tmp_rem
    ld bc, 6
    ldir
    push ix
    ld ix, tmp_rem
    ld iy, (cur_monkey)
    ld de, monkey.div
    add iy, de
    call divmod48le
    ld ix, divmod48le_remainder
    ld iy, dec48_zero
    call eq48le
    cp 1
    ld ix, (cur_monkey)
    ld hl, (ix+monkey.does_div)
    jp z, div_pass
    ld hl, (ix+monkey.no_div)
div_pass:
    ; hl now points to the monkey to throw to
    pop ix
    call throw_item
    ld de, 6
    add ix, de
    pop bc
item_loop_end:
    djnz item_loop_longjump
    jp longjump_done
item_loop_longjump:
    jp item_loop
longjump_done:
    ld ix, (cur_monkey)
    ld (ix+monkey.num_items), 0
    ld de, monkey
    add ix, de
    ld (cur_monkey), ix 
    ld a, (ix)
    cp 0
    jp z, round_done
    jp monkey_round_loop
round_done:
    pop iy
    pop ix
    ret

counter:
    db 0,0,0,0,0,0
bt:
    db 0,0,0,0,0,0
bt2:
    db 0,0,0,0,0,0
do_rounds:
    ld hl, do_round
    ld ix, counter
    call big_loop
    ; thing is complete, now calculate the "monkey business" value
    ; zero bt and bt2
    ld hl, bt
    ld (hl), 0
    ld de, bt+1
    ld bc, 11
    ldir

    ld ix, monkeys

scan_monkeys:
    push ix
    ld de, monkey.instimes
    add ix, de
    ; ix now points to this inspsection count
    ld iy, bt2
    call gt48le
    cp 1
    jp nz, done_this_monkey
    ld de, bt2
    ld hl, ix   
    ld bc, 6
    ldir
    ld iy, bt
    call gt48le
    cp 1
    jp nz, done_this_monkey
    ld de, bt2
    ld hl, bt
    ld bc, 6
    ldir
    ld de, bt
    ld hl, ix
    ld bc, 6
    ldir
done_this_monkey:
    ; step to next monkey
    pop ix
    ld de, monkey
    add ix, de
    ; check for end of monkey list
    ld a, (ix)
    cp 0
    jp z, scan_done
    jp scan_monkeys
scan_done:
    ld ix, bt
    ld iy, bt2
    call mul48le
    ; result is now in bt
    ret


three:
    db 3,0,0,0,0,0
twenty:
    db 20,0,0,0,0,0
ten_thousand:
    db 10,27,0,0,0,0

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    call parse
    ld iy, twenty
    call do_rounds

output:
    ld iy,(iy_cache)
    ld ix, bt
    call p1_result   
end:
    jp end

monkeys: ; data structure for monkeys
    db 0

prog_end:
    savebin "day11.bin",prog_start,prog_end-prog_start
    labelslist "day11.labels"

