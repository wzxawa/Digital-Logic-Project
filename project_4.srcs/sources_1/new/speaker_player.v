module variable_duty_cycle_wave (
    input clk,                // 100MHz ʱ���ź�
    input rst,                // ��λ�ź�
    input [6:0] state,       // �����״̬��
    output reg wave_out,      // ����ı�Ƶ������
    output wire en            // ʹ���źţ�����Ϊ�ߵ�ƽ��
);

    assign en = 1'b1; // ʼ��ʹ��

    reg wave_out_en;

    // ʱ�ӷ�Ƶ����
    reg [15:0] clk_div_counter; // ��Ƶ����??
    reg clk_new;                // ��Ƶ���ʱ���ź�

    // ռ�ձȺͿ��Ʋ���
    reg [6:0] counter;          // ����������������״???��??
    reg [7:0] duty_cycle;       // ռ�ձȣ�5% ?? 95%������Χ 5-95
    reg direction;              // �������??0 ��ʾ�ݼ�??1 ��ʾ����
    reg [15:0] count;           // ��Ƶ����??

    // ״???������
    reg [6:0] pre_state;        // ��һ��״??
    reg [44:0] timer_counter;   // ��ʱ�������������������ʱ��

    // ����
    localparam MAX_CYCLES = 50; // ÿ��״???����������50����Ƶʱ�����ڣ�
    localparam MAX_DUTY = 98;   // ??��ռ�ձ�??95%??
    localparam MIN_DUTY = 47;   // ??Сռ�ձ�??40%??
    localparam STEP = 1;        // ÿ�����ڵ���/�ݼ��Ĳ�����95% - 40%??/50 ?? 1

    // frequency generator
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            clk_div_counter <= 0;
            clk_new <= 0;
        end else begin
            if (clk_div_counter == count) begin
                clk_div_counter <= 0;
                clk_new <= ~clk_new; // �л�ʱ��Ƶ��
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            pre_state <= 7'b0;  // ��ʼ״???Ϊ 0
            timer_counter <= 0; // ��ʱ����??
            wave_out_en <= 0;      // ��ʼ�������??
        end else if (state != pre_state) begin
            pre_state <= state;          // ���� pre_state
            case (state)
                7'b0000000, 7'b1000000: begin
                    count <= 200;    // ���ò�ͬ�ķ�Ƶ��??
                    timer_counter <= 45'd150000000;  // ���� 1.5�루200MHz ʱ���£���Լ 2��ļ�ʱ����??200000000
                end
                7'b1010000, 7'b1100000, 7'b1100100, 7'b1101000, 7'b1101100: begin
                    count <= 250;
                    timer_counter <= 45'd150000000;  // ���� 1.5�루200MHz ʱ���£���Լ 2��ļ�ʱ����??200000000
                end
                7'b1010100, 7'b1011000, 7'b1011100: begin
                    count <= 300;
                    timer_counter <= 45'd150000000;  // ���� 1.5�루200MHz ʱ���£���Լ 2��ļ�ʱ����??200000000
                end
                7'b1111001, 7'b1111010, 7'b1111011, 7'b1111101, 7'b1111110, 7'b1111111: begin
                    count <= 150;
                    timer_counter <= 45'd150000000;  // ���� 1.5�루200MHz ʱ���£���Լ 2��ļ�ʱ����??200000000
                end
                7'b1011101:begin
                    count <= 250;
                    timer_counter <= 45'd6000000000;
                   end
                7'b1010010:begin
                    count <= 250;
                    timer_counter <= 45'd18000000000;
                end
                default: begin
                    count <= 100;
                    timer_counter <= 45'd150000000;  // ���� 1.5�루200MHz ʱ���£���Լ 2��ļ�ʱ����??200000000
                end
            endcase
            // �����������
            wave_out_en <= 1;
        end else if (timer_counter > 0) begin
            // ��ʱ�����٣������������
            timer_counter <= timer_counter - 1;
            wave_out_en <= 1;  // ���ָߵ�ƽ�������ʾ��������
        end else begin
            // ����2���ֹͣ�������
            wave_out_en <= 0;
        end
    end

    // ��???����ռ�ձȱ仯�����������??
    always @(posedge clk_new or negedge rst) begin
        if (~rst) begin
            counter <= 0;
            duty_cycle <= MAX_DUTY; // ��ʼռ�ձ�Ϊ95%
            direction <= 0;         // ��ʼ����Ϊ???��
        end else begin
            if (counter == MAX_CYCLES - 1) begin
                // ??50�����ڵ���һ��ռ�ձ�
                counter <= 0;

                if (direction == 0) begin
                    // �ݼ���ռ�ձ�??95%����??5%
                    if (duty_cycle > MIN_DUTY)
                        duty_cycle <= duty_cycle - STEP; // ÿ�εݼ�1%
                    else
                        direction <= 1; // ���ռ�ձ�Ϊ5%���ı䷽��Ϊ����
                end else begin
                    // ������ռ�ձ�??5%����??95%
                    if (duty_cycle < MAX_DUTY)
                        duty_cycle <= duty_cycle + STEP; // ÿ�ε���1%
                    else
                        direction <= 0; // ���ռ�ձ�Ϊ95%���ı䷽��Ϊ�ݼ�
                end
            end else begin
                counter <= counter + 1; // ������???��
            end

            // ����ռ�ձȿ��������??
            if (counter < (duty_cycle * MAX_CYCLES) / 100 && wave_out_en) begin
                wave_out <= 1; // �ߵ�??
            end else begin
                wave_out <= 0; // �͵�??
            end
        end
    end

endmodule
