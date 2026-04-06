module sw_led_match(
    input  [15:0] SW,
    output [15:0] LED
);

    assign LED = SW;

endmodule