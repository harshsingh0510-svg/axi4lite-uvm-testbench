


class axil_seq_item extends uvm_sequence_item;

typedef enum {
AR, AW, W, R, B, RESET
} operation_e;

rand operation_e operation;
randc bit [`ADDR_WIDTH-1 :0] araddr;
randc bit [`ADDR_WIDTH-1 :0] awaddr;
rand bit [`DATA_WIDTH-1 :0] wdata;
rand bit [`TOTAL_STRB_WIDTH-1:0] wstrb;
bit [`DATA_WIDTH-1 :0] rdata;
bit [`TOTAL_RESP_WIDTH-1:0] rresp;
bit [`TOTAL_RESP_WIDTH-1:0] bresp;
bit master_back_pressure=1'b0;
rand bit invalid_addr=1'b0;

function new(input string path="axil_seq_item");
super.new(path);
endfunction

constraint addr_range_c {
if (invalid_addr== 1'b0) {
araddr inside {[`MIN_VALID_ADDR:`MAX_VALID_ADDR]};
awaddr inside {[`MIN_VALID_ADDR:`MAX_VALID_ADDR]};
}
else {
!(araddr inside {[`MIN_VALID_ADDR:`MAX_VALID_ADDR]});
!(awaddr inside {[`MIN_VALID_ADDR:`MAX_VALID_ADDR]});
}
}

constraint operation_no_rst_c {
operation dist {AR :=`READ_OP_WEIGHT, AW :=`WRITE_OP_WEIGHT, W :=`WRITE_OP_WEIGHT};

}

constraint operation_with_rst_c {
operation dist {AR :=`READ_OP_WEIGHT, AW :=`WRITE_OP_WEIGHT, W :=`WRITE_OP_WEIGHT, R :=`RESET_OP_WEIGHT};

}

constraint invalid_addr_c {
invalid_addr dist {0 :=`VALID_ADDR_WEIGHT, 1 :=`INVALID_ADDR_WEIGHT};
}

`uvm_object_utils_begin(axil_seq_item)
`uvm_field_enum (operation_e, operation, UVM_DEFAULT)
`uvm_field_int (araddr, UVM_DEFAULT)
`uvm_field_int (awaddr, UVM_DEFAULT)
`uvm_field_int (wdata, UVM_DEFAULT)
`uvm_field_int (wstrb, UVM_DEFAULT)
`uvm_field_int (rdata, UVM_DEFAULT)
`uvm_field_int (rresp, UVM_DEFAULT)
`uvm_field_int (bresp, UVM_DEFAULT)
`uvm_field_int (master_back_pressure, UVM_DEFAULT)
`uvm_field_int (invalid_addr, UVM_DEFAULT)
`uvm_object_utils_end

endclass
