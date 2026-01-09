


class axil_seq extends uvm_sequence#(axil_seq_item);

`uvm_object_utils(axil_seq)

axil_seq_item seq_item;

function new(input string path="axil_seq");
super.new(path);
endfunction

task body();
start_item(seq_item);
seq_item.randomize();
finish_item(seq_item);
endtask

endclass
