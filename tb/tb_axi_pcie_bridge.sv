`timescale 1ns/1ps

module tb_axi_pcie_bridge;

    logic clk;
    logic rst;

    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;
    logic [3:0] s_axi_wstrb;
    
    logic [31:0] s_axi_wdata;
    logic        s_axi_wvalid;
    logic        s_axi_wready;
    logic       pcie_tx_ready;
    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;

    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    axi_pcie_bridge_top dut (
        .clk(clk),
        .rst(rst),

        .s_axi_awaddr (s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wdata (s_axi_wdata),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .pcie_tx_ready(pcie_tx_ready),
        .s_axi_bresp (s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr (s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata (s_axi_rdata),
        .s_axi_rresp (s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );


    axi_protocol_checker u_axi_protocol_checker (
        .clk(clk),
        .rst(rst),

        .s_axi_awaddr (s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata  (s_axi_wdata),
        .s_axi_wstrb  (s_axi_wstrb),
        .s_axi_wvalid (s_axi_wvalid),
        .s_axi_wready (s_axi_wready),

        .s_axi_bresp  (s_axi_bresp),
        .s_axi_bvalid (s_axi_bvalid),
        .s_axi_bready (s_axi_bready),

        .s_axi_araddr (s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata  (s_axi_rdata),
        .s_axi_rresp  (s_axi_rresp),
        .s_axi_rvalid (s_axi_rvalid),
        .s_axi_rready (s_axi_rready)
    );

    axi_coverage_tracker u_axi_coverage_tracker (
        .clk(clk),
        .rst(rst),

        .s_axi_awaddr (s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wvalid (s_axi_wvalid),
        .s_axi_wready (s_axi_wready),

        .s_axi_bvalid (s_axi_bvalid),

        .s_axi_araddr (s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rvalid (s_axi_rvalid)
    );

    always #5 clk = ~clk;

    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1;
            s_axi_wdata   <= data;
            s_axi_wvalid  <= 1;
            s_axi_bready  <= 1;

            wait (s_axi_awready && s_axi_wready);
            @(posedge clk);

            s_axi_awvalid <= 0;
            s_axi_wvalid  <= 0;

            wait (s_axi_bvalid);
            @(posedge clk);

            s_axi_bready <= 0;

            $display("WRITE OK: addr=%h data=%h time=%0t", addr, data, $time);
        end
    endtask


    task axi_read(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk);

            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1;
            s_axi_rready  <= 1;

            wait (s_axi_arready);
            @(posedge clk);

            s_axi_arvalid <= 0;

            wait (s_axi_rvalid);

            data = s_axi_rdata;

            @(posedge clk);
            s_axi_rready <= 0;

            $display("READ OK : addr=%h data=%h time=%0t", addr, data, $time);
        end
    endtask


    logic [31:0] rd_data;
    logic [31:0] rand_addr;
    logic [31:0] rand_data;
    integer i;

    initial begin
        clk = 0;
        rst = 1;
        s_axi_wstrb = 4'hF;
        pcie_tx_ready = 1'b1;
        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        #20;
        rst = 0;

        //--------------------------------------------------
        // Test 0: Read from empty memory
        //--------------------------------------------------
        axi_read(32'h00000030, rd_data);

        if (rd_data == 32'h00000000)
            $display("PASS: Empty memory read returns 0");
        else
            $display("FAIL: Unexpected value %h", rd_data);


        //--------------------------------------------------
        // Test 1: Write then read
        //--------------------------------------------------
        axi_write(32'h00000010, 32'h1234ABCD);
        axi_read (32'h00000010, rd_data);

        if (rd_data == 32'h1234ABCD)
            $display("PASS: Read data matches written data");
        else
            $display("FAIL: Expected 1234ABCD got %h", rd_data);


        //--------------------------------------------------
        // Test 2: Another write/read
        //--------------------------------------------------
        axi_write(32'h00000020, 32'hDEADBEEF);
        axi_read (32'h00000020, rd_data);

        if (rd_data == 32'hDEADBEEF)
            $display("PASS: Second read data matches");
        else
            $display("FAIL: Expected DEADBEEF got %h", rd_data);



        //--------------------------------------------------
        // Test 3: Overwrite behavior
        //--------------------------------------------------
        axi_write(32'h00000020, 32'hCAFEBABE);
        axi_read (32'h00000020, rd_data);

        if (rd_data == 32'hCAFEBABE)
            $display("PASS: Overwrite returns latest data");
        else
            $display("FAIL: Expected CAFEBABE got %h", rd_data);

        //--------------------------------------------------
        // Test 4: Mid-range address write/readback
        //--------------------------------------------------
        axi_write(32'h00000060, 32'hA5A55A5A);
        axi_read (32'h00000060, rd_data);

        if (rd_data == 32'hA5A55A5A)
            $display("PASS: Mid-range address readback matches");
        else
            $display("FAIL: Expected A5A55A5A got %h", rd_data);

        //--------------------------------------------------
        // Test 5: High-range address write/readback
        //--------------------------------------------------
        axi_write(32'h000000C0, 32'h55AA33CC);
        axi_read (32'h000000C0, rd_data);

        if (rd_data == 32'h55AA33CC)
            $display("PASS: High-range address readback matches");
        else
            $display("FAIL: Expected 55AA33CC got %h", rd_data);

        //--------------------------------------------------
        // Test 6-11: Randomized aligned address/data scenarios
        //--------------------------------------------------
        for (i = 0; i < 6; i = i + 1) begin
            rand_addr = {24'h0, (($urandom_range(0, 8'hFE)) & 8'hFC)};
            rand_data = $urandom();

            if (rand_data == 32'h00000000)
                rand_data = 32'hA5A50000 + i;

            axi_write(rand_addr, rand_data);
            axi_read (rand_addr, rd_data);

            if (rd_data == rand_data)
                $display("PASS: Randomized write/readback addr=%h data=%h", rand_addr, rand_data);
            else
                $display("FAIL: Randomized mismatch addr=%h expected=%h got=%h", rand_addr, rand_data, rd_data);
        end

        #20;
        $finish;
    end


    initial begin
        $dumpfile("build/axi_pcie_bridge.vcd");
        $dumpvars(0, tb_axi_pcie_bridge);
    end

endmodule
