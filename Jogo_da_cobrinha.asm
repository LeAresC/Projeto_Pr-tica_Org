jmp pergunta_dificuldade
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




pergunta_dificuldade:
    ; "CHOOSE" em Branco (Cor 0) perfeitamente centralizado
    loadn r0, #457
    loadn r1, #'C'
    outchar r1, r0  
    inc r0
    loadn r1, #'H'
    outchar r1, r0  
    inc r0
    loadn r1, #'O'
    outchar r1, r0  
    inc r0
    loadn r1, #'O'      ; Segundo 'O'
    outchar r1, r0  
    inc r0
    loadn r1, #'S'
    outchar r1, r0 
    inc r0
    loadn r1, #'E'
    outchar r1, r0  

    ; "1: EASY" em Verde (512)
    loadn r0, #576
    loadn r1, #561      ; '1' (49) + Verde (512)
    outchar r1, r0
    inc r0
    loadn r1, #570      ; ':' (58) + 512
    outchar r1, r0
    inc r0
    inc r0              ; Espaço
    loadn r1, #581      ; 'E' (69) + 512
    outchar r1, r0
    inc r0
    loadn r1, #577      ; 'A' (65) + 512
    outchar r1, r0
    inc r0
    loadn r1, #595      ; 'S' (83) + 512
    outchar r1, r0
    inc r0
    loadn r1, #601      ; 'Y' (89) + 512
    outchar r1, r0

    ; "2: MEDIUM" em Amarelo (2816)
    loadn r0, #616
    loadn r1, #2866     ; '2' (50) + Amarelo (2816)
    outchar r1, r0
    inc r0
    loadn r1, #2874     ; ':' (58) + 2816
    outchar r1, r0
    inc r0
    inc r0              ; Espaço
    loadn r1, #2893     ; 'M' (77) + 2816
    outchar r1, r0
    inc r0
    loadn r1, #2885     ; 'E' (69) + 2816
    outchar r1, r0
    inc r0
    loadn r1, #2884     ; 'D' (68) + 2816
    outchar r1, r0
    inc r0
    loadn r1, #2889     ; 'I' (73) + 2816
    outchar r1, r0
    inc r0
    loadn r1, #2901     ; 'U' (85) + 2816
    outchar r1, r0
    inc r0
    loadn r1, #2893     ; 'M' (77) + 2816
    outchar r1, r0

    ; "3: HARD" em Vermelho (2304)
    loadn r0, #656
    loadn r1, #2355     ; '3' (51) + Vermelho (2304)
    outchar r1, r0
    inc r0
    loadn r1, #2362     ; ':' (58) + 2304
    outchar r1, r0
    inc r0
    inc r0              ; Espaço
    loadn r1, #2376     ; 'H' (72) + 2304
    outchar r1, r0
    inc r0
    loadn r1, #2369     ; 'A' (65) + 2304
    outchar r1, r0
    inc r0
    loadn r1, #2386     ; 'R' (82) + 2304
    outchar r1, r0
    inc r0
    loadn r1, #2372     ; 'D' (68) + 2304
    outchar r1, r0

decide_diculdade:
    inchar r0

    loadn r7, #255
    cmp r0, r7
    jeq decide_diculdade

    loadn r7, #'1'
    cmp r0, r7
    jeq facil

    loadn r7, #'2'
    cmp r0, r7
    jeq medio

    loadn r7, #'3'
    cmp r0, r7
    jeq dificil

    jmp decide_diculdade

facil:
    loadn r0, #35
    store Velocidade, r0

    loadn r0, #HighScoreEasy
    loadn r1, #HighScore
    storei r1, r0

    call limpa_tela
    jmp main

medio:
    loadn r0, #30
    store Velocidade, r0

    loadn r0, #HighScoreMedium
    loadn r1, #HighScore
    storei r1, r0

    call limpa_tela
    jmp main

dificil:
    loadn r0, #25
    store Velocidade, r0

    loadn r0, #HighScoreHard
    loadn r1, #HighScore
    storei r1, r0

    call limpa_tela
    jmp main

main:
    loadn r0, #0
    store CabecaCobra, r0  
    store RaboCobra, r0
    store CurScore, r0

    store QuantMaca, r0    ; Zera o contador de maçãs
    store Tempo, r0        ; Zera o timer de animação


    loadn r0, #80
    store CorpoCobra, r0
    
    loadn r0, #255
    store DirecaoMovimento, r0  ; Reseta a direção para parado


    ; --- Imprime a cobra inicial na tela ---
    load r0, CorCobra
    loadn r1, #80                ; Coordenada inicial (0)
    outchar r0, r1              ; Pinta no monitor
    
    loadn r2, #TelaJogo
    add r2, r2, r1
    storei r2, r0               ; Pinta no shadow buffer

    call gerar_paredes
    call inicializa_posicao_maca
    call gerar_score
    call gerar_highscore

