


Class axil_driver extends uvm_driver#(axil_seq_item);

//Registering class to factory
`uvm_component_utils(axil_driver)

//Defining variables
rand int arvalid_delay;
rand int awvalid_delay;
rand int wvalid_delay;
rand int rready_delay;
rand int bready_delay;
rand int reset_delay;
bit ar_master_back_pressure=1'b0;
bit aw_master_back_pressure=1'b0;
bit w_master_back_pressure=1'b0;

semaphore ar_sem;
semaphore aw_sem;
sempahore w_sem;

//Defining constraints
constraint ar_delay_c {

if(ar_master_back_pressure==1'b0){

arvalid_delay dist {0 :=`ARVALID_NO_DELAY_WEIGHT, [1:`READY_WAIT_THRESHOLD] :=`ARVALID_WITH_DELAY_WEIGHT };
}
}

constraint aw_delay_c{

if(aw_master_back_pressure==1'b0){

awvalid_delay dist {0 :=`AWVALID_NO_DELAY_WEIGHT, [1:`READY_WAIT_THRESHOLD] :=`AWVALID_WITH_DELAY_WEIGHT };
}
}

constraint w_delay_c{

if(w_master_back_pressure==1'b0){

wvalid_delay dist {0 :=`WVALID_NO_DELAY_WEIGHT, [1:`READY_WAIT_THRESHOLD] :=`WVALID_WITH_DELAY_WEIGHT };
}
}

constraint r_delay_c{

rready_delay dist {0 :=`RREADY_NO_DELAY_WEIGHT, [1:`RESP_WAIT_THRESHOLD] :=`RREADY_WITH_DELAY_WEIGHT };
}

constraint b_delay_c{

bready_delay dist {0 :=`BREADY_NO_DELAY_WEIGHT, [1:`RESP_WAIT_THRESHOLD] :=`BREADY_WITH_DELAY_WEIGHT };
}

/*constraint reset_delay_c{
reset_delay dist {0 :=`RESET_NO_DELAY_WEIGHT, [1:9] :=`RESET_WITH_DELAY_WEIGHT };
}*/

//seq item handle
axil_seq_item seq_item;
axil_seq_item ar_seq_item;
axil_seq_item aw_seq_item;
axil_seq_item w_seq_item;

//handle for virtual interface
virtual axil_interface axil_if;

//new constructor
function new(input string path="axil_driver", uvm_component parent=null);

super.new(path,parent);

endfunction

//Build phase
virtual function void build_phase(uvm_phase phase);
//obj created
seq_item = axil_seq_item::type_id::create("seq_item");
ar_seq_item = axil_seq_item::type_id::create("ar_seq_item");
aw_seq_item = axil_seq_item::type_id::create("aw_seq_item");
w_seq_item = axil_seq_item::type_id::create("w-seq_item");
ar_sem = new(1);
aw_sem = new(1);
w_sem = new(1);
//use config_db to get the interface
if(!uvm_config_db #(virtual axil_interface)::get(this,"","axil_if", axil_if))
`uvm_error("DRV","unable to access axil_interface through config_db");

endfunction

//task for rready assertion
task assert_rready();

forever begin

this.randomize(rready_delay);
repeat(rready_delay)@(posedge axil_if.clk);
axil_if.RREADY <= 1'b1;
this.randomize(rready_delay);
repeat(rready_delay)@(posedge axil_if.clk);
axil_if.RREADY <= 1'b0;

end

endtask

//task for bready assertion
task assert_bready();

forever begin

this.randomize(bready_delay);
repeat(bready_delay)@(posedge axil_if.clk);
axil_if.BREADY <= 1'b1;
this.randomize(bready_delay);
repeat(bready_delay)@(posedge axil_if.clk);
axil_if.BREADY <= 1'b0;

end

endtask

//task for sending read address to DUT
task ar_op (uvm_phase phase, axil_seq_item seq_item);

phase.raise_objection(this);
ar_sem.get();
ar_seq_item.copy(seq_item);

ar_fork:fork

begin

wait(axil_if.ARESETn == 1'b0);
axil_if.ARVALID <= 1'b0;
ar_sem.put();
phase.drop_objection(this);
disable ar_fork;
end

begin

ar_master_back_pressure = ar_seq_item.master_back_pressure;
this.randomize(ar_delay);
repeat(ar_delay)@(posedge axil_if.clk);
axil_if.ARVALID <= 1'b1;
axil_if.ARADDR <= ar_seq_item.araddr;
@(posedge axil_if.clk iff (axil_if.ARVALID & axil_if.ARREADY));
axil_if.ARVALID <= 1'b0;
@(posedge axil_if.clk);
ar_sem.put();
phase.drop_objection(this);
disable ar_fork;

end

join_none

seq_item_port.item_done();

endtask

//Task for sending write address to DUT
task aw_op (uvm_phase phase, axil_seq_item seq_item);

phase.raise_objection(this);
aw_sem.get();
aw_seq_item.copy(seq_item);

aw_fork:fork

begin

wait(axil_if.ARESETn == 1'b0);
axil_if.AWVALID <= 1'b0;
aw_sem.put();
phase.drop_objection(this);
disable aw_fork
end

begin

aw_master_back_pressure = aw_seq_item.master_back_pressure;
this.randomize(aw_delay);
repeat(aw_delay)@(posedge axil_if.clk);
axil_if.AWVALID <= 1'b1;
axil_if.AWADDR <= aw_seq_item.awaddr;
@(posedge axil_if.clk iff (axil_if.AWVALID & axil_if.AWREADY));
axil_if.AWVALID <= 1'b0;
@(posedge axil_if.clk);
aw_sem.put();
phase.drop_objection(this);
disable aw_fork;

end

join_none

seq_item_port.item_done();

endtask

//Task for sending write data and strb to DUT  
task w_op (uvm_phase phase, axil_seq_item seq_item);

phase.raise_objection(this);
w_sem.get();
w_seq_item.copy(seq_item);

w_fork:fork

begin

wait(axil_if.ARESETn == 1'b0);
axil_if.WVALID <= 1'b0;
w_sem.put();
phase.drop_objection(this);
disable w_fork
end

begin

w_master_back_pressure=w_seq_item.master_back_pressure;
this.randomize(w_delay);
repeat(w_delay)@(posedge axil_if.clk);
axil_if.WVALID <= 1'b1;
axil_if.WDATA <= w_seq_item.wdata;
@(posedge axil_if.clk iff (axil_if.WVALID & axil_if.WREADY));
axil_if.WVALID <= 1'b0;
@(posedge axil_if.clk);
w_sem.put();
phase.drop_objection(this);
disable w_fork;

end

join_none

seq_item_port.item_done();

endtask

//Task for reset operation
task rst_op(uvm_phase phase);

phase.raise_objection(this);
/*this.randomize(reset_delay);
#reset_delay;*/
axil_if.ARESETn <= 1'b0;
@(posedge axil_if.clk);
axil_if.ARESETn <= 1'b1;
@(posedge axil_if.clk);
seq_item_port.item_done();
phase.drop_objection(this);

endtask

//Run_phase
virtual task run_phase(uvm_phase phase);

fork

begin

assert_rready();

end

begin

assert_bready();

end

join_none

forever begin

seq_item_port.get_next_item(seq_item);

case (seq_item.operation)

AR: ar_op(phase, seq_item);

AW: aw_op(phase, seq_item);

W: w_op(phase, seq_item);

RESET: rst_op(phase);

endcase

end

endtask
