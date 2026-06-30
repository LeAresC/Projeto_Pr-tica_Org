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