main_loop:
	call obter_movimento
    call atualizar_cobra
    call tenta_gerar_maca
    call aumenta_tempo
    call tenta_animar_maca
    call delay
	jmp main_loop
	
obter_movimento:
    ; --- LÊ A COORDENADA REAL DA CABEÇA ---
    load r0, CabecaCobra       ; r0 = Índice atual (a "gaveta")
    
    loadn r1, #CorpoCobra
    add r1, r1, r0             ; Acha o endereço da gaveta na memória
    loadi r1, r1               ; r1 = A coordenada real da tela!
    ; -----------------------------------------

    inchar r4
    loadn r7, #255
    cmp r7, r4
    jeq mantem_direcao         

    loadn r7, #'s'
    cmp r7, r4
    jeq validez_movimento_baixo

    loadn r7, #'d'
    cmp r7, r4
    jeq validez_movimento_direita

    loadn r7, #'w'
    cmp r7, r4
    jeq validez_movimento_cima

    loadn r7, #'a'
    cmp r7, r4
    jeq validez_movimento_esquerda
    
    jmp obter_movimento

    
aprova_movimento:
    store DirecaoMovimento, r4


mantem_direcao:
    load r2, DirecaoMovimento  
    
    loadn r7, #255
    cmp r2, r7
    jeq obter_movimento        

    loadn r7, #'s'
    cmp r2, r7
    jeq baixo
    
    loadn r7, #'d'
    cmp r2, r7
    jeq direita
    
    loadn r7, #'w'
    cmp r2, r7
    jeq cima
    
    loadn r7, #'a'
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
	loadn r1, #1021
	loadn r2, #3301
	loadn r3, #1200
    load r0, Semente
	mul r4, r0, r1
	add r4, r4, r2
	mod r4, r4, r3
    mov r0, r4
    store Semente, r0
	rts

atualizar_cobra:

    mov r7, r1
    ; ---  CHECA COLISÃO E MAÇÃ ---
    ; Lê o que tem na tela na posição para onde a cabeça quer ir
    loadn r0, #TelaJogo
    add r0, r0, r7
    loadi r0, r0          ; r0 = O que está na tela virtual?

    load r2, CorCobra
    cmp r0, r2
    jeq fim_de_jogo       ; Se for o próprio corpo ou uma parede, GAME OVER!
    load r2, CaracParede
    cmp r0, r2
    jeq fim_de_jogo

    load r2, CorMaca
    cmp r0, r2
    jne mover_rabo        ; Se NÃO for a maçã, vai mover o rabo.
    
    call rotina_comeu_maca
    jmp atualiza_cabeca   ; Pula o movimento do rabo (a cobra cresce na tela!)


    ; ---  APAGA O RABO ANTIGO ---
mover_rabo:
    load r0, RaboCobra      ; r0 = Índice atual do rabo
    
    loadn r2, #CorpoCobra
    add r2, r2, r0          ; r2 = Endereço do rabo no vetor
    loadi r2, r2            ; r2 = Coordenada da tela onde o rabo está

    ; Apaga do monitor físico
    loadn r3, #' '
    outchar r3, r2

    ; Apaga do Shadow Buffer (TelaJogo)
    loadn r4, #TelaJogo
    add r4, r4, r2
    storei r4, r3

    ; Avança o ponteiro circular do Rabo
    inc r0
    loadn r4, #1200
    cmp r0, r4
    jne salva_rabo
    loadn r0, #0
salva_rabo:
    store RaboCobra, r0

atualiza_cabeca:
    load r0, CabecaCobra    ; r0 = Índice atual da cabeça
    
    ; Avança o ponteiro circular da Cabeça
    inc r0
    loadn r4, #1200
    cmp r0, r4
    jne salva_cabeca
    loadn r0, #0
salva_cabeca:
    store CabecaCobra, r0

    ; Salva a nova coordenada dentro do vetor
    loadn r4, #CorpoCobra
    add r4, r4, r0
    storei r4, r7          ; CorpoCobra[NovoIndice] = r7 (Nova Coordenada)

    ; Desenha a nova cabeça na tela
    load r2, CorCobra
    outchar r2, r7          ; Pinta no monitor

    loadn r3, #TelaJogo
    add r3, r3, r7
    storei r3, r2           ; Pinta no Shadow Buffer

    rts




