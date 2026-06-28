; Hello World - Escreve mensagem armazenada na memoria na tela


; ------- TABELA DE CORES -------
; adicione ao caracter para Selecionar a cor correspondente

; 0 branco							0000 0000
; 256 marrom						0001 0000
; 512 verde							0010 0000
; 768 oliva							0011 0000
; 1024 azul marinho					0100 0000
; 1280 roxo							0101 0000
; 1536 teal							0110 0000
; 1792 prata						0111 0000
; 2048 cinza						1000 0000
; 2304 vermelho						1001 0000
; 2560 lima							1010 0000
; 2816 amarelo						1011 0000
; 3072 azul							1100 0000
; 3328 rosa							1101 0000
; 3584 aqua							1110 0000
; 3840 branco						1111 0000



main:

	loadn r1, #0
    loadn r2, #CabecaCobra
    storei r2, r1

    call imprime_cobra
	call gerar_maca



main_loop:
	call obter_movimento
    call atualizar_cobra
	jmp main_loop
	
obter_movimento:
    load r1, CabecaCobra

    inchar r4
    loadn r7, #255
    cmp r7, r4
    jeq mantem_direcao         

   
    store DirecaoMovimento, r4

mantem_direcao:
    load r2, DirecaoMovimento  
    
    loadn r7, #255
    cmp r2, r7
    jeq obter_movimento        

    loadn r7, #40
    cmp r2, r7
    jeq baixo
    
    loadn r7, #39
    cmp r2, r7
    jeq direita
    
    loadn r7, #38
    cmp r2, r7
    jeq cima
    
    loadn r7, #37
    cmp r2, r7
    jeq esquerda

    rts

direita:
	inc r1
	rts
	
esquerda:
	dec r1
	rts

cima:
	loadn r7, #40
	sub r1, r1, r7
	rts

baixo:
	loadn r7, #40
	add r1, r1, r7
	rts

rand:
	loadn r1, #1033
	loadn r2, #3301
	loadn r3, #1200
	mul r4, r0, r1
	add r4, r4, r2
    load r7, DirecaoMovimento
    add r4, r4, r7
	mod r4, r4, r3
    mov r0, r4
	rts

atualizar_cobra:
    loadn r0, #CabecaCobra

    load r2, TamanhoCobra

    loadn r3, #0

    mov r7, r1

    loop_atualizacao:
        loadi r4, r0
        storei r0, r7
        mov r7,r4
        inc r3
        inc r0
        cmp r2,r3
        jne loop_atualizacao

    
    loadn r5, #' '
    outchar r5, r7

    loadn r0, #TelaJogo
    add r0, r0, r7
    storei r0, r5

    call verifica_colisao
    call comeu_maca
    call imprime_cobra
    rts


comeu_maca:
    loadn r0, #TelaJogo
    load r1, CabecaCobra
    add r0, r0, r1
    loadi r0, r0
    loadn r2, #2381
    cmp r0,r2
    jne nao_comeu

    call aumenta_cobra
    call gerar_maca
    rts

nao_comeu:
    rts

aumenta_cobra:

    load r0, TamanhoCobra
    loadn r1, #CabecaCobra
    add r1, r1, r0
    storei r1, r7


    load r1, CorCobra
    outchar r1, r7

    loadn r0, #TelaJogo
    add r0, r0, r7
    storei r0, r1

    load r0, TamanhoCobra
    inc r0
    store TamanhoCobra, r0
    rts 


imprime_cobra:

    load r7, CabecaCobra
    load r6, CorCobra
    outchar r6, r7

    loadn r2, #TelaJogo
    add r2, r2, r7
    storei r2, r6

    rts

gerar_maca:
	call rand

    loadn r1, #TelaJogo
    add r1, r1, r0             ; r1 = TelaJogo + Coordenada Sorteada
    loadi r2, r1               ; r2 = Lê o que está na tela virtual
    
    loadn r3, CorCobra             ; Caractere de espaço (vazio)
    cmp r2, r3                 
    jeq gerar_maca

	loadn r1, #2381
	outchar r1, r0

	loadn r2, #TelaJogo
    add r2, r2, r0
    storei r2, r1
	rts
atualizar_direcao:
    store DirecaoMovimento, r4
    rts

verifica_colisao:
    load r0, CabecaCobra
    loadn r1, #TelaJogo
    add r1, r1, r0
    loadi r1, r1
    load r2, CorCobra
    cmp r2, r1
    jeq fim_de_jogo
    rts
fim_de_jogo:
    loadn r0, #615
    loadn r1, #2887        ; Letra 'G' (71) + Amarelo (2816) = 2887
    outchar r1, r0
    
    inc r0
    loadn r1, #2881        ; Letra 'A' (65)
    outchar r1, r0

    inc r0
    loadn r1, #2893        ; Letra 'M' (77)
    outchar r1, r0

    inc r0
    loadn r1, #2885        ; Letra 'E' (69)
    outchar r1, r0

    inc r0
    inc r0                 ; Pula o espaço

    loadn r1, #2895        ; Letra 'O' (79)
    outchar r1, r0

    inc r0
    loadn r1, #2902        ; Letra 'V' (86)
    outchar r1, r0

    inc r0
    loadn r1, #2885        ; Letra 'E' (69)
    outchar r1, r0

    inc r0
    loadn r1, #2898        ; Letra 'R' (82)
    outchar r1, r0
    halt

TelaJogo: var #1200     
CabecaCobra: var #1200         
TamanhoCobra: var #1     
static TamanhoCobra, #1
CorCobra: var #1        
static CorCobra, #595
DirecaoMovimento: var #1
static DirecaoMovimento, #255
Semente: var #1
static Semente, #42           
		
	