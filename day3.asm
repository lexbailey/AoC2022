    DEVICE ZXSPECTRUM48

    org  $8000
prog_start:
    jp start 

    include "print.asm"
    include "math.asm"
    include "intro.asm"

day:
    db " 3"

iy_cache:
    db 0, 0

priority: ; lookup the priority of `a`, return the result in `a`
    ; bit 6 determines case (1 is lower case)
    ; take the last 5 bits, if bit 6 is 0 then add 26 to the result
    push af
    and 0x20 ; test bit 6
    jp nz, priority_lowercase
    pop af
    and 0x1f
    add 26
    ret
priority_lowercase:
    pop af
    and 0x1f
    ret

result:
    db 0,0,0,0

tmp:
    db 0,0,0,0

line_end:
    db 0,0
line_mid:
    db 0,0

start:
    ld (iy_cache),iy
    call ROM_CLS
    ld hl, day
    call intro_p1
compute:
    ld hl, 0xa000
    ld bc, 0xa000
line_loop:
    ld d, 0
    ld e, 0
    ld b, h
    ld c, l
length_loop:
    ; get the length of this line
    inc bc
    inc e
    ld a, (bc)
    cp 10 ;check for line feed
    jp nz, length_loop
    ; e is now the line length
    srl e ; e /=2
    ; bc is at the end of the line
    ; move hl to the middle of the line
    add hl, de
    dec hl
    ; save line end location
    ld (line_end), bc
    ld (line_mid), hl
    ld ix, (line_end)
    ; do line computation
scan_half:
    ld b, e
    ld c, (ix)
step_back:
    ld a, (hl)
    dec hl
    cp c
    jp z, scan_done
    djnz step_back
    dec ix
    ld hl, (line_mid)
    jp scan_half
scan_done:
    ; a now contains the duplicate
    call priority
    ld (tmp), a
    ld ix, result
    ld iy, tmp
    call add32le
    ; this priority number has now been added to the result
    ld hl, (line_end)
    inc hl
    ld a, (hl)
    cp 0
    jp nz, line_loop
output:
    ld iy,(iy_cache)
    ld ix, result
    call p1_result   
    call intro_p2
    jp part2


line1_start:
    db 0,0
line2_start:
    db 0,0
line3_start:
    db 0,0

result2:
    db 0,0,0,0
tmp2:
    db 0,0,0,0


line_contains_char: ; check if line pointed to by hl contains the char in c, result is in the zero flag, clobbers hl and a
    ld a, (hl)
    cp 10
    jp z, line_contains_char_end
    cp c
    ret z
    inc hl
    jp line_contains_char
line_contains_char_end:
    cp 0
    ret
    

part2:
    ; Part 2 is similar, except instead of half rows, we need to consider three rows
    ; There's an additional layer of complexity: the item needs to exist in all three lines
    ; Start by finding the starts of the three lines we care about next
    ld hl, 0xa000
find_lines:
    ; upon arriving at find_lines, hl should point to the first char in the first line
    ld (line1_start), hl
find_line_2:
    inc hl
    ld a, (hl)
    cp 0
    jp z, part2_done
    cp 10
    jp nz, find_line_2
    inc hl
    ld (line2_start), hl
find_line_3:
    inc hl
    ld a, (hl)
    cp 10
    jp nz, find_line_3
    inc hl
    ld (line3_start), hl
found_lines:
    ; we now have three pointers, one pointing to each line in this group
    ld ix, (line1_start)
    ld iy, tmp2
line1_loop:
    ld c, (ix)
    ld hl, (line2_start)
    call line_contains_char
    jp nz, next_char
    ld hl, (line3_start)
    call line_contains_char
    jp nz, next_char
    ; c is the common char
    ld a, c
    call priority
    ld (tmp2), a
    ld ix, result2
    call add32le
    ld hl, (line3_start)
skip_line:
    ld a, (hl)
    inc hl
    cp 10
    jp nz, skip_line
    jp find_lines
next_char:
    inc ix
    jp line1_loop
part2_done:
    ld iy,(iy_cache)
    ld ix, result2
    call p2_result
end:
    jp end

prog_end:
    savebin "day3.bin",prog_start,prog_end-prog_start

