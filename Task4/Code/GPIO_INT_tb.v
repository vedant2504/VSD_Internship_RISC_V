`timescale 1ns/1ps

module tb_gpio_int;

parameter WIDTH = 8;

reg clk;
reg rst_n;

reg we;
reg re;
reg [7:0] addr;
reg [31:0] wdata;
wire [31:0] rdata;

reg  [WIDTH-1:0] gpio_in;
wire [WIDTH-1:0] gpio_out;
wire [WIDTH-1:0] gpio_oe;

wire irq;

gpio_int #(.WIDTH(WIDTH)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .we(we),
    .re(re),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata),
    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oe(gpio_oe),
    .irq(irq)
);
always #5 clk = ~clk;   // 100 MHz

task write_reg;
input [7:0] a;
input [31:0] d;
begin
    @(posedge clk);
    addr  <= a;
    wdata <= d;
    we    <= 1;
    re    <= 0;
    @(posedge clk);
    we    <= 0;
end
endtask
task read_reg;
input [7:0] a;
begin
    @(posedge clk);
    addr <= a;
    re   <= 1;
    we   <= 0;
    @(posedge clk);
    re   <= 0;
end
endtask
initial begin
    $dumpfile("gpio_int.vcd");
    $dumpvars(0, tb_gpio_int);

    clk = 0;
    rst_n = 0;
    we = 0;
    re = 0;
    addr = 0;
    wdata = 0;
    gpio_in = 0;
    #20;
    rst_n = 1;
    #20;
    $display("Test1: GPIO_DIR");
    write_reg(8'h00, 32'h01);
    $display("Test2: GPIO_OUT write");
    write_reg(8'h04, 32'h01);
    $display("Test3: GPIO_SET");
    write_reg(8'h0C, 32'h02);  // set bit1
    $display("Test4: GPIO_CLR");
    write_reg(8'h10, 32'h01);  // clear bit0

    $display("Test5: GPIO_TOGGLE");
    write_reg(8'h14, 32'h02);  // toggle bit1
    $display("Test6: Interrupt Enable");
    write_reg(8'h18, 32'h01);
    $display("Test7: Generate rising edge");

    #20;
    gpio_in[0] = 0;
    #20;
    gpio_in[0] = 1;   // Rising edge
    #40;

    if (irq)
        $display("PASS: IRQ asserted");
    else
        $display("FAIL: IRQ not asserted");
    read_reg(8'h1C);
    #10;
    $display("INT_STATUS = %h", rdata);
    $display("Test9: Clear interrupt");
    write_reg(8'h1C, 32'h01);
    #20;

    if (!irq)
        $display("PASS: IRQ cleared");
    else
        $display("FAIL: IRQ still active");
    #50;
    $display("Simulation Completed");
    $finish;
end
endmodule
