module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;

integer i,j,k;

reg [7:0] string [0:31];
reg [7:0] pattern [0:7];
reg [5:0] count_string;
reg [3:0] count_pattern; 
reg [4:0] compare [0:1];

reg [1:0] state_cs,state_ns;
parameter ST_IDLE = 2'd0;
parameter ST_STRING = 2'd1;
parameter ST_PATTERN = 2'd2;
parameter ST_COMPARE = 2'd3;

always @(posedge clk or posedge reset) begin //state machine
    if(reset)
        state_cs <= ST_IDLE;
    else
        state_cs <= state_ns;    
end

always @(*) begin
    case (state_cs)
        ST_IDLE:
            if(isstring)
                state_ns = ST_STRING;
            else if(count_pattern)
                state_ns = ST_PATTERN;
            else
                state_ns = ST_IDLE;
        ST_STRING:
            if(~isstring)
                state_ns = ST_PATTERN;
            else
                state_ns = ST_STRING;
        ST_PATTERN:
            if(~ispattern)
                state_ns = ST_COMPARE;
            else
                state_ns = ST_PATTERN;
        ST_COMPARE:
            if(valid)
                state_ns = ST_IDLE;
            else
                state_ns = ST_COMPARE;
        default: 
            state_ns = ST_IDLE; 
    endcase
end

always @(posedge clk or posedge reset) begin //count_string
    if(reset)
        count_string <= 5'd0;
    else if(isstring && state_ns == ST_STRING)
        count_string <= count_string + 1'b1;
    else if(isstring && state_ns == ST_IDLE)
        count_string <= 5'd1;
    else 
        count_string <= count_string;
end

always @(posedge clk or posedge reset) begin //count_pattern
    if(reset)
        count_pattern <= 3'd0;
    else if(ispattern)
        count_pattern <= count_pattern + 1'b1;
    else if(state_ns == ST_COMPARE)
        count_pattern <= 3'd0;
    else 
        count_pattern <= count_pattern;
end

always @(posedge clk or posedge reset) begin //string
    if(reset)
        for(i=0;i<32;i=i+1)
            string[i] <= 8'd0;
    else 
        case (state_ns)
            ST_IDLE: 
                if(isstring)begin
                    for(i=0;i<32;i=i+1)
                        string[i] <= 8'd0;
                    string[count_pattern] <= chardata;
                end
                else
                    string[count_string] <= string[count_string];
            ST_STRING:
                string[count_string] <= chardata;
            default: 
                string[count_string] <= string[count_string];
        endcase
end

always @(posedge clk or posedge reset) begin //pattern
    if(reset)
        for(j=0;j<8;j=j+1)
            pattern[j] <= 8'd0;
    else 
        case (state_ns)
            ST_IDLE:begin
                for(j=0;j<8;j=j+1)
                    pattern[j] <= 8'd0;
                pattern[count_pattern] <= chardata;
            end
                
            ST_PATTERN:begin
                pattern[count_pattern] <= chardata;
            end
            default: 
                pattern[count_pattern] <= pattern[count_pattern];
        endcase
end

always @(*) begin //compare
    if(reset)begin
        compare[0] = 5'd0;
        compare[1] = 5'd0;
    end
    else if(state_ns == ST_COMPARE)
        for(i=0;i<count_string;i=i+1)begin
            compare[0] = 0;
            for(j=0;j<count_pattern;j=j+1)begin                    
                if(pattern[0] == 8'h5e)begin
                    compare[0] = compare[0] + 1'b1;
                    if(string[i] == 8'h20 || i == 0)
                        if(pattern[j+1] == string[i+j+1] || pattern[j+1] == 8'h2E)
                            compare[0] = compare[0];
                        else if(i == 0 && pattern[j] == string[i+j])
                            compare[0] = compare[0];
                        else if(pattern[j+1] == 8'h24)
                            if(string[i+j+1] == 8'h20 || i+j+1 == count_string)
                                compare[0] = compare[0];
                            else
                                compare[0] = 0; 
                        else if(compare[0] && j == count_pattern - 1)
                            compare[0] = compare[0];
                        else
                            compare[0] = 0;
                    else
                        compare[0] = 0;
                end                    
                else if(pattern[j] == string[i+j] || pattern[j] == 8'h2e || pattern[j] == 8'h24)begin
                    compare[0] = compare[0] + 1'b1;
                    if(pattern[count_pattern - 1] == 8'h24)begin
                        if(string[i+count_pattern-1] == 8'h20 || i+count_pattern-1 == count_string)
                            compare[0] = compare[0];
                        else
                            compare[0] = 0;  
                    end
                    else
                        compare[0] = compare[0];
                end
                else
                    compare[0] = 0;
            end
            if(compare[1] || ~compare[1])
                compare[1] = compare[1];
            else if(compare[0] == count_pattern && pattern[0] == 8'h5e)
                compare[1] = i + 1;
            else if(compare[0] == count_pattern)
                compare[1] = i;
            else
                compare[1] = compare[1];
        end 
    else begin
        compare[0] = 5'd0;
        compare[1] = 5'bz;
    end
end

always @(posedge clk or posedge reset) begin //match
    if(reset)
        match <= 0;
    else if(state_ns == ST_COMPARE)
        if(compare[1] >= 0)
            match <= 1;
        else
            match <= 0;
    else 
        match <= 0;
end

always @(posedge clk or posedge reset) begin //match_index
    if(reset)
        match_index <= 0;
    else if(state_ns == ST_COMPARE)
        match_index <= compare[1];
    else
        match_index <= 0;
end

always @(posedge clk or posedge reset) begin //valid
    if(reset)
        valid <= 0;
    else if(state_ns == ST_COMPARE)
        valid <= 1;
    else
        valid <= 0;
end


endmodule
