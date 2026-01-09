


interface axil_interface();

//clk
logic clk;
logic ARESETn;
   
    // Write Address Channel
    logic [`ADDR_WIDTH-1 : 0] AWADDR;
    logic         AWVALID;
    logic         AWREADY;
   
    // Write Data Channel
    logic [`DATA_WIDTH-1 : 0] WDATA;
    logic [`TOTAL_STRB_WIDTH-1 : 0]  WSTRB;
    logic         WVALID;
    logic         WREADY;
   
    // Write Response Channel
    logic [`TOTAL_RESP_WIDTH-1 : 0]  BRESP;
    logic         BVALID;
    logic         BREADY;
   
    // Read Address Channel
    logic [`ADDR_WIDTH-1 : 0]  ARADDR;
    logic         ARVALID;
    logic         ARREADY;
   
    // Read Data Channel
    logic [`DATA_WIDTH-1 : 0]  RDATA;
    logic [`TOTAL_RESP_WIDTH-1 : 0]  RRESP;
    logic         RVALID;
    logic         RREADY;
   
endinterface
