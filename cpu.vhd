-- Processador Versao 4: 06/08/2025
-- Video com 256 cores e tela de 40 colunas por 30 linhas

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.STD_LOGIC_UNSIGNED.all;

entity cpu is
   port (
      clk      : in  STD_LOGIC;
      reset    : in  STD_LOGIC;

      Mem      : in  STD_LOGIC_VECTOR(15 downto 0);
      M5       : out STD_LOGIC_VECTOR(15 downto 0);
      M1       : out STD_LOGIC_VECTOR(15 downto 0);
      RW       : out STD_LOGIC;

      key      : in  STD_LOGIC_VECTOR(7 downto 0);

      videoflag: out STD_LOGIC;
      vga_pos  : out STD_LOGIC_VECTOR(15 downto 0);
      vga_char : out STD_LOGIC_VECTOR(15 downto 0);

      Ponto    : out STD_LOGIC_VECTOR(2 downto 0);

      halt_ack : out STD_LOGIC;
      halt_req : in  STD_LOGIC;

      PC_data  : out STD_LOGIC_VECTOR(15 downto 0);
      break    : out STD_LOGIC
   );
end cpu;

ARCHITECTURE main of cpu is
   TYPE STATES        is (fetch, decode, exec, exec2, halted);                   -- Estados da Maquina de Controle do Processador
   TYPE Registers     is array(0 to 7) of STD_LOGIC_VECTOR(15 downto 0); -- Banco de Registradores
   TYPE LoadRegisters is array(0 to 7) of std_LOGIC;                     -- Sinais de LOAD dos Registradores do Banco

   -- INSTRUCTION SET: 29 INSTRUCTIONS
   -- Data Manipulation Instructions:                                    -- Usage          -- Action        -- Format
   CONSTANT LOAD      : STD_LOGIC_VECTOR(5 downto 0) := "110000";      -- LOAD RX END  -- RX <- M[END]  Format: < inst(6) | RX(3) | xxxxxxx >  + 16bit END
   CONSTANT STORE     : STD_LOGIC_VECTOR(5 downto 0) := "110001";      -- STORE END RX -- M[END] <- RX  Format: < inst(6) | RX(3) | xxxxxxx >  + 16bit END
   CONSTANT LOADIMED  : STD_LOGIC_VECTOR(5 downto 0) := "111000";      -- LOADN RX Nr   -- RX <- Nr       Format: < inst(6) | RX(3) | xxxxxxb0 >  + 16bit Numero
   CONSTANT LOADINDEX : STD_LOGIC_VECTOR(5 downto 0) := "111100";      -- LOADI RX RY   -- RX <- M[RY]   Format: < inst(6) | RX(3) | RY(3) | xxxx >
   CONSTANT STOREINDEX: STD_LOGIC_VECTOR(5 downto 0) := "111101";      -- STOREI RX RY  -- M[RX] <- RY   Format: < inst(6) | RX(3) | RY(3) | xxxx >
   CONSTANT MOV       : STD_LOGIC_VECTOR(5 downto 0) := "110011";      -- MOV RX RY    -- RX <- RY        Format: < inst(6) | RX(3) | RY(3) | xx | x0 >
                                                                        -- MOV RX SP    RX <- SP         Format: < inst(6) | RX(3) | xxx | xx | 01 >
                                                                        -- MOV SP RX    SP <- RX         Format: < inst(6) | RX(3) | xxx | xx | 11 >

   -- I/O Instructions:
   CONSTANT OUTCHAR   : STD_LOGIC_VECTOR(5 downto 0) := "110010";      -- OUTCHAR RX RY -- Video[RY] <- Char(RX)      Format: < inst(6) | RX(3) | RY(3) | xxxx >
   
   CONSTANT INCHAR      : STD_LOGIC_VECTOR(5 downto 0) := "110101";      -- INCHAR RX     -- RX[5..0] <- KeyPressed   RX[15..6] <- 0's     Format: < inst(6) | RX(3) | xxxxxxx >

   CONSTANT ARITH         : STD_LOGIC_VECTOR(1 downto 0) := "10";
   -- Aritmethic Instructions(All should begin wiht "10"):
   CONSTANT ADD         : STD_LOGIC_VECTOR(3 downto 0) := "0000";         -- ADD RX RY RZ / ADDC RX RY RZ     -- RX <- RY + RZ / RX <- RY + RZ + C     -- b0=CarRY             Format: < inst(6) | RX(3) | RY(3) | RZ(3)| C >
   CONSTANT SUB         : STD_LOGIC_VECTOR(3 downto 0) := "0001";         -- SUB RX RY RZ / SUBC RX RY RZ     -- RX <- RY - RZ / RX <- RY - RZ + C     -- b0=CarRY             Format: < inst(6) | RX(3) | RY(3) | RZ(3)| C >
   CONSTANT MULT          : STD_LOGIC_VECTOR(3 downto 0) := "0010";         -- MUL RX RY RZ  / MUL RX RY RZ      -- RX <- RY * RZ / RX <- RY * RZ + C     -- b0=CarRY            Format: < inst(6) | RX(3) | RY(3) | RZ(3)| C >
   CONSTANT DIV         : STD_LOGIC_VECTOR(3 downto 0) := "0011";         -- DIV RX RY RZ                      -- RX <- RY / RZ / RX <- RY / RZ + C     -- b0=CarRY            Format: < inst(6) | RX(3) | RY(3) | RZ(3)| C >
   CONSTANT INC         : STD_LOGIC_VECTOR(3 downto 0) := "0100";         -- INC RX / DEC RX                  -- RX <- RX + 1 / RX <- RX - 1           -- b6= INC/DEC : 0/1   Format: < inst(6) | RX(3) | b6 | xxxxxx >
   CONSTANT LMOD          : STD_LOGIC_VECTOR(3 downto 0) := "0101";         -- MOD RX RY RZ                      -- RX <- RY MOD RZ                                          Format: < inst(6) | RX(3) | RY(3) | RZ(3)| x >

   CONSTANT LOGIC         : STD_LOGIC_VECTOR(1 downto 0) := "01";
   -- LOGIC Instructions (All should begin wiht "01"):
   CONSTANT LAND         : STD_LOGIC_VECTOR(3 downto 0) := "0010";    -- AND RX RY RZ     -- RZ <- RX AND RY   Format: < inst(6) | RX(3) | RY(3) | RZ(3)| x >
   CONSTANT LOR         : STD_LOGIC_VECTOR(3 downto 0) := "0011";      -- OR RX RY RZ      -- RZ <- RX OR RY      Format: < inst(6) | RX(3) | RY(3) | RZ(3)| x >
   CONSTANT LXOR         : STD_LOGIC_VECTOR(3 downto 0) := "0100";    -- XOR RX RY RZ     -- RZ <- RX XOR RY   Format: < inst(6) | RX(3) | RY(3) | RZ(3)| x >
   CONSTANT LNOT         : STD_LOGIC_VECTOR(3 downto 0) := "0101";      -- NOT RX RY          -- RX <- NOT(RY)      Format: < inst(6) | RX(3) | RY(3) | xxxx >
   CONSTANT SHIFT         : STD_LOGIC_VECTOR(3 downto 0) := "0000";      -- SHIFTL0 RX,n / SHIFTL1 RX,n / SHIFTR0 RX,n / SHIFTR1 RX,n / ROTL RX,n / ROTR RX,n

   CONSTANT CMP         : STD_LOGIC_VECTOR(3 downto 0) := "0110";      -- CMP RX RY        -- Compare RX and RY and set FR :   Format: < inst(6) | RX(3) | RY(3) | xxxx >  Flag Register: <...DIVbyZero|StackUnderflow|StackOverflow|DIVByZero|ARITHmeticOverflow|carRY|zero|equal|lesser|greater>

   -- FLOW CONTROL Instructions:
   CONSTANT JMP         : STD_LOGIC_VECTOR(5 downto 0) := "000010";   -- JMP END    -- PC <- 16bit END                       : b9-b6 = COND      Format: < inst(6) | COND(4) | xxxxxx >   + 16bit END
   CONSTANT CALL         : STD_LOGIC_VECTOR(5 downto 0) := "000011";   -- CALL END   -- M[SP] <- PC | SP-- | PC <- 16bit END   : b9-b6 = COND        Format: < inst(6) | COND(4) | xxxxxx >   + 16bit END
   CONSTANT RTS         : STD_LOGIC_VECTOR(5 downto 0) := "000100";   -- RTS        -- SP++ | PC <- M[SP] | b6=RX/FR: 1/0                          Format: < inst(6) | xxxxxxxxxx >
   CONSTANT PUSH         : STD_LOGIC_VECTOR(5 downto 0) := "000101";   -- PUSH RX / PUSH FR  -- M[SP] <- RX / M[SP] <- FR | SP--     : b6=RX/FR: 0/1      Format: < inst(6) | RX(3) | b6 | xxxxxx >
   CONSTANT POP         : STD_LOGIC_VECTOR(5 downto 0) := "000110";   -- POP RX  / POP FR   -- SP++ | RX <- M[SP]  / FR <- M[SP]    : b6=RX/FR: 0/1      Format: < inst(6) | RX(3) | b6 | xxxxxx >

   -- Control Instructions:
   CONSTANT NOP         : STD_LOGIC_VECTOR(5 downto 0) := "000000";   -- NOP             -- Do Nothing                               Format: < inst(6) | xxxxxxxxxx >
   CONSTANT HALT         : STD_LOGIC_VECTOR(5 downto 0) := "001111";   -- HALT            -- StOP Here                              Format: < inst(6) | xxxxxxxxxx >
   CONSTANT SETC         : STD_LOGIC_VECTOR(5 downto 0) := "001000";   -- CLEARC / SETC  -- Set/Clear CarRY: b9 = 1-set; 0-clear   Format: < inst(6) | b9 | xxxxxxxxx >
   CONSTANT BREAKP      : STD_LOGIC_VECTOR(5 downto 0) := "001110";    -- BREAK POINT    -- Switch to manual clock                  Format: < inst(6) | xxxxxxxxxx >

   -- CONSTANTes para controle do Mux2: Estes sinais selecionam as respectivas entradas para o Mux2
   CONSTANT sULA      : STD_LOGIC_VECTOR (2 downto 0) := "000";
   CONSTANT sMem      : STD_LOGIC_VECTOR (2 downto 0) := "001";
   CONSTANT sM4      : STD_LOGIC_VECTOR (2 downto 0) := "010";
   CONSTANT sTECLADO   : STD_LOGIC_VECTOR (2 downto 0) := "011"; -- nao tinha
   CONSTANT sSP      : STD_LOGIC_VECTOR (2 downto 0) := "100";

   -- Sinais para o Processo da ULA
   signal OP            : STD_LOGIC_VECTOR(6 downto 0);   -- OP(6) deve ser setado para OPeracoes com carRY
   signal x, y, result   : STD_LOGIC_VECTOR(15 downto 0);
   signal FR            : STD_LOGIC_VECTOR(15 downto 0);   
   signal auxFR         : STD_LOGIC_VECTOR(15 downto 0);   


