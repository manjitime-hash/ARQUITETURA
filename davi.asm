.data
    arquivo_entrada: .asciiz "lista.txt"
    arquivo_saida: .asciiz "lista_ordenada.txt"
    buffer: .space 1024   # 1kb
    .align 2
    arrayNumeros: .space 400
    tamanho: .word 0
    
    msg_abertura_erro: .asciiz "Erro ao abrir arquivo!\n"
    msg_leitura_erro: .asciiz "Erro ao ler arquivo!\n"
    msg_escrita_erro: .asciiz "Erro ao criar arquivo de saida!\n"
    msg_sucesso: .asciiz "Arquivo ordenado salvo com sucesso!\n"
    debug_qtd: .asciiz "Numeros encontrados: "

.text
.globl main

main:
    
    li $v0, 13            #abrir arquivo se der erro -1 ou n 
    la $a0, arquivo_entrada
    li $a1, 0	    # sinal pro sistema cod ler
    syscall
    move $s0, $v0
    bltz $s0, erro_abertura

    # ler arquivo
    li $v0, 14             # erro -1 se não n 
    move $a0, $s0
    la $a1, buffer
    li $a2, 1024            #limite 
    syscall
    move $s1, $v0 	 # salvar quantidade de bytes lidos
    bltz $s1, erro_leitura

    # fechar arquivo de entrada
    li $v0, 16
    move $a0, $s0
    syscall

    # processar buffer 
    la $s0, buffer
    add $s1, $s0, $s1  # fim do buffer (último byte lido + 1)
    la $s2, arrayNumeros
    li $s3, 0          # contador de números
    li $s4, 0          # número atual
    li $s5, 1          # Sinal: 1=positivo, -1=negativo

processar_caracteres:   
    bge $s0, $s1, fim_processamento  # Se chegou ao fim do buffer , tem um loop iniciado em linha 77
    
    lb $t0, 0($s0)
    addi $s0, $s0, 1
    
    # Verificar se é vírgula
    li $t1, 44
    beq $t0, $t1, armazenar_numero
    
    # Verificar se é negativo
    li $t1, 45
    beq $t0, $t1, set_negativo
    
    # Verificar se é dígito (0-9)
    li $t1, 48
    blt $t0, $t1, caractere_invalido
    li $t1, 57
    bgt $t0, $t1, caractere_invalido
    
    # É um dígito - converter e acumular
    sub $t0, $t0, 48     # 48 inicio do ascii 
    mul $s4, $s4, 10
    add $s4, $s4, $t0
    j processar_caracteres

set_negativo:
    li $s5, -1
    j processar_caracteres

caractere_invalido:
    # Se não for vírgula, dígito ou sinal, ignora
    j processar_caracteres

armazenar_numero:
    # Aplica sinal e armazena
    mul $s4, $s4, $s5
    sw $s4, 0($s2)
    addi $s2, $s2, 4
    addi $s3, $s3, 1
    
    # Reset para próximo número
    li $s4, 0
    li $s5, 1
    j processar_caracteres

fim_processamento:
    # Armazenar último número (se houver)
    beqz $s3, sem_numeros
    mul $s4, $s4, $s5
    sw $s4, 0($s2)
    addi $s3, $s3, 1

sem_numeros:
    sw $s3, tamanho

    # Debug
    li $v0, 4
    la $a0, debug_qtd
    syscall
    li $v0, 1
    lw $a0, tamanho
    syscall
    li $v0, 11
    li $a0, 10
    syscall

    # Bubble Sort
    lw $t0, tamanho
    ble $t0, 1, pular_ordenacao
    
    addi $t1, $t0, -1  # n-1
    li $t2, 0          # i

bubble_outer:
    la $t3, arrayNumeros
    li $t4, 0          # j
    li $t5, 0          # trocou = false

bubble_inner:
    lw $t6, 0($t3)     # array[j]
    lw $t7, 4($t3)     # array[j+1]
    
    ble $t6, $t7, no_swap
    
    # Troca
    sw $t7, 0($t3)
    sw $t6, 4($t3)
    li $t5, 1          # trocou = true

no_swap:
    addi $t3, $t3, 4
    addi $t4, $t4, 1
    blt $t4, $t1, bubble_inner

    beqz $t5, pular_ordenacao
    addi $t2, $t2, 1
    blt $t2, $t1, bubble_outer

pular_ordenacao:
    # Escrever arquivo de saída
    li $v0, 13
    la $a0, arquivo_saida
    li $a1, 1    
    syscall
    move $s0, $v0
    bltz $s0, erro_escrita

    # Preparar conteúdo
    la $s1, arrayNumeros
    lw $s2, tamanho
    la $s3, buffer
    li $s4, 0          #set
    li $s5, 0          # índice atual

escrever_numeros:
    bge $s5, $s2, fim_escrita
    
    lw $a0, 0($s1)
    move $a1, $s3
    move $a2, $s4
    jal int_para_string
    move $s4, $v0
    
    # Adicionar vírgula se não for último
    addi $s5, $s5, 1
    bge $s5, $s2, sem_virgula
    
    add $t0, $s3, $s4
    li $t1, 44
    sb $t1, 0($t0)
    addi $s4, $s4, 1

sem_virgula:
    addi $s1, $s1, 4
    j escrever_numeros

fim_escrita:
    # Escrever buffer no arquivo
    li $v0, 15
    move $a0, $s0
    la $a1, buffer
    move $a2, $s4
    syscall
    
    # Fechar arquivo
    li $v0, 16
    move $a0, $s0
    syscall
    
    li $v0, 4
    la $a0, msg_sucesso
    syscall
    
    j exit

# Função int_para_string CORRIGIDA
int_para_string:
    # $a0 = número, $a1 = buffer, $a2 = set
    move $t0, $a0
    add $t1, $a1, $a2  # $t1 = posição atual no buffer
    
    # Tratar zero
    bnez $t0, nao_zero
    li $t2, 48
    sb $t2, 0($t1)
    addi $v0, $a2, 1
    jr $ra

nao_zero:
    # Verificar negativo
    li $t8, 0          # flag de negativo
    bgez $t0, positivo_str
    li $t8, 1
    sub $t0, $zero, $t0
    li $t2, 45
    sb $t2, 0($t1)
    addi $t1, $t1, 1

positivo_str:
    # Contar dígitos
    li $t3, 0          # contador de dígitos
    move $t4, $t0
contar_digitos:
    addi $t3, $t3, 1
    div $t4, $t4, 10
    bnez $t4, contar_digitos
    
    # $t3 = número de dígitos
    add $t1, $t1, $t3  # vai para o final do número
    move $t4, $t0
    li $t5, 10
    
escrever_digitos:
    addi $t1, $t1, -1
    div $t4, $t5
    mfhi $t6           # dígito
    mflo $t4           # resto
    addi $t6, $t6, 48
    sb $t6, 0($t1)
    bnez $t4, escrever_digitos
    
    # Calcular tamanho total
    add $v0, $a2, $t3
    add $v0, $v0, $t8  # adiciona 1 se for negativo
    jr $ra

erro_abertura:
    li $v0, 4
    la $a0, msg_abertura_erro
    syscall
    j exit

erro_leitura:
    li $v0, 4
    la $a0, msg_leitura_erro
    syscall
    j exit

erro_escrita:
    li $v0, 4
    la $a0, msg_escrita_erro
    syscall

exit:
    li $v0, 10
    syscall
