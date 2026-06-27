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

	loadn r0, #595  
	loadn r1, #CorpoCobra
	storei r1, r0


	loadn r1, #0
	loadn r2, #CabecaCobra
	storei r2, r1

	loadn r0, #CorpoCobra
	loadi r0, r0
	loadn r1, #CabecaCobra
	loadi r1,r1

    outchar r0, r1

	loadn r7, #TelaJogo
    add r7, r7, r1
    storei r7, r0

	loadn r7, #0
	print_inicial:
		call comeu_maca
		inc r7
		loadn r2, #4
		cmp r2, r7 
		jne print_inicial



main_loop:
	call obter_movimento

	

	loadn r7, #TelaJogo  ; Pega o início da tela
    add r7, r7, r1     ; Adiciona a posição da cabeça da cobra (r1)
    loadi r7, r7       ; Lê o caractere desenhado lá
    loadn r4, #2381    ; Caractere/Cor da maçã
    cmp r7, r4
	jeq comeu_maca

	pop r6

	loadn r5, #' ';
    outchar r5, r6

	loadn r7, #TelaJogo
    add r7, r7, r6
    storei r7, r5
	
	outchar r0, r1

	loadn r7, #TelaJogo
    add r7, r7, r1
    storei r7, r0

	jmp main_loop
	
obter_movimento:
	
	inchar r2
	
	loadn r7, #255
	cmp r2, r7
	jeq obter_movimento
    mov r6, r1

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

comeu_maca:
	loadn r4, #90
	add r5, r5, r4
	call rand
	loadn r4, #2381
	outchar r4, r5

	loadn r3, #TelaJogo
    add r3, r3, r5
    storei r3, r4

	rts

rand:
	loadn r2, #102
	loadn r3, #3131
	loadn r4, #1200
	mul r5, r5, r2
	add r5, r5, r3
	mod r5, r5, r4
	rts

TelaJogo: var #4000
CorpoCobra: var #6000
CabecaCobra: var #8000

		
	