begin

-- Maquina de Controle
process(clk, reset)

   --Register Declaration:
   variable PC      : STD_LOGIC_VECTOR(15 downto 0);      -- Program Counter
   variable IR      : STD_LOGIC_VECTOR(15 downto 0);      -- Instruction Register
   variable SP      : STD_LOGIC_VECTOR(15 downto 0);      -- Stack Pointer
   variable MAR   : STD_LOGIC_VECTOR(15 downto 0);      -- Memory address Register
   VARIABLE   TECLADO   :STD_LOGIC_VECTOR(15 downto 0);      -- Registrador para receber dados do teclado 

   variable reg : Registers;

   -- Mux dos barramentos de dados internos
   VARIABLE   M2            :STD_LOGIC_VECTOR(15 downto 0);   
   VARIABLE M3, M4      :STD_LOGIC_VECTOR(15 downto 0);   
   VARIABLE   M6            :STD_LOGIC_VECTOR(15 downto 0);   

   -- Novos Sinais da Versao 2: Controle dos registradores internos (Load-Inc-Dec)
   variable LoadReg      : LoadRegisters;
   variable LoadIR      : std_LOGIC;
   variable LoadMAR      : std_LOGIC;
   variable LoadPC      : std_LOGIC;
   variable IncPC       : std_LOGIC;
   VARIABLE LoadSP      : STD_LOGIC;
   variable IncSP       : std_LOGIC;
   variable DecSP         : std_LOGIC;
   variable LoadFR      : std_LOGIC;

   -- Selecao dos Mux 2 e 6
   variable selM2       : STD_LOGIC_VECTOR(2 downto 0);
   variable selM6       : STD_LOGIC_VECTOR(2 downto 0);

   VARIABLE BreakFlag   : STD_LOGIC; 

   variable state : STATES; 

   -- Seletores dos registradores para execussao das instrucoes
   variable RX : integer;
   variable RY : integer;
   variable RZ : integer;