gerar_maca:
	call rand

    loadn r1, #TelaJogo
    add r1, r1, r0             ; r1 = TelaJogo + Coordenada Sorteada
    loadi r2, r1               ; r2 = Lê o que está na tela virtual
    
    loadn r3, #' '             ; Verifica se o espaço gerado está VAZIO
    cmp r2, r3                 
    jne gerar_maca             ; Se não estiver vazio, tenta de novo

	load r1, CorMaca
	outchar r1, r0

    loadn r2, #TelaJogo
    add r2, r2, r0
    storei r2, r1

    call adiciona_posicao_maca
	rts

inicializa_posicao_maca:

    loadn r0, #0
    loadn r1, #PosicaoMaca
    loadn r2, #1201
    load r3, MaxMaca

loop_inicializa_posicao_maca:
    add r4, r1, r0
    storei r4, r2 
    inc r0
    cmp r0, r3
    jne loop_inicializa_posicao_maca


    rts
    

adiciona_posicao_maca:
    loadn r1, #0
    loadn r2, #PosicaoMaca

loop_adiciona_posicao_maca:
    add r3, r2, r1
    loadi r4, r3
    inc r1
    loadn r5, #1201
    cmp r4, r5
    jne loop_adiciona_posicao_maca
    storei r3, r0
    rts


rotina_comeu_maca:
    load r0, QuantMaca    
    dec r0
    store QuantMaca, r0
    call remove_posicao_maca
    call aumenta_score
    rts

remove_posicao_maca:
    loadn r0, #0
    loadn r1, #PosicaoMaca
    load r5, MaxMaca         
    
loop_remove_posicao_maca:
    add r2, r1, r0
    loadi r3, r2
    
    cmp r3, r7              
    jeq achou_maca_remover   
    
    inc r0
    cmp r0, r5              
    jne loop_remove_posicao_maca
    rts                     

achou_maca_remover:
    loadn r4, #1201
    storei r2, r4            ;
    rts


atualizar_direcao:
    store DirecaoMovimento, r4
    rts

fim_de_jogo:
    loadn r0, #615         ; Posição central da tela
    
    loadn r1, #2887        ; Letra 'G'
    outchar r1, r0
    
    inc r0
    loadn r1, #2881        ; Letra 'A'
    outchar r1, r0

    inc r0
    loadn r1, #2893        ; Letra 'M'
    outchar r1, r0

    inc r0
    loadn r1, #2885        ; Letra 'E'
    outchar r1, r0

    inc r0
    inc r0                 ; Pula um espaço em branco

    loadn r1, #2895        ; Letra 'O'
    outchar r1, r0

    inc r0                 ; <--- Faltava isso!
    loadn r1, #2902        ; Letra 'V'
    outchar r1, r0

    inc r0                 ; <--- Faltava isso!
    loadn r1, #2885        ; Letra 'E'
    outchar r1, r0

    inc r0
    loadn r1, #2898        ; Letra 'R'
    outchar r1, r0

    loadn r0, #656

    loadn r1, #80
    outchar r1, r0

    inc r0
    loadn r1, #82  
    outchar r1, r0

    inc r0
    loadn r1, #69
    outchar r1, r0

    inc r0
    loadn r1, #83
    outchar r1, r0

    inc r0
    outchar r1, r0

    inc r0
    inc r0

    loadn r1, #2386
    outchar r1, r0

    call loop_restart
    call tenta_mudar_highscore
    jmp pergunta_dificuldade

loop_restart:
    inchar r4
    loadn r1, #'r'
    cmp r1, r4
    jne loop_restart
    call limpa_tela
    rts

limpa_tela:
    loadn r0, #0           
    loadn r1, #1200        
    loadn r2, #' '  
    loadn r3, #TelaJogo

loop_limpa_tela:
    storei r3, r2
    outchar r2, r0
    inc r0
    inc r3
    cmp r0, r1
    jne loop_limpa_tela
    rts


validez_movimento_direita:
    loadn r2, #'a'
    load r3, DirecaoMovimento
    cmp r2, r3
    jeq mantem_direcao
    jmp aprova_movimento

validez_movimento_esquerda:
    loadn r2, #'d'
    load r3, DirecaoMovimento
    cmp r2, r3
    jeq mantem_direcao
    jmp aprova_movimento

validez_movimento_cima:
    loadn r2, #'s'
    load r3, DirecaoMovimento
    cmp r2, r3
    jeq mantem_direcao
    jmp aprova_movimento

