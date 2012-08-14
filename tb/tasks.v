/*
   
task write_reg();
    input  [31:0]   addr;
    input  [31:0]   data;
begin
    wait_clks(0);   // sync

    hsel    = 1'b1;
    haddr   = addr;
    hburst  = 3'd0;
    htrans  = 2'd0;
    hwrite  = 1'b1;
    hwdata  = data;
    wait (hready);  // wait for ready
    wait_clks(1);   // wait for the clock to change

    hsel    = 1'b0;
    hwrite  = 1'b0;
end
endtask


task read_reg();
    input  [31:0]   addr;
    output [31:0]   data;
begin
    wait_clks(0);   // sync

    hsel    = 1'b1;
    haddr   = addr;
    hburst  = 3'd0;
    htrans  = 2'd0;
    hwrite  = 1'b0;
    wait (hready);  // wait for ready
    wait_clks(1);   // wait for the clock to change
    data    = hrdata;

    hsel    = 1'b0;
    hwrite  = 1'b0;
end
endtask


task write_burst();
    input  [31:0]   addr;
    input  [ 2:0]   burst;
    input  [31:0]   data[7:0];
begin
end
endtask


task read_burst();
    input  [31:0]   addr;
    input  [ 2:0]   burst;
    output [31:0]   data[7:0];
begin
end
endtask

task check_reg();
    input  [31:0]   addr;
    input  [31:0]   expected;
    reg    [31:0]   data;
begin
    data = read_reg(.addr(addr));
    if (data != expected) begin
        $display("%t: Register mismatch, addr:%h, expected:%h != actual:%h\n",
                $time, addr, expected, data);
    end
end
endtask
*/
