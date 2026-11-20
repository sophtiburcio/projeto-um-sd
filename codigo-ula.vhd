-- =========
-- ULA's Code
-- =========

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

-- ========
-- entity Main's Code
-- ========

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top-level entity integrating the FSM, Debouncer, and ALU
entity main is
    Port ( bit0      : in  STD_LOGIC; -- Shared DIP switch bit 0
           bit1      : in  STD_LOGIC; -- Shared DIP switch bit 1
           bit2      : in  STD_LOGIC; -- Shared DIP switch bit 2
           bit3      : in  STD_LOGIC; -- Shared DIP switch bit 3
           clk_50MHz : in  STD_LOGIC; -- Board clock input
           btn_step  : in  STD_LOGIC; -- Step button to trigger FSM state transition
           led0, led1, led2, led3 : out STD_LOGIC; -- LEDs for 4-bit ALU result
           led4, led5, led6, led7 : out STD_LOGIC);-- LEDs for ALU flags (Z, N, C, V)
end main;

architecture Behavioral of main is

    -- Component Declaration: Debouncer
    component debouncer is
        Port ( clk_50MHz : in  STD_LOGIC;
               button    : in  STD_LOGIC;
               clean_clk : out STD_LOGIC);
    end component;

    -- Component Declaration: ALU
    component ula is
        Port ( reg_A      : in  STD_LOGIC_VECTOR (3 downto 0);
               reg_B      : in  STD_LOGIC_VECTOR (3 downto 0);
               reg_opcode : in  STD_LOGIC_VECTOR (2 downto 0);
               alu_result : out STD_LOGIC_VECTOR (3 downto 0);
               flag_Z     : out STD_LOGIC;
               flag_N     : out STD_LOGIC;
               flag_C     : out STD_LOGIC;
               flag_V     : out STD_LOGIC);
    end component;

    -- Internal Signals
    signal clean_clock : STD_LOGIC;

    -- FSM State Definitions
    type state_type is (S_LOAD_OPCODE, S_LOAD_A, S_LOAD_B, S_SHOW_RESULT);
    signal current_state : state_type := S_LOAD_OPCODE;

    -- Registered Inputs
    signal reg_opcode : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal reg_A      : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal reg_B      : STD_LOGIC_VECTOR(3 downto 0) := "0000";

    -- ALU Output Connections
    signal res_ula    : STD_LOGIC_VECTOR(3 downto 0);
    signal z_ula, n_ula, c_ula, v_ula : STD_LOGIC;

    signal input_vec  : STD_LOGIC_VECTOR(3 downto 0);

begin

    -- Group physical switch inputs into a 4-bit vector
    input_vec <= bit3 & bit2 & bit1 & bit0;

    -- Instantiate Debouncer module
    Filtro_Botao: debouncer PORT MAP (
        clk_50MHz => clk_50MHz,
        button    => btn_step,
        clean_clk => clean_clock
    );

    -- Instantiate ALU module
    Minha_ULA: ula PORT MAP (
        reg_A      => reg_A,
        reg_B      => reg_B,
        reg_opcode => reg_opcode,
        alu_result => res_ula,
        flag_Z     => z_ula,
        flag_N     => n_ula,
        flag_C     => c_ula,
        flag_V     => v_ula
    );

    -- Finite State Machine (FSM) clocked by the debounced step button
    process(clean_clock)
    begin
        if rising_edge(clean_clock) then
            case current_state is
                when S_LOAD_OPCODE =>
                    reg_opcode <= input_vec(2 downto 0); -- Capture opcode from switches
                    current_state <= S_LOAD_A;
                    
                when S_LOAD_A =>
                    reg_A <= input_vec;                 -- Capture Operand A from switches
                    current_state <= S_LOAD_B;
                    
                when S_LOAD_B =>
                    reg_B <= input_vec;                 -- Capture Operand B from switches
                    current_state <= S_SHOW_RESULT;
                    
                when S_SHOW_RESULT =>
                    current_state <= S_LOAD_OPCODE;     -- Loop back to sequence start
            end case;
        end if;
    end process;

    -- Map ALU Result to LEDs (led0 to led3)
    led0 <= res_ula(0);
    led1 <= res_ula(1);
    led2 <= res_ula(2);
    led3 <= res_ula(3);

    -- Map Status Flags to LEDs (led4 to led7)
    led4 <= z_ula; -- Zero Flag
    led5 <= n_ula; -- Negative Flag
    led6 <= c_ula; -- Carry Flag
    led7 <= v_ula; -- Overflow Flag

end Behavioral;

-- ======
-- entity debouncer's Code
-- ======

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Push-button debouncer circuit (filters mechanical switch noise over ~20ms at 50MHz)
entity debouncer is
    Port ( clk_50MHz : in  STD_LOGIC;  -- 50MHz system clock input
           button    : in  STD_LOGIC;  -- Raw button signal input
           clean_clk : out STD_LOGIC); -- Debounced output signal
end debouncer;

architecture Behavioral of debouncer is
    -- 1,000,000 clock cycles @ 50MHz = 20ms debounce period
    signal counter   : integer range 0 to 1_000_000 := 0;
    signal btn_state : STD_LOGIC := '0';
begin
    process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
            -- If button state changes, start counting to filter bounce noise
            if button /= btn_state then
                counter <= counter + 1;
                if counter = 1_000_000 then
                    btn_state <= button;
                    counter <= 0;
                end if;
            else
                counter <= 0; -- Reset counter if button state remains stable
            end if;
        end if;
    end process;

    clean_clk <= btn_state;
end Behavioral;

-- =====
-- Pin's Code
-- ======

# Pin Mapping Constraints for Spartan-3E FPGA Board

# DIP Switch Inputs
NET "bit0" LOC = V8;
NET "bit1" LOC = U10;
NET "bit2" LOC = U8;
NET "bit3" LOC = T9;

# LED Outputs (Result & Flags)
NET "led0" LOC = R20; # Result Bit 0
NET "led1" LOC = T19; # Result Bit 1
NET "led2" LOC = U20; # Result Bit 2
NET "led3" LOC = U19; # Result Bit 3
NET "led4" LOC = V19; # Flag Z (Zero)
NET "led5" LOC = V20; # Flag N (Negative)
NET "led6" LOC = Y22; # Flag C (Carry)
NET "led7" LOC = W21; # Flag V (Overflow)

# Clock and Push-button Inputs
NET "clk_50MHz" LOC = E12; # 50MHz On-Board Oscillator
NET "btn_step"  LOC = U15; # Step Button for FSM Advancement