validez_movimento_baixo:
    loadn r2, #'w'
    load r3, DirecaoMovimento
    cmp r2, r3
    jeq mantem_direcao
    jmp aprova_movimento

delay:
    push r0
    push r1
    push r2
    
    ; r0 = Multiplicador (Ajuste a velocidade do jogo aqui)
    ; AUMENTE para deixar a cobra mais LENTA.
    ; DIMINUA para deixar a cobra mais RÁPIDA.
    load r0, Velocidade         
    
    loadn r2, #0
delay_loop_out:
    loadn r1, #30000       ; Loop interno de 3 mil ciclos
delay_loop_in:
    dec r1
    cmp r1, r2
    jne delay_loop_in      ; Fica girando aqui dentro atoa
    
    dec r0
    cmp r0, r2
    jne delay_loop_out     ; Repete o ciclo externo
    
    pop r2
    pop r1
    pop r0
    rts
gerar_paredes:
    loadn r0, #40
    loadn r1, #80
    load r2, CaracParede

loop_gerar_paredes_cima:
    ;--- Gera as paredes de cima e guarda no shadow buffer ---;
    outchar r2, r0
    loadn r3, #TelaJogo
    add r3, r3, r0
    storei r3, r2

    inc r0
    cmp r0, r1
    jne loop_gerar_paredes_cima

    loadn r0, #1160
    loadn r1, #1200

loop_gerar_paredes_baixo:
    outchar r2, r0

    loadn r3, #TelaJogo
    add r3, r3, r0
    storei r3, r2

    inc r0
    cmp r0, r1
    jne loop_gerar_paredes_baixo  


    rts 

tenta_gerar_maca:
    load r0, QuantMaca
    load r1, MaxMaca
    cmp r0, r1
    jeq fim_tenta_gerar_maca

    load r0, Tempo
    loadn r2, #0
    cmp r0, r2
    jne fim_tenta_gerar_maca
    
    call gerar_maca
    load r0, QuantMaca
    inc r0
    store QuantMaca, r0

fim_tenta_gerar_maca:
    rts

aumenta_tempo:
    load r0, Tempo
    inc r0
    store Tempo, r0

    loadn r1, #40
    cmp r0, r1
    jne fim_aumenta_tempo

    loadn r0, #0
    store Tempo, r0

fim_aumenta_tempo:
    rts

gerar_score:
    loadn r0, #15
    loadn r1, #'S'
    outchar r1, r0

    inc r0
    loadn r1, #'C'
    outchar r1, r0

    inc r0
    loadn r1, #'O'
    outchar r1, r0

    inc r0
    loadn r1, #'R'
    outchar r1, r0

    inc r0
    loadn r1, #'E'
    outchar r1, r0

    inc r0
    loadn r1, #':'
    outchar r1, r0

    inc r0
    loadn r1, #'0'
    outchar r1, r0

    loadn r2, #TelaJogo
    add r2, r2, r0
    storei r2, r1

    inc r0
    loadn r1, #'0'
    outchar r1, r0

    loadn r2, #TelaJogo
    add r2, r2, r0
    storei r2, r1

    inc r0
    loadn r1, #'0'
    outchar r1, r0

    loadn r2, #TelaJogo
    add r2, r2, r0
    storei r2, r1

    inc r0
    loadn r1, #'0'
    outchar r1, r0

    loadn r2, #TelaJogo
    add r2, r2, r0
    storei r2, r1

    rts

aumenta_score:
    call ajustar_unidade
    call ajustar_score_memoria
    rts


ajustar_unidade:
    loadn r0, #TelaJogo
    loadn r1, #24
    add r0, r0, r1
    loadi r2, r0

    loadn r3, #'9'
    cmp r2, r3
    jeq ajustar_dezena
    inc r2
    outchar r2, r1
    storei r0, r2
    rts
    

ajustar_dezena:
    loadn r2, #'0'
    outchar r2, r1
    storei r0, r2

    loadn r0, #TelaJogo
    loadn r1, #23
    add r0, r0, r1
    loadi r2, r0

    loadn r3, #'9'
    cmp r2, r3
    jeq ajustar_centena
    inc r2
    outchar r2, r1
    storei r0, r2
    rts

ajustar_centena:
    loadn r2, #'0'
    outchar r2, r1
    storei r0, r2

    loadn r0, #TelaJogo
    loadn r1, #22
    add r0, r0, r1
    loadi r2, r0

    loadn r3, #'9'
    cmp r2, r3
    jeq ajustar_milhar
    inc r2
    outchar r2, r1
    storei r0, r2
    rts

