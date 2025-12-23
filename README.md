# Mini FSM RAM em Verilog

Projeto pessoal de estudo em Verilog: uma máquina de estados finitos (FSM) que lê 4 bytes de uma RAM de 8 bits e monta duas palavras de 16 bits em outra RAM. A ideia é reproduzir, em versão reduzida, um cenário comum em sistemas digitais: um bloco de controle que coordena o fluxo de dados entre memórias com larguras e profundidades diferentes.

---

## Objetivo

- RAM_IN: 4 posições de 8 bits.  
- RAM_OUT: 2 posições de 16 bits.  
- A FSM deve:
  - Ler `byte0` e `byte1` da RAM_IN e gravar `{byte1, byte0}` na posição 0 da RAM_OUT.  
  - Ler `byte2` e `byte3` da RAM_IN e gravar `{byte3, byte2}` na posição 1 da RAM_OUT.  
  - Usar `start` para iniciar e `done` para indicar que as duas palavras já foram geradas.

---

## Organização do projeto
rtl/
ram_minima.v
mini_top_fsm.v

tb/
tb_top_minimo.v

img/
wave_fsm.jpg
transcript_fsm.jpg

## Módulo `ram_minima` (RAM simples)

RAM parametrizável usada como RAM_IN e RAM_OUT.

**Parâmetros**

- `WIDTH`: largura dos dados (8 ou 16 bits).  
- `DEPTH`: número de posições.  
- `DEPTH_LOG`: largura do endereço (log2(DEPTH)).

**Comportamento**

- Escrita síncrona em `posedge clk` quando `we = 1`.  
- Leitura assíncrona:
  assign data_rd = ram[addr_rd];
  
Instâncias típicas:

- RAM_IN: `WIDTH = 8`, `DEPTH = 4`.  
- RAM_OUT: `WIDTH = 16`, `DEPTH = 2`.

---

## Módulo `mini_top_fsm`

FSM responsável por coordenar a leitura da RAM_IN e a escrita da RAM_OUT.

**Interface principal**

- Entradas:
- `clk`, `rst_n`, `start`.
- `ram_in_we`, `ram_in_addr_wr`, `ram_in_data_wr` (quando a RAM_IN é preenchida “por fora” pelo testbench).
- `ram_in_data_rd`: dado lido da RAM_IN.

- Saídas:
- `ram_in_addr_rd`: endereço de leitura da RAM_IN.
- `ram_out_we`: enable de escrita da RAM_OUT.
- `ram_out_addr_wr`: endereço de escrita (0 ou 1).
- `ram_out_data_wr`: palavra de 16 bits montada.
- `done`: indica que as duas palavras já foram gravadas.

**Estados (one-hot)**

- `IDLE`  
- `READ0`  
- `READ1`  
- `WRITE0`  
- `READ2`  
- `READ3`  
- `WRITE1`

**Fluxo**

1. `IDLE`: espera `start`.  
2. `READ0` / `READ1`: lê bytes dos endereços 0 e 1, armazenando em `byte0_buf` e `byte1_buf`.  
3. `WRITE0`: grava `{byte1_buf, byte0_buf}` em `RAM_OUT[0]`.  
4. `READ2` / `READ3`: lê bytes dos endereços 2 e 3.  
5. `WRITE1`: grava `{byte1_buf, byte0_buf}` em `RAM_OUT[1]` e ativa `done`.  

Buffers internos:

- `byte0_buf`: primeiro byte do par.  
- `byte1_buf`: segundo byte do par.

---

## Testbench `tb_top_minimo`

O testbench exerce o papel de “ambiente de teste” para a FSM.

**Funções principais**

- Gera `clk` e `rst_n`.  
- Preenche a RAM_IN via portas de escrita:
- `ram_in_we`, `addr_wr`, `data_wr`.  
- Aplica um pulso de `start`.  
- Espera o sinal `done`.  
- Monitora as escritas na RAM_OUT.

**Exemplo de estímulo**

// escreve 4 bytes na RAM_IN
for (i = 0; i < 4; i = i + 1) begin
write_data(i[1:0], $random);
end

// pulso de start
@(posedge clk);
start = 1;
@(posedge clk);
start = 0;

// espera done e mais alguns ciclos
wait (done);
#10 $stop;

Monitor das escritas na RAM_OUT:

always @(posedge clk) begin
if (ram_out_we)
$display("RAM_OUT[%0d] = 0x%04h", ram_out_addr_wr, ram_out_data_wr);
end

---

## Resultados de simulação

Exemplo de dados escritos na RAM_IN:

- endereço 0 → `0x24`  
- endereço 1 → `0x81`  
- endereço 2 → `0x09`  
- endereço 3 → `0x63`

Saídas observadas na RAM_OUT:

- `RAM_OUT[0] = 0x8124`  
- `RAM_OUT[1] = 0x6309`  

A figura abaixo mostra a waveform da FSM lendo os 4 bytes da RAM_IN
e escrevendo as duas palavras de 16 bits na RAM_OUT:

![Waveform da FSM](img/wave_fsm.jpg)

Já a figura seguinte mostra o transcript da simulação (Questa/ModelSim),
com as mensagens de `$display` indicando os dados escritos na RAM_IN e nas
duas posições da RAM_OUT:

![Transcript da simulação](img/transcript_fsm.jpg)







