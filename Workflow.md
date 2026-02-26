wr_en			Write mode enable
addr_config[7:0]	Used to configure the dictionary. Selects the dict entry where data_config is stored
data_config[19:0]	Stores the huffman code corresponding to the value of addr_config in the dictionary

code_table[addr_config]	This is the dict table. Read only during encoding


logic[19:0] code_table [255:0]	Has 256 Entries and has 2 columns (code_length(4bits), code_bits(16bits))
For Each symbol, code_table[symbol] = {code_length, code_bits}