begin

   if(reset = '1') then

      state := fetch;      -- inicializa o estado na busca!
      M1(15 downto 0) <=   x"0000";  
      videoflag <= '0';

      RX := 0;
      RY := 0;
      RZ := 0;

      RW <= '0';

      LoadIR   := '0';
      LoadMAR   := '0';
      LoadPC   := '0';
      IncPC      := '0';
      IncSP      := '0';
      DecSP      := '0';
      LoadSP   := '0';
      LoadFR   := '0';
      selM2      := sMem;
      selM6      := sULA;

      LoadReg(0) := '0'; LoadReg(1) := '0'; LoadReg(2) := '0'; LoadReg(3) := '0';
      LoadReg(4) := '0'; LoadReg(5) := '0'; LoadReg(6) := '0'; LoadReg(7) := '0';

      REG(0)  := x"0000"; REG(1)  := x"0000"; REG(2)  := x"0000"; REG(3)  := x"0000";
      REG(4)  := x"0000"; REG(5)  := x"0000"; REG(6)  := x"0000"; REG(7)  := x"0000";

      PC := x"0000";  
      SP := x"7ffc";  
      IR := x"0000";
      MAR := x"0000";

      BreakFlag:= '0';   
      BREAK <= '0';    

      HALT_ack <= '0';

   elsif(clk'event and clk = '1') then

      if(LoadIR = '1')   then IR := Mem;             end if;
      if(LoadPC = '1')   then PC := Mem;             end if;
      if(IncPC = '1')    then PC := PC + x"0001";    end if;
      if(LoadMAR = '1')  then MAR := Mem;            end if;
      if(LoadSP = '1')   then SP := M4;              end if;
      if(IncSP = '1')    then SP := SP + x"0001";    end if;
      if(DecSP = '1')    then SP := SP - x"0001";    end if;

      if (selM6 = sULA) THEN M6 := auxFR;            
      ELSIF (selM6 = sMem) THEN M6 := Mem; END IF;   

      if(LoadFR = '1')    then FR <= M6;             end if;

      RX := conv_integer(IR(9 downto 7));
      RY := conv_integer(IR(6 downto 4));
      RZ := conv_integer(IR(3 downto 1));

      if (selM2 = sULA)       THEN M2 := RESULT;
      ELSIF (selM2 = sMem)    THEN M2 := Mem;
      ELSIF (selM2 = sM4)     THEN M2 := M4;
      ELSIF (selM2 = sTECLADO)THEN M2 := TECLADO;
      ELSIF (selM2 = sSP)     THEN M2 := SP;
      END IF;

      if(LoadReg(RX) = '1') then reg(RX) := M2; end if;

      LoadIR  := '0'; LoadMAR := '0'; LoadPC  := '0'; IncPC   := '0';
      IncSP   := '0'; DecSP   := '0'; LoadSP  := '0'; LoadFR  := '0';
      selM6   := sULA;   

      LoadReg(0) := '0'; LoadReg(1) := '0'; LoadReg(2) := '0'; LoadReg(3) := '0';
      LoadReg(4) := '0'; LoadReg(5) := '0'; LoadReg(6) := '0'; LoadReg(7) := '0';

      videoflag <= '0';   

      RW <= '0';  

      if(halt_req = '1') then state := halted; end if;

      PC_data <= PC;

      case state is
--************************************************************************
-- FETCH STATE
--************************************************************************
      when fetch =>
         PONTO <= "001";

         M1 <= PC;
         RW <= '0';
         LoadIR := '1';
         IncPC := '1';

         STATE := decode;

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--************************************************************************
-- DECODE STATE
--************************************************************************
      when decode =>
         PONTO <= "010";

--========================================================================
-- INCHAR           
--========================================================================
         IF(IR(15 DOWNTO 10) = INCHAR) THEN
            TECLADO(7 downto 0) := key(7 downto 0);
            TECLADO(15 downto 8) := X"00";
            selM2 := sTECLADO;
            LoadReg(RX) := '1';
            state := fetch;
         END IF;

--========================================================================
-- OUTCHAR         
--========================================================================
         IF(IR(15 DOWNTO 10) = OUTCHAR) THEN
            M3 := Reg(Rx);                      
            M4 := Reg(Ry);                      

            if M3(15 downto 8) = "00000000" then
               M3(15 downto 8) := "11111111";
            end if;

            vga_char <= M3; 
            vga_pos  <= M4;  
            videoflag <= '1';  
            state := fetch;
         END IF;

--========================================================================
-- LOAD Imediato          
--========================================================================
         IF(IR(15 DOWNTO 10) = LOADIMED) THEN
            M1 <= PC;            
            state := exec; -- Aguarda o operando vir da memoria no ciclo seguinte
         END IF;

--========================================================================
-- LOAD Direto           
--========================================================================
         IF(IR(15 DOWNTO 10) = LOAD) THEN 
            M1 <= PC;
            LoadMAR := '1'; -- Salva o endereço alvo no MAR
            IncPC := '1';
            state := exec;  
         END IF;

--========================================================================
-- STORE   DIReto         
--========================================================================
         IF(IR(15 DOWNTO 10) = STORE) THEN  
            M1 <= PC;
            LoadMAR := '1'; -- Salva o endereço alvo no MAR
            IncPC := '1';
            state := exec;  
         END IF;

--========================================================================
-- LOAD Indexado por registrador          
--========================================================================
         IF(IR(15 DOWNTO 10) = LOADINDEX) THEN
            state := exec; -- Pula para exec para usar a memoria
         END IF;

--========================================================================
-- STORE indexado por registrador          
--========================================================================
         IF(IR(15 DOWNTO 10) = STOREINDEX) THEN
            state := exec; -- Pula para exec para escrita segura
         END IF;

--========================================================================
-- MOV           
--========================================================================
         IF(IR(15 DOWNTO 10) = MOV) THEN
            if IR(1 downto 0) = "00" or IR(1 downto 0) = "10" then
               M4 := Reg(RY);
               selM2 := sM4;
               LoadReg(RX) := '1';
            elsif IR(1 downto 0) = "01" then
               selM2 := sSP;
               LoadReg(RX) := '1';
            elsif IR(1 downto 0) = "11" then
               M4 := Reg(RX);
               LoadSP := '1';
            end if;
            state := fetch;
         END IF;

--========================================================================
-- ARITH OPERATION ('INC' NOT INCLUDED)          
--========================================================================
         IF(IR(15 DOWNTO 14) = ARITH AND IR(13 DOWNTO 10) /= INC) THEN
            OP(6) <= IR(0);
            OP(5 downto 0) <= IR(15 downto 10);
            x <= Reg(RY);
            y <= Reg(RZ);
            state := exec; -- Avanca de ciclo para os sinais atingirem a ULA
         END IF;

--========================================================================
-- INC/DEC         
--========================================================================
         IF(IR(15 DOWNTO 14) = ARITH AND (IR(13 DOWNTO 10) = INC))   THEN
            OP(6) <= '0';
            OP(5 downto 4) <= ARITH;
            if IR(6) = '0' then OP(3 downto 0) <= ADD; else OP(3 downto 0) <= SUB; end if;
            x <= Reg(RX);
            y <= x"0001";
            state := exec;
         END IF;

--========================================================================
-- LOGIC OPERATION ('SHIFT', and 'CMP'  NOT INCLUDED)           
--========================================================================
         IF(IR(15 DOWNTO 14) = LOGIC AND IR(13 DOWNTO 10) /= SHIFT AND IR(13 DOWNTO 10) /= CMP) THEN 
				M3 := Reg(RY);
				M4 := Reg(RZ);
				
				x <= M3;
				y <= M4;
				
				
				OP(6) <= '0';
				OP(5 DOWNTO 0) <= IR(15 DOWNTO 10);
				
				selM2 := sULA;
				LoadReg(RX) := '1';
				
				state := fetch;
			END IF;	

--========================================================================
-- SHIFT      
--========================================================================
         IF(IR(15 DOWNTO 14) = LOGIC and (IR(13 DOWNTO 10) = SHIFT)) THEN
            if(IR(6 DOWNTO 4) = "000") then      
               Reg(RX) := To_StdLOGICVector(to_bitvector(Reg(RY))sll conv_integer(IR(3 DOWNTO 0)));
            elsif(IR(6 DOWNTO 4) = "001") then   
               Reg(RX) := not (To_StdLOGICVector(to_bitvector(not Reg(RY))sll conv_integer(IR(3 DOWNTO 0))));
            elsif(IR(6 DOWNTO 4) = "010") then   
               Reg(RX) := To_StdLOGICVector(to_bitvector(Reg(RY))srl conv_integer(IR(3 DOWNTO 0)));
            elsif(IR(6 DOWNTO 4) = "011") then   
               Reg(RX) := not (To_StdLOGICVector(to_bitvector(not Reg(RY))srl conv_integer(IR(3 DOWNTO 0))));
            elsif(IR(6 DOWNTO 5) = "11") then   
               Reg(RX) := To_StdLOGICVector(to_bitvector(Reg(RY))ror conv_integer(IR(3 DOWNTO 0)));
            elsif(IR(6 DOWNTO 5) = "10") then   
               Reg(RX) := To_StdLOGICVector(to_bitvector(Reg(RY))rol conv_integer(IR(3 DOWNTO 0)));
            end if;
            state := fetch;
         end if;

--========================================================================
-- CMP      
--========================================================================
         IF(IR(15 DOWNTO 14) = LOGIC AND IR(13 DOWNTO 10) = CMP) THEN
            OP(6) <= '0';
            OP(5 downto 0) <= IR(15 downto 10);
            x <= Reg(RX);
            y <= Reg(RY);
            state := exec;
         END IF;

--========================================================================
-- JMP END    
--========================================================================
         IF(IR(15 DOWNTO 10) = JMP) THEN
            IF((IR(9 DOWNTO 6) = "0000") OR
            ((IR(9 DOWNTO 6) = "0111") AND FR(0) = '1') OR
            ((IR(9 DOWNTO 6) = "1001") AND (FR(2) = '1' OR FR(0) = '1')) OR
            ((IR(9 DOWNTO 6) = "1000") AND FR(1) = '1') OR
            ((IR(9 DOWNTO 6) = "1010") AND (FR(2) = '1' OR FR(1) = '1')) OR
            ((IR(9 DOWNTO 6) = "0001") AND FR(2) = '1') OR
            ((IR(9 DOWNTO 6) = "0010") AND FR(2) = '0') OR
            ((IR(9 DOWNTO 6) = "0011") AND FR(3) = '1') OR
            ((IR(9 DOWNTO 6) = "0100") AND FR(3) = '0') OR
            ((IR(9 DOWNTO 6) = "0101") AND FR(4) = '1') OR
            ((IR(9 DOWNTO 6) = "0110") AND FR(4) = '0') OR
            ((IR(9 DOWNTO 6) = "1011") AND FR(5) = '1') OR
            ((IR(9 DOWNTO 6) = "1100") AND FR(5) = '0') OR
            ((IR(9 DOWNTO 6) = "1101") AND FR(6) = '1') OR
            ((IR(9 DOWNTO 6) = "1110") AND FR(9) = '1')) THEN
               M1 <= PC;            
               state := exec; 
            ELSE
               IncPC := '1';
               state := fetch;
            END IF;
         END IF;

--========================================================================
-- CALL END    
--========================================================================
         IF(IR(15 DOWNTO 10) = CALL) THEN
            IF((IR(9 DOWNTO 6) = "0000") OR
            ((IR(9 DOWNTO 6) = "0111") AND FR(0) = '1') OR
            ((IR(9 DOWNTO 6) = "1001") AND (FR(2) = '1' OR FR(0) = '1')) OR
            ((IR(9 DOWNTO 6) = "1000") AND FR(1) = '1') OR
            ((IR(9 DOWNTO 6) = "1010") AND (FR(2) = '1' OR FR(1) = '1')) OR
            ((IR(9 DOWNTO 6) = "0001") AND FR(2) = '1') OR
            ((IR(9 DOWNTO 6) = "0010") AND FR(2) = '0') OR
            ((IR(9 DOWNTO 6) = "0011") AND FR(3) = '1') OR
            ((IR(9 DOWNTO 6) = "0100") AND FR(3) = '0') OR
            ((IR(9 DOWNTO 6) = "0101") AND FR(4) = '1') OR
            ((IR(9 DOWNTO 6) = "0110") AND FR(4) = '0') OR
            ((IR(9 DOWNTO 6) = "1011") AND FR(5) = '1') OR
            ((IR(9 DOWNTO 6) = "1100") AND FR(5) = '0') OR
            ((IR(9 DOWNTO 6) = "1101") AND FR(6) = '1') OR
            ((IR(9 DOWNTO 6) = "1110") AND FR(9) = '1')) THEN
               M1 <= PC;
               LoadMAR := '1';
               IncPC := '1';
               state := exec;
            ELSE
               IncPC := '1';
               state := fetch;
            END IF;
         END IF;

--========================================================================
-- RTS          
--========================================================================
         IF(IR(15 DOWNTO 10) = RTS) THEN
            IncSP := '1';
            state := exec;
         END IF;

--========================================================================
-- PUSH RX
--========================================================================
         IF(IR(15 DOWNTO 10) = PUSH) THEN
            state := exec;
         END IF;

--========================================================================
-- POP RX
--========================================================================
         IF(IR(15 DOWNTO 10) = POP) THEN
            IncSP := '1';
            state := exec;
         END IF;

--========================================================================
-- NOP
--========================================================================
         IF( IR(15 DOWNTO 10) = NOP) THEN
            state := fetch;
         end if;

--========================================================================
-- HALT
--========================================================================
         IF( IR(15 DOWNTO 10) = HALT) THEN
            state := halted;
         END IF;

--========================================================================
-- SETC/CLEARC
--========================================================================
         IF( IR(15 DOWNTO 10) = SETC) THEN
            FR(4) <= IR(9);  
            state := fetch;
         end if;

--========================================================================
-- BREAKP
--========================================================================
         IF( IR(15 DOWNTO 10) = BREAKP) THEN
            BreakFlag := not(BreakFlag);  
            BREAK <= BreakFlag;
            state := fetch;
            PONTO <= "101";
         END IF;

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--************************************************************************
-- EXECUTE STATE
--************************************************************************

         when exec =>
            PONTO <= "100";

--========================================================================
-- EXEC LOADIMED
--========================================================================
         IF(IR(15 DOWNTO 10) = LOADIMED) THEN
            selM2 := sMem;       
            LoadReg(RX) := '1';   
            IncPC := '1';        
            state := fetch;
         END IF;

--========================================================================
-- EXEC LOAD DIReto           
--========================================================================
         IF(IR(15 DOWNTO 10) = LOAD) THEN
            M1 <= MAR;
            state := exec2;
         END IF;

--========================================================================
-- EXEC STORE DIReto          
--========================================================================
         IF(IR(15 DOWNTO 10) = STORE) THEN
            M1 <= MAR;
            M5 <= Reg(RX);
            RW <= '1';
            state := fetch;
         END IF;

--========================================================================
-- EXEC LOAD Indexado           
--========================================================================
         IF(IR(15 DOWNTO 10) = LOADINDEX) THEN
            M1 <= Reg(RY);
            state := exec2;
         END IF;

--========================================================================
-- EXEC STORE Indexado          
--========================================================================
         IF(IR(15 DOWNTO 10) = STOREINDEX) THEN
            M1 <= Reg(RX);
            M5 <= Reg(RY);
            RW <= '1';
            state := fetch;
         END IF;

--========================================================================
-- EXEC ULA (ARITH e INC/DEC)          
--========================================================================
         IF(IR(15 DOWNTO 14) = ARITH) THEN
            selM2 := sULA;
            LoadReg(RX) := '1';
            LoadFR := '1';
            state := fetch;
         END IF;

--========================================================================
-- EXEC ULA (LOGIC/CMP)          
--========================================================================
         IF(IR(15 DOWNTO 14) = LOGIC AND IR(13 DOWNTO 10) /= SHIFT) THEN
            IF(IR(13 DOWNTO 10) = CMP) THEN
               LoadFR := '1';
            ELSE
               selM2 := sULA;
               if IR(13 DOWNTO 10) = LNOT then
                  LoadReg(RX) := '1';
               else
                  LoadReg(RZ) := '1';
               end if;
               LoadFR := '1';
            END IF;
            state := fetch;
         END IF;

--========================================================================
-- EXEC JMP 
--========================================================================
         IF(IR(15 DOWNTO 10) = JMP) THEN
            LoadPC := '1';         
            state := fetch;
         END IF;

--========================================================================
-- EXEC CALL    
--========================================================================
         IF(IR(15 DOWNTO 10) = CALL) THEN
            M1 <= SP;
            M5 <= PC;
            RW <= '1';
            DecSP := '1';
            PC := MAR;
            state := fetch;
         END IF;

--========================================================================
-- EXEC RTS          
--========================================================================
         IF(IR(15 DOWNTO 10) = RTS) THEN
            M1 <= SP;
            state := exec2;
         END IF;

--========================================================================
-- EXEC PUSH 
--========================================================================
         IF(IR(15 DOWNTO 10) = PUSH) THEN
            M1 <= SP;
            if IR(6) = '0' then
               M5 <= Reg(RX);
            else
               M5 <= FR;
            end if;
            RW <= '1';
            DecSP := '1';
            state := fetch;
         END IF;

--========================================================================
-- EXEC POP RX/FR
--========================================================================
         IF(IR(15 DOWNTO 10) = POP) THEN
            M1 <= SP;
            state := exec2;
         END IF;

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--************************************************************************
-- EXECUTE2 STATE
--************************************************************************

         when exec2 =>
            PONTO <= "100";

--========================================================================
-- EXEC2 LOAD DIRETO E LOAD INDEXADO       
--========================================================================
         IF(IR(15 DOWNTO 10) = LOAD OR IR(15 DOWNTO 10) = LOADINDEX) THEN
            selM2 := sMem;
            LoadReg(RX) := '1';
            state := fetch;
         END IF;

--========================================================================
-- EXEC2 RTS          
--========================================================================
         IF(IR(15 DOWNTO 10) = RTS) THEN
            LoadPC := '1';
            state := fetch;
         END IF;

--========================================================================
-- EXEC2 POP          
--========================================================================
         IF(IR(15 DOWNTO 10) = POP) THEN
            if IR(6) = '0' then
               selM2 := sMem;
               LoadReg(RX) := '1';
            else
               selM6 := sMem;
               LoadFR := '1';
            end if;
            state := fetch;
         END IF;

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--************************************************************************
-- HALT STATE
--************************************************************************
      WHEN halted =>
         PONTO <= "111";
         state := halted;
         halt_ack <= '1';

      WHEN OTHERS =>
         state := fetch;
         videoflag <= '0';
         PONTO <= "000";

      END CASE;

   end if;
   end process;

--************************************************************************
-- ULA --->  3456  (3042)
--************************************************************************
PROCESS (OP, X, Y, reset)

   VARIABLE AUX      : STD_LOGIC_VECTOR(15 downto 0);
   VARIABLE RESULT32 : STD_LOGIC_VECTOR(31 downto 0);

BEGIN

   IF (reset = '1') THEN
      auxFR <= x"0000";
      RESULT <= x"0000";
   else
      auxFR <= FR;

      IF (OP (5 downto 4) = ARITH) THEN
         CASE OP (3 downto 0) IS
            WHEN ADD =>
               IF (OP(6) = '1') THEN 
                  AUX := X + Y + FR(4);
                  RESULT32 := (x"00000000" + X + Y + FR(4));
               ELSE  
                  AUX := X + Y;
                  RESULT32 := (x"00000000" + X + Y);
               end if;
               if(RESULT32 > "01111111111111111") THEN 
                  auxFR(4) <= '1';
               ELSE
                  auxFR(4) <= '0';
               end if;

            WHEN SUB =>
               AUX := X - Y;

            WHEN MULT =>
               RESULT32 := X * Y;
               AUX := RESULT32(15 downto 0);
               if(RESULT32 > x"0000FFFF") THEN 
                  auxFR(5) <= '1';
               ELSE
                  auxFR(5) <= '0';
               end if;

            WHEN DIV =>
               IF(Y = x"0000") THEN
                  AUX := x"0000";
                  auxFR(6) <= '1'; 
               ELSE
                  AUX := CONV_STD_LOGIC_VECTOR(CONV_INTEGER(X)/CONV_INTEGER(Y), 16);
                  auxFR(6) <= '0';
               END IF;
            WHEN LMOD =>
               IF(Y = x"0000") THEN
                  AUX := x"0000";
                  auxFR(6) <= '1'; 
               ELSE
                  AUX := CONV_STD_LOGIC_VECTOR(CONV_INTEGER(X) mod CONV_INTEGER(Y), 16);
                  auxFR(6) <= '0';
               END IF;
            WHEN others =>   
               AUX := X;
         END CASE;
         if(AUX = x"0000") THEN
            auxFR(3) <= '1';  
         ELSE
            auxFR(3) <= '0';  
         end if;
         if(AUX < x"0000") THEN   
            auxFR(9) <= '1';
         ELSE
            auxFR(9) <= '0';
         end if;
         RESULT <= AUX;

      ELSIF (OP (5 downto 4) = LOGIC) THEN
         IF (OP (3 downto 0) = CMP) THEN
            result <= x;
            IF (x > y) THEN
               auxFR(2 downto 0) <= "001"; 
            ELSIF (x < y) THEN
               auxFR(2 downto 0) <= "010"; 
            ELSIF (x = y) THEN
               auxFR(2 downto 0) <= "100"; 
            END IF;
         ELSE
            CASE OP (3 downto 0) IS
               WHEN LAND => result <= x and y;
               WHEN LXOR => result <= x xor y;
               WHEN LOR =>    result <= x or y;
               WHEN LNOT => result <= not x;
               WHEN others =>   
                  RESULT <= X;
            END CASE;
            if(result = x"0000") THEN
               auxFR(3) <= '1';  
            ELSE
               auxFR(3) <= '0';  
            end if;
         END IF;
      END IF;
   END IF; 
END PROCESS;
end main;