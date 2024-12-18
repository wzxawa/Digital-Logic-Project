module keyboard(
    input wire clk,
    input wire clr,
    input wire PS2C,
    input wire PS2D,
    output reg [2:0] kb_out
);

    reg PS2Cf; 
    reg PS2Df;
    reg [0:20] cnt_xd = 0;    //消抖计时
    reg [7:0] key_pass;
    reg [1:0] clk_25MHz;
    reg [7:0] ps2c_filter,ps2d_filter;
    reg [10:0] shift1,shift2;  
    reg DIR1 = 1'b0;   
    wire [15:0] xkey;

    parameter xd = 21'd2000000;    //计时_20ms


    always @(posedge clk) begin  //25MHZ
    if(clk_25MHz >= 3)
    begin
        DIR1 <= 1'b1;
        clk_25MHz <= 0;
    end
    else
    begin
        clk_25MHz <= clk_25MHz + 1;
        DIR1 <= 1'b0;
    end
    end

    //filter for PS2 clock and data
    always @(posedge DIR1)
    begin
        if(!clr)
            begin
            ps2c_filter <= 0;
            ps2d_filter <= 0;
            PS2Cf <= 1;
            PS2Df <= 1;
            end
         else
            begin
            ps2c_filter[7]<=PS2C;
            ps2c_filter[6:0]<=ps2c_filter[7:1];
            ps2d_filter[7]<=PS2D;
            ps2d_filter[6:0]<=ps2d_filter[7:1];
            if(ps2c_filter==8'b11111111)
                PS2Cf <= 1;
            else
                if(ps2c_filter == 8'b00000000)
                PS2Cf <= 0;
            if(ps2d_filter == 8'b11111111)
                PS2Df <= 1;
            else
                if(ps2d_filter == 8'b00000000)
                PS2Df <= 0;
            end
     end

    always @(negedge PS2Cf) begin   
    if(!clr)
    begin
        shift1 <= 0;
        shift2 <= 0;
    end
    else
    begin
        shift1 <= {PS2Df,shift1[10:1]};
        shift2 <= {shift1[0],shift2[10:1]};
    end 
    end
    
    assign xkey = {shift2[8:1],shift1[8:1]};
    
    
    //键盘消抖和按键消抖同理，但这里存在Bug，就是松开之后也会算一次按下信号，但对于本贪吃蛇工程无影响
    always@(posedge clk) begin    //消抖计时
    key_pass = xkey[7:0];
    if(key_pass != 8'h63 & key_pass != 8'h60 & key_pass != 8'h61 & key_pass != 8'h6a)    //抖动即重新开始
        cnt_xd = 0;
    else if(cnt_xd == xd)
        cnt_xd <= xd;
    else
        cnt_xd <= cnt_xd + 1;
    end

    always@(posedge clk) begin
    if(cnt_xd == 0)
        kb_out <= 0;
    else if(cnt_xd == (xd - 21'b1))    //产生1个时间单位的按键信号
        case(key_pass)     //根据键入得到对应的值
        8'h63: kb_out <= 1;    //↑
        8'h60: kb_out <= 2;    //↓
        8'h61: kb_out <= 3;    //←
        8'h6a: kb_out <= 4;    //→
        default : kb_out <= 0;
        endcase
    else
        kb_out <= 0;   //0表示无按键按下
    end

endmodule