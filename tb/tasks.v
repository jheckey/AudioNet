task wait_hclks;
    input  [31:0]   clocks;
    reg    [31:0]   cnt;
begin
    cnt = 0;
    wait (hclk == 0);
    while (cnt < clocks)  begin
        wait (hclk == 1);
        wait (hclk == 0);
        cnt = cnt+1;
    end
end
endtask

task write_reg;
    input  [31:0]   addr;
    input  [31:0]   data;
begin
    wait_hclks(0);   // sync
    //$display("synced");

    hsel    = 1'b1;
    haddr   = addr;
    hburst  = 3'd0;
    htrans  = 2'b10;
    hwrite  = 1'b1;
    hwdata  = data;
    //$display("wait for ready");
    wait (hready);  // wait for ready
    //$display("ready");
    wait_hclks(1);   // wait for the clock to change

    hsel    = 1'b0;
    hwrite  = 1'b0;
    htrans  = 2'b00;
    //$display("cleared");
    wait_hclks(1);   // wait for the clock to change
end
endtask


task read_reg;
    input  [31:0]   addr;
    output [31:0]   data;
begin
    wait_hclks(0);   // sync

    hsel    = 1'b1;
    haddr   = addr;
    hburst  = 3'd0;
    htrans  = 2'b10;
    hwrite  = 1'b0;
    wait (hready);  // wait for ready
    wait_hclks(1);   // wait for the clock to change
    data    = hrdata;

    hsel    = 1'b0;
    hwrite  = 1'b0;
    htrans  = 2'b00;
end
endtask


/*
task write_burst;
    input  [31:0]   addr;
    input  [ 2:0]   burst;
    input  [31:0]   data[7:0];
begin
end
endtask


task read_burst;
    input  [31:0]   addr;
    input  [ 2:0]   burst;
    output [31:0]   data[7:0];
begin
end
endtask

task check_reg;
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
