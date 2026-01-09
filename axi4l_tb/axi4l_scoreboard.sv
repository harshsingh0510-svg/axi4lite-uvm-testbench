


Class axil_scoreboard extends uvm_scoreboard#(axil_seq_item);

//registering class to factory
`uvm_component_utils(axil_scoreboard)

//uvm_analysis port implementaion
uvm_analysis_imp #(axil_seq_item, axil_scoreboard) recv_port;

//defining refrence memory, queues, counter variables
bit [`DATA_WIDTH-1 : 0] ref_memory [`MIN_VALID_ADDR:`MAX_VALID_ADDR];
bit [`TOTAL_RESP_WIDTH-1 : 0] rresp_queue [$];
bit [`TOTAL_RESP_WIDTH-1 : 0] bresp_queue [$];

typedef struct{
bit [`DATA_WIDTH-1 : 0] wdata,
bit [`TOTAL_STRB_WIDTH-1 : 0] wstrb
} data_strb;

bit [`ADDR_WIDTH-1 : 0] araddr_queue[$];
bit [`ADDR_WIDTH-1 : 0] awaddr_queue[$];
data_strb wdata_queue[$];

int ar_count=0;
int aw_count=0;
int w_count=0;
int rresp_count=0;
int bresp_count=0;

//handle of seq_item
axil_seq_item seq_item;

//new constructor
function new(input string path="axil_scoreboard", uvm_component parent=null);

super.new(path,parent);

endfunction

//build_phase
virtual function void build_phase(uvm_phase phase);

super.build_phase(phase);
//obj created
seq_item = axil_seq_item::type_id::create("seq_item");
recv_port = new("recv_port", this);

endfunction

//task verifying rresp and rdata comparison with refrence memory
function rd_resp_checker(axil_seq_item seq_item);

axil_seq_item rresp_seq_item = seq_item;

rresp_count++;
if(araddr_queue.size() > 0) begin

if(`MIN_VALID_ADDR < araddr_queue[0] < `MAX_VALID_ADDR) begin
if(rresp_seq_item.rdata != ref_memory[araddr_queue[0]] || rresp_seq_item.rresp != 1'b00) begin
`uvm_error("SCO", $sformatf("Incorrect rresp or rdata recieved for read operation on valid address,rdata recieved:%0d, rresp recieved:%0d, reference memory data at %0d is :%0d",rresp_seq_item.rdata, rresp_seq_item.rresp, araddr_queue[0], ref_memory[araddr_queue[0]]));
araddr_queue.pop_front();
end
end
else begin
if(rresp_seq_item.rresp != 1'b10) begin
`uvm_error("SCO", $sformatf("Incorrect rresp recieved for read operation on invalid address:rresp recieved:%0d", rresp_seq_item.rresp));
araddr_queue.pop_front();
end
end
end
else begin
`uvm_fatal("SCO","Orphan read response recieved");
end

endfunction

function wr_resp_checker(axil_seq_item seq_item);

axil_seq_item bresp_seq_item=seq_item;
bresp_count++;
if(awaddr_queue.size() & wdata_queue.size()) begin

if(`MIN_VALID_ADDR<awaddr_queue[0]<`MAX_VALID_ADDR) begin
if(bresp_seq_item.bresp==1'b00) begin
for(i=0;i<`TOTAL_STRB_WIDTH;i++) begin
if(wdata_queue[0].wstrb[i]) begin
ref_memory[awaddr_queue[0]][(i*8+7):(i*8)]=wdata_queue[0].wdata[(i*8+7):(i*8)];
end
end
awaddr_queue.pop_front();
wdata_queue.pop_front();
end
else begin
`uvm_error("SCO", $sformatf("Incorrect bresp recieved for write on valid address:write response recieved=%0d, write address=%0d, write data=%0d and strb=%0d", bresp_seq_item.bresp, awaddr_queue[0], wdata_queue[0].wdata, wdata_queue[0].wstrb));\

end
end
else begin
if(bresp_seq_item.bresp !=1'b10) begin
`uvm_error("SCO", $sformatf("Incorrect bresp recieved for write on invalid address:bresp recieved:%0d", bresp_seq_item.bresp));
awaddr_queue.pop_front();
wdata_queue.pop_front();
end
end
end
else begin
`uvm_fatal("SCO","Orphan write response recieved");
end
endfunction


virtual function void write(input axil_seq_item seq_item);

case(seq_item.operation)
AR: begin
araddr_queue.push_back(seq_item.araddr);
ar_count++;
end

AW: begin
awaddr_queue.push_back(seq_item.awaddr);
aw_count++;
end

W: begin
data_strb item='{seq_item.wdata, seq_item.wstrb};
wdata_queue.push_back(item)
w_count++;
end

R: begin
rd_resp_checker(seq_item);
end

B: begin
wr_resp_checker(seq_item);
end

Reset: begin
araddr_queue.delete();
awaddr_queue.delete();
wdata_queue.delete();
ref_memory = '{default:0};
end

endcase

endfunction

endclass
