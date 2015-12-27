.16bit

.def PRG_ROM          1 ; prg-rom banks
.def CHR_ROM          1 ; chr-rom banks
.def HEADER           0 ; don't change
.def RAM              2 ; also don't change


; defines
.def PPU_CTRL1        $2000
.def PPU_CTRL2        $2001
.def PPU_STATUS       $2002
.def PPU_SPR_ADDR     $2003
.def PPU_SPR_IO       $2004
.def PPU_VRAM_ADDR1   $2005
.def PPU_VRAM_ADDR2   $2006
.def PPU_VRAM_IO      $2007

.def APU_MODCTRL      $4010
.def APU_SPR_DMA      $4014

.def APU_PAD1         $4016
.def APU_PAD2         $4017

.def BTN_CHECK        %00000001

.def SPR_ENABLED      %00010000
.def BG_ENABLED       %00001000
.def NO_L_CLIP        %00000010

.def NMI_ENABLED      %10000000
.def SPRITES_8x16     %00100000
.def BG_PT_ADDR_O     %00010000
.def SP_PT_ADDR_O     %00001000
.def VRAM_INC         %00000100
.def NT_20            %00000000
.def NT_24            %00000001
.def NT_28            %00000010
.def NT_2C            %00000011


.memorymap
defaultslot 1
slotsize $0010 ; header
slot 0 $0000
slotsize $4000 ; prg-rom
slot 1 $c000
slotsize $2000 ; chr-rom
slot 2 $0000
slotsize $800 ; ram
slot 3 $0000
.endme

.rombankmap
bankstotal PRG_ROM+CHR_ROM+1
banksize $0010 ; header
banks 1
banksize $4000 ; prg-rom
banks PRG_ROM
banksize $2000 ;chr-rom
banks CHR_ROM
.endro



.ramsection "ram" slot RAM
    test_db db
    test_dw dw
.ends


.bank HEADER
.org $0000

.section "header" force
.db "NES", $1a ; ines header
.db PRG_ROM ; PRG-ROM pages (16kb)
.db CHR_ROM ; CHR-ROM pages (8kb)
.dsb 10, $00 ; leave the trailing
; header bytes blank.
.ends


.bank PRG_ROM

.org $0000
.section "reset" force
Reset: sei ; no interrupts
    cld ; no decimal mode
    
    .rept 3 ; 3 vblanks,
    ; for the sake of
    ; safety.
    jsr vblank_cycle
    .endr

    ; load all ram with 0's.
    ; ld a with 0, then store
    ; a into the location + x.
    lda #$00
    ldx #$00

-:  sta $000,x
    sta $100,x
    sta $200,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx
    bne -

    ldx #$FF
    txs ; set up stack

    ldx #$00
    stx PPU_CTRL1
    stx PPU_CTRL2
    stx APU_MODCTRL

    ; write to $3F00
    lda #$3F
    sta PPU_VRAM_ADDR2
    lda #$00
    sta PPU_VRAM_ADDR2

    ldx #$00 ; counter

-:  lda palette,x
    sta PPU_VRAM_IO ; write to ppu
    inx
    cpx #$4; is it $4?
    bne -  ; if not, go to -

print_message:
    lda PPU_STATUS
    lda #$20
    sta PPU_VRAM_ADDR2
    lda #$42
    sta PPU_VRAM_ADDR2
    ldx #$00

-:  lda message.w, x
    cmp #$ff
    beq load_attr
    sta PPU_VRAM_IO
    inx
    jmp -


load_attr:
    lda PPU_STATUS
    lda #$23
    sta PPU_VRAM_ADDR2
    lda #$C0
    sta PPU_VRAM_ADDR2

    lda #$00
    sta PPU_VRAM_IO


    lda #BG_ENABLED|NO_L_CLIP
    sta PPU_CTRL2

    -: jsr vblank_cycle
    jmp -
.ends

.section "vblank_cycle" free
vblank_cycle:
    lda PPU_STATUS
    bpl vblank_cycle
    rts
.ends


.section "data" free
palette:
.db $0F,$30,$3E,$0F

.asctable
map "A" to "Z" = $B
map " " = $00
.enda

message:
.asc "MY FIRST NES ROM"
.db $ff

; dummy vector
dummy: rti
.ends

.orga $fffa
.section "vectors" force
.dw dummy Reset dummy
.ends

.bank 2 slot 2
.org $0000
.incbin "font.chr"