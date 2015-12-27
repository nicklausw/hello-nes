
  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

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
;;;;;;;;;;;;;;;


  .bank 0
  .org $C000
Reset: sei ; no interrupts
    cld ; no decimal mode
    
    ; nesasm doesn't seem to have a
    ; repeat feature, and so i have
    ; to write these cycles out
    ; manually...ugh. i hate this assembler.
    jsr vblank_cycle
    jsr vblank_cycle
    jsr vblank_cycle

    ; load all ram with 0's.
    ; ld a with 0, then store
    ; a into the location + x.
    lda #$00
    ldx #$00

raml:  sta $000,x
    sta $100,x
    sta $200,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx
    bne raml

    ldx #$FF
    txs ; set up stack

    ldx #$00
    stx PPU_CTRL1
    stx PPU_CTRL2
    stx APU_MODCTRL

    jsr vblank_cycle

    ; write to $3F00
    lda #$3F
    sta PPU_VRAM_ADDR2
    lda #$00
    sta PPU_VRAM_ADDR2

    ldx #$00 ; counter

palloop:  lda palette,x
    sta PPU_VRAM_IO ; write to ppu
    inx
    cpx #$4; is it $4?
    bne palloop  ; if not, go to palloop

print_message:
    lda PPU_STATUS
    lda #$20
    sta PPU_VRAM_ADDR2
    lda #$42
    sta PPU_VRAM_ADDR2
    ldx #$00

msgloop: lda message, x
    cmp #$ff
    beq load_attr
    sta PPU_VRAM_IO
    inx
    jmp msgloop


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

    end: jsr vblank_cycle
    jmp end


vblank_cycle:
    lda PPU_STATUS
    bpl vblank_cycle
    rts


palette:
  .db $0F,$30,$3E,$0F

message:
  .db $17,$23,$00,$10,$13,$1C,$1D,$1E
  .db $00,$18,$0F,$1D,$00,$1C,$19,$17,$FF

; dummy vector
dummy: rti

; Don't touch this part
  .bank 1
  .org $fffa
  .dw dummy, Reset, dummy


  .incbin "font.chr"