ajustar_milhar:
    loadn r2, #'0'
    outchar r2, r1
    storei r0, r2

    loadn r0, #TelaJogo
    loadn r1, #22
    add r0, r0, r1
    loadi r2, r0
    inc r2
    outchar r2, r1
    storei r0, r2
    rts

ajustar_score_memoria:
    load r0, CurScore
    inc r0
    store CurScore, r0

tenta_animar_maca:
    load r0, Tempo
    loadn r1, #10
    mod r2, r0, r1

    loadn r0, #0
    cmp r0, r2
    jeq anima_maca
    rts

anima_maca:
    load r0, CorMaca_A
    load r1, CorMaca
    load r2, CorMaca_B
    cmp r0, r1
    jeq muda_para_corb
    jmp muda_para_cora

muda_para_corb:
    store CorMaca, r2
    jmp atualiza_cor

muda_para_cora:
    store CorMaca, r0
    jmp atualiza_cor

atualiza_cor:
    loadn r0, #0
    load r1, MaxMaca
    loadn r2, #PosicaoMaca
    load r5, CorMaca
loop_atualiza_cor:
    add r3, r2, r0
    loadi r4, r3

    ; --- CORREÇÃO: CHECA SE A GAVETA ESTÁ VAZIA ---
    loadn r6, #1201
    cmp r4, r6
    jeq pula_desenho_maca    ; Se for 1201, pula o desenho!
    ; ----------------------------------------------

    outchar r5, r4
    loadn r6, #TelaJogo
    add r6, r6, r4
    storei r6, r5
    inc r0
    cmp r0, r1
    jne loop_atualiza_cor
    rts

pula_desenho_maca:           ; Ponto de aterrissagem do pulo
    inc r0
    cmp r0, r1
    jne loop_atualiza_cor
    rts

tenta_mudar_highscore:
    load r0, CurScore
    load r1, HighScore
    loadi r2, r1
    cmp r0, r2
    jgr muda_high_score
    rts

muda_high_score:
    storei r1, r0
    rts


gerar_highscore:
    loadn r0, #0
    loadn r1, #'H'
    outchar r1, r0

    inc r0
    loadn r1, #'I'
    outchar r1, r0

    inc r0
    loadn r1, #'-'
    outchar r1, r0

    inc r0
    loadn r1, #'S'
    outchar r1, r0

    inc r0
    loadn r1, #'C'
    outchar r1, r0

    inc r0
    loadn r1, #'O'
    outchar r1, r0

    inc r0
    loadn r1, #'R'
    outchar r1, r0

    inc r0
    loadn r1, #'E'
    outchar r1, r0

    inc r0
    loadn r1, #':'
    outchar r1, r0

    loadn r2, #4
    add r0, r0, r2

gerar_valor_highscore:
    loadn r1, #'0'

    load r4, HighScore
    loadi r4, r4
    loadn r5, #10
    mod r2, r4, r5 
    add r1, r1, r2
    outchar r1, r0

    dec r0
    div r4, r4, r5
    loadn r1, #'0'
    mod r2, r4, r5
    add r1, r1, r2
    outchar r1, r0

    dec r0
    div r4, r4, r5
    loadn r1, #'0'
    mod r2, r4, r5
    add r1, r1, r2
    outchar r1, r0

    dec r0
    div r4, r4, r5
    loadn r1, #'0'
    mod r2, r4, r5
    add r1, r1, r2
    outchar r1, r0

    rts



TelaJogo: var #1200     
CabecaCobra: var #1
static CabecaCobra, #0
RaboCobra: var #1
static RaboCobra, #0
CorpoCobra: var #1200
CorCobra: var #1        
static CorCobra, #637
DirecaoMovimento: var #1
static DirecaoMovimento, #255
Semente: var #1
static Semente, #42           
CorMaca: var #1
static CorMaca, #2368		
CaracParede: var #1
static CaracParede, #291
QuantMaca: var #1
static QuantMaca, #0
MaxMaca: var #1
static MaxMaca, #10
PosicaoMaca: var #10
CorMaca_A: var #1
static CorMaca_A, #2368
CorMaca_B: var #1
static CorMaca_B, #2858 
Tempo: var #1
static Tempo, #0
Velocidade: var #1
CurScore: var#1
static CurScore, #0
HighScoreEasy: var#1
static HighScoreEasy, #0
HighScoreMedium: var#1
static HighScoreMedium, #0
HighScoreHard: var#1
static HighScoreHard, #0
HighScore: var#1
