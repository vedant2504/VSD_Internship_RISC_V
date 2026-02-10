module gpio_int #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,

    input  wire             we,
    input  wire             re,
    input  wire [7:0]       addr,
    input  wire [31:0]      wdata,
    output reg  [31:0]      rdata,

    input  wire [WIDTH-1:0] gpio_in,
    output reg  [WIDTH-1:0] gpio_out,
    output wire [WIDTH-1:0] gpio_oe,

    output wire irq
);

reg [WIDTH-1:0] dir;
reg [WIDTH-1:0] int_en;
reg [WIDTH-1:0] int_status;
reg [WIDTH-1:0] sync1, sync2;
always @(posedge clk) begin
    sync1 <= gpio_in;
    sync2 <= sync1;
end

wire [WIDTH-1:0] gpio_in_sync = sync2;
reg [WIDTH-1:0] prev_in;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        prev_in <= 0;
    else
        prev_in <= gpio_in_sync;
end
wire [WIDTH-1:0] rising_edge = gpio_in_sync & ~prev_in;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        int_status <= 0;
    else
        int_status <= int_status | rising_edge;
end
assign irq = |(int_status & int_en);
assign gpio_oe = dir;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dir      <= 0;
        gpio_out <= 0;
        int_en   <= 0;
    end
    else if (we) begin
        case (addr)
        8'h00: dir <= wdata[WIDTH-1:0];
        8'h04: gpio_out <= wdata[WIDTH-1:0];
        8'h0C: gpio_out <= gpio_out | wdata[WIDTH-1:0];
        8'h10: gpio_out <= gpio_out & ~wdata[WIDTH-1:0];
        8'h14: gpio_out <= gpio_out ^ wdata[WIDTH-1:0];
        8'h18: int_en <= wdata[WIDTH-1:0];
        8'h1C: int_status <= int_status & ~wdata[WIDTH-1:0]; // W1C
        endcase
    end
end
always @(*) begin
    case (addr)
    8'h00: rdata = dir;
    8'h04: rdata = gpio_out;
    8'h08: rdata = gpio_in_sync;
    8'h18: rdata = int_en;
    8'h1C: rdata = int_status;
    default: rdata = 0;
    endcase
end
endmodule
