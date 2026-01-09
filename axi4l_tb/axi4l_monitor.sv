


Class axil_monitor extends uvm_monitor#(axil_seq_item);

//Registering class to factory
`uvm_component_utils(axil_monitor)

//analysis port
uvm_analysis_port #(axil_seq_item) send_port;

//new constructor
function new(input string path="axil_monitor", uvm_component parent=null);

super.new(path,parent);

endfunction

//seq item obj handle
axil_seq_item aw_seq_item;
axil_seq_item w_seq_item;
axil_seq_item ar_seq_item;
axil_seq_item r_seq_item;
axil_seq_item b_seq_item;
axil_seq_item reset_seq_item;

//counter
int rvalid_wait_count = 1'b0;
int bvalid_wait_count = 1'b0;

//queue
bit [`ADDR_WIDTH-1 : 0] ar_queue[$], aw_queue[$];
bit [`DATA_WIDTH-1 : 0] w_queue[$];

//add handle to virtual interface
virtual axil_interface axil_if;

//uvm_Event
uvm_event queue_empty_event;

//build phase
virtual function void build_phase(uvm_phase phase);

//seq item obj created
ar_seq_item = axil_seq_item::type_id::create("ar_seq_item");
aw_seq_item = axil_seq_item::type_id::create("aw_seq_item");
w_seq_item = axil_seq_item::type_id::create("w_seq_item");
r_seq_item = axil_seq_item::type_id::create("r_seq_item");
b_seq_item = axil_seq_item::type_id::create("b_seq_item");
reset_seq_item = axil_seq_item::type_id::create("reset_seq_item");

//analysis port obj created
send_port = new("send_port", this);

//use config_db to set the interface
if(!uvm_config_db #(virtual axil_interface)::get(this,"","axil_if", axil_if))
`uvm_error("MON","unable to access axil_interface through config_db");


//event set using config_db
if(!uvm_config_db#(uvm_event)::get(this, "", "queue_empty", queue_empty_event))
`uvm_error("MON","Unable to access uvm_event through config_db");

endfunction

task send_ar_seq_item (uvm_phase phase);

@(posedge axil_if.clk iff axil_if.ARVALID & axil_if.ARREADY)
phase.raise_objection(this);
ar_queue.push_back(axil_if.ARADDR);
ar_seq_item.araddr = axil_if.ARADDR;
ar_seq_item.operation = AR;
send_port.write(ar_seq_item);

endtask

task send_aw_seq_item (uvm_phase phase);

@(posedge axil_if.clk iff axil_if.AWVALID & axil_if.AWREADY);
phase.raise_objection(this);
aw_queue.push_back(axil_if.AWADDR);
aw_seq_item.awaddr = axil_if.AWADDR;
aw_seq_item.operation = AR;
send_port.write(aw_seq_item);

endtask

task send_w_seq_item (uvm_phase phase);

@(posedge axil_if.clk iff axil_if.WVALID & axil_if.WREADY);
phase.raise_objection(this);
w_queue.push_back(axil_if.WDATA);
w_seq_item.wdata = axil_if.WDATA;
w_seq_item.wstrb = axil_if.WSTRB;
aw_seq_item.operation = W;
send_port.write(w_seq_item);

endtask

task send_r_seq_item (uvm_phase phase);

@(posedge axil_if.clk iff axil_if.RVALID & axil_if.RREADY);
if(ar_queue.size()==0 & !axil_if.ARVALID)
queue_empty_event.trigger();
r_seq_item.rdata = axil_if.RDATA;
r_seq_item.rresp = axil_if.RRESP;
r_seq_item.operation = R;
send_port.write(r_seq_item);
phase.drop_objection(this);

endtask

task send_b_seq_item (uvm_phase phase);

@(posedge axil_if.clk iff axil_if.BVALID & axil_if.BREADY);
if(aw_queue.size()==0 & w_queue.size() & !axil_if.AWVALID & !axil_if.WVALID)
queue_empty_event.trigger();
b_seq_item.bresp = axil_if.BRESP;
b_seq_item.operation = B;
send_port.write(b_seq_item);
phase.drop_objection(this);
phase.drop_objection(this);

endtask

task send_reset_seq_item (uvm_phase phase);

wait(axil_if.ARESETn==0);
reset_seq_item.operation = RESET;
disable arready_timeout_fork;
disable awready_timeout_fork;
disable wready_timeout_fork;
disable rvalid_timeout_fork;
disable bvalid_timeout_fork
ar_queue.delete();
aw_queue.delete();
w_queue.delete()
rvalid_wait_count = 1'b0;
bvalid_wait_count = 1'b0;
send_port.write(reset_seq_item);
@(posedge axil_if.ARESETn);
//how phase objection dropped??

endtask

task arready_timeout_counter();

@(posedge axil_if.ARVALID);
@(posedge axil_if.clk);
fork:arready_timeout_fork
begin
wait(axil_if.ARREADY);
end
begin
repeat(`RREADY_WAIT_THRESHOLD)@(posedge clk);
`uvm_fatal("ARREADY_TIMEOUT_ERR", "Timeout for ARREADY occured");
end
join
disable arready_timeout_fork;

endtask

task awready_timeout_counter();

@(posedge axil_if.AWVALID);
@(posedge axil_if.clk);
fork:awready_timeout_fork
begin
wait(axil_if.AWREADY);
end
begin
repeat(`READY_WAIT_THRESHOLD)@(posedge axil_if.clk);
`uvm_fatal("AWREADY_TIMEOUT_ERR", "Timeout for AWREADY occured");
end
join
disable awready_timeout_fork;

endtask

task wready_timeout_counter();

@(posedge axil_if.WVALID);
@(posedge axil_if.clk);
fork:wready_timeout_fork
begin
wait(axil_if.WREADY);
end
begin
repeat(`READY_WAIT_THRESHOLD)@(posedge axil_if.clk);
`uvm_fatal("WREADY_TIMEOUT_ERR", "Timeout for WREADY occured");
end
join
disable wready_timeout_fork;

endtask

task rvalid_timeout_counter();

wait(ar_queue.size());
rvalid_wait_count = 1'b0;
fork:rvalid_timeout_fork
begin
wait(axil.RVALID);
if(rvalid_wait_count<1)
`uvm_fatal("RVALID_ERR", "Orphan response recieved");
ar_queue.pop_front();
end
begin
while(rvalid_wait_count<=`RESP_WAIT_THRESHOLD) begin
@(posedge axil_if.clk);
rvalid_wait_count++;
if(rvalid_wait_count>`RESP_WAIT_THRESHOLD)
`uvm_fatal("RVALID_TIMEOUT_ERR", "Timeout for RVALID occured");
end

end
join_any

disable rvalid_timeout_fork;
//@(posedge axil_if.clk)
endtask

task bvalid_timeout_counter();

wait(aw_queue.size() & w_queue.size());
bvalid_wait_count = 1'b0;
fork:bvalid_timeout_fork
begin
wait(axil.BVALID);
if(bvalid_wait_count<1)
`uvm_fatal("BVALID_ERR", "Orphan response recieved");
aw_queue.pop_front();
w_queue.pop_front();
end
begin
while(bvalid_wait_count<=`RESP_WAIT_THRESHOLD) begin
@(posedge axil_if.clk);
bvalid_wait_count++;
if(bvalid_wait_count>`RESP_WAIT_THRESHOLD)
`uvm_fatal("BVALID_TIMEOUT_ERR", "Timeout for BVALID occured");
end

end
join_any

disable bvalid_timeout_fork;
//@(posedge axil_if.clk)
endtask

virtual task run_phase(uvm_phase phase);

fork
begin
forever begin
send_ar_seq_item(phase);
end
end
begin
forever begin
send_aw_seq_item(phase);
end
end
begin
forever begin
send_w_seq_item(phase);
end
end
begin
forever begin
send_r_seq_item(phase);
end
end
begin
forever begin
send_b_seq_item(phase);
end
end
begin
forever begin
send_reset_seq_item();
end
end
begin
forever begin
arready_timeout_counter();
end
end
begin
forever begin
awready_timeout_counter();
end
end
begin
forever begin
wready_timeout_counter();
end
end
begin
forever begin
rvalid_timeout_counter();
end
end
begin
forever begin
bvalid_timeout_counter();
end
end
join

endtask
