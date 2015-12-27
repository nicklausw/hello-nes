; defines
PPU_CTRL1       = $2000
PPU_CTRL2       = $2001
PPU_STATUS      = $2002
PPU_SPR_ADDR    = $2003
PPU_SPR_IO      = $2004
PPU_VRAM_ADDR1  = $2005
PPU_VRAM_ADDR2  = $2006
PPU_VRAM_IO     = $2007

APU_MODCTRL     = $4010
APU_SPR_DMA     = $4014

APU_PAD1        = $4016
APU_PAD2        = $4017

BTN_CHECK = %00000001

SPR_ENABLED = %00010000
BG_ENABLED =  %00001000
NO_L_CLIP =   %00000010

NMI_ENABLED =  %10000000
SPRITES_8x16 = %00100000
BG_PT_ADDR_O = %00010000
SP_PT_ADDR_O = %00001000
VRAM_INC     = %00000100
NT_20        = %00000000
NT_24        = %00000001
NT_28        = %00000010
NT_2C        = %00000011

; the header!
.db "NES", $1a ; ines header
.db $01 ; PRG-ROM pages (16kb)
.db $01 ; CHR-ROM pages (8kb)
.db $01
.dsb $9, $00 ; leave the trailing
; header bytes blank.


.enum $0000
    chr_ram .dsb 2
.ende


; the main code
.org $c000

; initialization
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
    cpx #32; is it 32?
    bne -  ; if not, go to -

    ; clear screen
    lda #$20
    sta PPU_VRAM_ADDR2
    lda #$00
    sta PPU_VRAM_ADDR2

    jsr clear_nam

print_message:
    lda PPU_STATUS
    lda #$20
    sta PPU_VRAM_ADDR2
    lda #$42
    sta PPU_VRAM_ADDR2
    ldx #$00

-:  lda message, x
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

    -: jmp -


vblank_cycle:
    lda PPU_STATUS
    bpl vblank_cycle
    rts

clear_nam:
    lda #$00
    tax
    tay


-:  sta PPU_VRAM_IO
    inx
    cpx #$1f
    bne -
    tax
    iny
    cpy #$1d
    bne -
    rts

palette:
.db $0F,$30,$3E,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F

message:
.db "MY FIRST NES ROM"-$36,$ff


; dummy vector
dummy: rti

; Don't touch this part
.org $fffa
.dw dummy, Reset, dummy


.incbin "font.chr"