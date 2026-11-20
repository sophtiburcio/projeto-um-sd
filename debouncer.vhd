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
