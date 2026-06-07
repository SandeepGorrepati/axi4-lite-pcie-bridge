`timescale 1ns/1ps

// Icarus-friendly AXI4-Lite protocol checker.
// Checks protocol intent without relying on concurrent SVA property syntax.
module axi_protocol_checker (
    input logic        clk,
    input logic        rst,

    input logic [31:0] s_axi_awaddr,
    input logic        s_axi_awvalid,
    input logic        s_axi_awready,
    input logic [31:0] s_axi_wdata,
    input logic [3:0]  s_axi_wstrb,
    input logic        s_axi_wvalid,
    input logic        s_axi_wready,
    input logic [1:0]  s_axi_bresp,
    input logic        s_axi_bvalid,
    input logic        s_axi_bready,

    input logic [31:0] s_axi_araddr,
    input logic        s_axi_arvalid,
    input logic        s_axi_arready,
    input logic [31:0] s_axi_rdata,
    input logic [1:0]  s_axi_rresp,
    input logic        s_axi_rvalid,
    input logic        s_axi_rready
);

    integer pass_count;
    integer fail_count;
    integer accepted_write_count;
    integer accepted_read_count;
    integer bresp_count;
    integer rresp_count;

    logic pending_write;
    logic pending_read;
    integer write_latency;
    integer read_latency;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pass_count           <= 0;
            fail_count           <= 0;
            accepted_write_count <= 0;
            accepted_read_count  <= 0;
            bresp_count          <= 0;
            rresp_count          <= 0;
            pending_write        <= 1'b0;
            pending_read         <= 1'b0;
            write_latency        <= 0;
            read_latency         <= 0;
        end else begin
            // Known-value checks during valid phases.
            if (s_axi_awvalid) begin
                if (!$isunknown(s_axi_awaddr)) pass_count <= pass_count + 1;
                else begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: AWADDR X/Z while AWVALID at time %0t", $time);
                end
            end

            if (s_axi_wvalid) begin
                if (!$isunknown(s_axi_wdata) && !$isunknown(s_axi_wstrb)) pass_count <= pass_count + 1;
                else begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: WDATA/WSTRB X/Z while WVALID at time %0t", $time);
                end
            end

            if (s_axi_arvalid) begin
                if (!$isunknown(s_axi_araddr)) pass_count <= pass_count + 1;
                else begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: ARADDR X/Z while ARVALID at time %0t", $time);
                end
            end

            // Accepted write transaction: simplified design accepts AW and W together.
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                accepted_write_count <= accepted_write_count + 1;
                if (pending_write) begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: new write accepted while previous write response is pending at time %0t", $time);
                end else begin
                    pass_count <= pass_count + 1;
                end
                pending_write <= 1'b1;
                write_latency <= 0;
            end else if (pending_write && !s_axi_bvalid) begin
                write_latency <= write_latency + 1;
                if (write_latency >= 16) begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: BVALID not seen within 16 cycles after write accept at time %0t", $time);
                    pending_write <= 1'b0;
                    write_latency <= 0;
                end
            end

            // Accepted read transaction.
            if (s_axi_arvalid && s_axi_arready) begin
                accepted_read_count <= accepted_read_count + 1;
                if (pending_read) begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: new read accepted while previous read response is pending at time %0t", $time);
                end else begin
                    pass_count <= pass_count + 1;
                end
                pending_read <= 1'b1;
                read_latency <= 0;
            end else if (pending_read && !s_axi_rvalid) begin
                read_latency <= read_latency + 1;
                if (read_latency >= 16) begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: RVALID not seen within 16 cycles after read accept at time %0t", $time);
                    pending_read <= 1'b0;
                    read_latency <= 0;
                end
            end

            // Write response must correspond to a pending write.
            if (s_axi_bvalid) begin
                bresp_count <= bresp_count + 1;
                if (!pending_write) begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: BVALID without pending write at time %0t", $time);
                end else if (s_axi_bresp == 2'b00) begin
                    pass_count <= pass_count + 1;
                end else begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: non-OKAY BRESP=%0b at time %0t", s_axi_bresp, $time);
                end

                if (s_axi_bready) begin
                    pending_write <= 1'b0;
                    write_latency <= 0;
                end
            end

            // Read response must correspond to a pending read.
            if (s_axi_rvalid) begin
                rresp_count <= rresp_count + 1;
                if (!pending_read) begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: RVALID without pending read at time %0t", $time);
                end else if (s_axi_rresp == 2'b00) begin
                    pass_count <= pass_count + 1;
                end else begin
                    fail_count <= fail_count + 1;
                    $error("AXI CHECK FAIL: non-OKAY RRESP=%0b at time %0t", s_axi_rresp, $time);
                end

                if (s_axi_rready) begin
                    pending_read <= 1'b0;
                    read_latency <= 0;
                end
            end
        end
    end

    final begin
        $display("========================================");
        $display("AXI PROTOCOL CHECK SUMMARY");
        $display("WRITES=%0d READS=%0d BRESP=%0d RRESP=%0d PASS=%0d FAIL=%0d",
                 accepted_write_count, accepted_read_count, bresp_count, rresp_count, pass_count, fail_count);
        $display("========================================");
    end

endmodule
