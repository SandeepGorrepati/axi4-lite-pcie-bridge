`timescale 1ns/1ps

// Lightweight functional coverage tracker compatible with Icarus Verilog.
// Tracks read/write activity, address ranges, responses, and cross-style bins.
module axi_coverage_tracker (
    input logic        clk,
    input logic        rst,

    input logic [31:0] s_axi_awaddr,
    input logic        s_axi_awvalid,
    input logic        s_axi_awready,
    input logic        s_axi_wvalid,
    input logic        s_axi_wready,
    input logic        s_axi_bvalid,
    input logic [31:0] s_axi_araddr,
    input logic        s_axi_arvalid,
    input logic        s_axi_arready,
    input logic        s_axi_rvalid
);

    integer write_count;
    integer read_count;
    integer bresp_seen;
    integer rresp_seen;

    integer low_addr_count;
    integer mid_addr_count;
    integer high_addr_count;

    integer w_low;
    integer w_mid;
    integer w_high;
    integer r_low;
    integer r_mid;
    integer r_high;

    function automatic [1:0] addr_bin(input logic [31:0] addr);
        begin
            if (addr < 32'h0000_0040)
                addr_bin = 2'd0;
            else if (addr < 32'h0000_0080)
                addr_bin = 2'd1;
            else
                addr_bin = 2'd2;
        end
    endfunction

    task automatic sample_addr(input logic [31:0] addr);
        begin
            case (addr_bin(addr))
                2'd0: low_addr_count  <= low_addr_count + 1;
                2'd1: mid_addr_count  <= mid_addr_count + 1;
                default: high_addr_count <= high_addr_count + 1;
            endcase
        end
    endtask

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            write_count    <= 0;
            read_count     <= 0;
            bresp_seen     <= 0;
            rresp_seen     <= 0;
            low_addr_count <= 0;
            mid_addr_count <= 0;
            high_addr_count <= 0;
            w_low <= 0;
            w_mid <= 0;
            w_high <= 0;
            r_low <= 0;
            r_mid <= 0;
            r_high <= 0;
        end else begin
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                write_count <= write_count + 1;
                sample_addr(s_axi_awaddr);
                case (addr_bin(s_axi_awaddr))
                    2'd0: w_low  <= w_low + 1;
                    2'd1: w_mid  <= w_mid + 1;
                    default: w_high <= w_high + 1;
                endcase
            end

            if (s_axi_arvalid && s_axi_arready) begin
                read_count <= read_count + 1;
                sample_addr(s_axi_araddr);
                case (addr_bin(s_axi_araddr))
                    2'd0: r_low  <= r_low + 1;
                    2'd1: r_mid  <= r_mid + 1;
                    default: r_high <= r_high + 1;
                endcase
            end

            if (s_axi_bvalid)
                bresp_seen <= bresp_seen + 1;

            if (s_axi_rvalid)
                rresp_seen <= rresp_seen + 1;
        end
    end

    final begin
        $display("========================================");
        $display("AXI FUNCTIONAL COVERAGE SUMMARY");
        $display("Operation bins       : writes=%0d reads=%0d", write_count, read_count);
        $display("Address range bins   : low=%0d mid=%0d high=%0d", low_addr_count, mid_addr_count, high_addr_count);
        $display("Response bins        : bresp_seen=%0d rresp_seen=%0d", bresp_seen, rresp_seen);
        $display("Cross op x addr bins : W_LOW=%0d W_MID=%0d W_HIGH=%0d R_LOW=%0d R_MID=%0d R_HIGH=%0d",
                 w_low, w_mid, w_high, r_low, r_mid, r_high);
        $display("========================================");
    end

endmodule
