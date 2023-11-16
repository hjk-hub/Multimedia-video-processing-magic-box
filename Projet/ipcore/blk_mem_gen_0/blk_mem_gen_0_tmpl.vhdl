-- Created by IP Generator (Version 2022.1 build 99559)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT blk_mem_gen_0
  PORT (
    wr_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_addr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    rd_addr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    wr_en : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    rd_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : blk_mem_gen_0
  PORT MAP (
    wr_data => wr_data,
    wr_addr => wr_addr,
    rd_addr => rd_addr,
    wr_clk => wr_clk,
    rd_clk => rd_clk,
    wr_en => wr_en,
    rst => rst,
    rd_data => rd_data
  );
