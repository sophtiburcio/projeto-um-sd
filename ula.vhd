library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- 4-bit Arithmetic Logic Unit (ALU) with 8 operations and 4 status flags
entity ula is
    Port ( reg_A      : in  STD_LOGIC_VECTOR (3 downto 0); -- 4-bit Input Operand A
           reg_B      : in  STD_LOGIC_VECTOR (3 downto 0); -- 4-bit Input Operand B
           reg_opcode : in  STD_LOGIC_VECTOR (2 downto 0); -- 3-bit Operation Code
           alu_result : out STD_LOGIC_VECTOR (3 downto 0); -- 4-bit ALU Output
           flag_Z     : out STD_LOGIC;                      -- Zero Flag
           flag_N     : out STD_LOGIC;                      -- Negative Flag
           flag_C     : out STD_LOGIC;                      -- Carry Out Flag
           flag_V     : out STD_LOGIC);                     -- Overflow Flag
end ula;

architecture Behavioral of ula is
begin
    process(reg_A, reg_B, reg_opcode)
        variable ext_A        : unsigned(4 downto 0);
        variable ext_B        : unsigned(4 downto 0);
        variable ext_SUM      : unsigned(4 downto 0);
        variable res_tmp      : STD_LOGIC_VECTOR(3 downto 0);
        variable carry_tmp    : STD_LOGIC;
        variable overflow_tmp : STD_LOGIC;
    begin
        -- Reset temporary flags for each process execution
        carry_tmp := '0';
        overflow_tmp := '0';
        
        -- Zero-extend operands to 5 bits to calculate Carry/Borrow correctly
        ext_A := unsigned('0' & reg_A);
        ext_B := unsigned('0' & reg_B);

        case reg_opcode is
            when "000" => -- 1. Addition (A + B)
                ext_SUM := ext_A + ext_B;
                res_tmp := std_logic_vector(ext_SUM(3 downto 0));
                carry_tmp := ext_SUM(4);
                -- Overflow occurs when adding two numbers of the same sign results in a different sign
                if (reg_A(3) = reg_B(3)) and (reg_A(3) /= ext_SUM(3)) then
                    overflow_tmp := '1';
                end if;

            when "001" => -- 2. Subtraction (A - B)
                ext_SUM := ext_A - ext_B;
                res_tmp := std_logic_vector(ext_SUM(3 downto 0));
                carry_tmp := ext_SUM(4);
                -- Overflow occurs when subtracting numbers of different signs produces an incorrect sign bit
                if (reg_A(3) /= reg_B(3)) and (reg_A(3) /= ext_SUM(3)) then
                    overflow_tmp := '1';
                end if;

            when "010" => -- 3. Bitwise AND
                res_tmp := reg_A and reg_B;

            when "011" => -- 4. Bitwise OR
                res_tmp := reg_A or reg_B;

            when "100" => -- 5. Bitwise XOR
                res_tmp := reg_A xor reg_B;

            when "101" => -- 6. Bitwise NOT (Invert Operand A)
                res_tmp := not reg_A;

            when "110" => -- 7. Increment (A + 1)
                ext_SUM := ext_A + 1;
                res_tmp := std_logic_vector(ext_SUM(3 downto 0));
                carry_tmp := ext_SUM(4);
                if (reg_A(3) = '0') and (ext_SUM(3) = '1') then
                    overflow_tmp := '1';
                end if;

            when "111" => -- 8. Logical Shift Left (A << 1)
                res_tmp := reg_A(2 downto 0) & '0';
                carry_tmp := reg_A(3); -- MSB shifted out becomes Carry

            when others =>
                res_tmp := "0000";
        end case;

        -- Assign outputs
        alu_result <= res_tmp;
        flag_C <= carry_tmp;
        flag_V <= overflow_tmp;
        
        -- Zero Flag: '1' if result is 0000, '0' otherwise
        if res_tmp = "0000" then
            flag_Z <= '1';
        else
            flag_Z <= '0';
        end if;
        
        -- Negative Flag: takes the value of the Most Significant Bit (MSB)
        flag_N <= res_tmp(3);
    end process;
end Behavioral;
