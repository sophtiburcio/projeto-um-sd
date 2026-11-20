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
