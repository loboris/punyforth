\ this demo is for http://bit.ly/2bqHz58

5  constant: PIN_SPEED_1 \ D1
4  constant: PIN_SPEED_2 \ D2
0  constant: PIN_MOTOR_1 \ D3
2  constant: PIN_MOTOR_2 \ D4
14 constant: PIN_LIGHT_1 \ D5
15 constant: PIN_LIGHT_2 \ D8

create: PWM_PINS PIN_SPEED_1 c, PIN_SPEED_2 c,

FALSE init-variable: lamp-active

: lamp-on ( -- )
    PIN_LIGHT_1 GPIO_OUT gpio-mode
    PIN_LIGHT_2 GPIO_OUT gpio-mode
    PIN_LIGHT_1 GPIO_HIGH gpio-write
    PIN_LIGHT_2 GPIO_HIGH gpio-write ;
    
: lamp-off ( -- )
    PIN_LIGHT_1 GPIO_OUT gpio-mode
    PIN_LIGHT_2 GPIO_OUT gpio-mode
    PIN_LIGHT_1 GPIO_LOW gpio-write
    PIN_LIGHT_2 GPIO_LOW gpio-write ;

: lamp-toggle ( -- )
    lamp-active @ if lamp-off else lamp-on then 
    lamp-active @ invert lamp-active ! ;
    
: engine-start ( -- )
    PIN_MOTOR_1 GPIO_OUT gpio-mode
    PIN_MOTOR_2 GPIO_OUT gpio-mode
    PWM_PINS 2 pwm-init
    1000 pwm-freq
    1023 pwm-duty
    pwm-start ;

: engine-stop ( -- ) pwm-stop ;

: forward ( -- v1 v2 ) GPIO_LOW  GPIO_LOW  ;
: back    ( -- v1 v2 ) GPIO_HIGH GPIO_HIGH ;
: left    ( -- v1 v2 ) GPIO_LOW  GPIO_HIGH ;
: right   ( -- v1 v2 ) GPIO_HIGH GPIO_LOW  ;

: direction ( v1 v2 -- )
    PIN_MOTOR_2 swap gpio-write
    PIN_MOTOR_1 swap gpio-write ;
    
30000 constant: very-slow
40000 constant: slow
50000 constant: medium
60000 constant: fast
65535 constant: full

: speed ( n -- )
    case
        0 of
            pwm-stop
            PIN_SPEED_1 GPIO_LOW gpio-write
            PIN_SPEED_2 GPIO_LOW gpio-write
        endof
        full of
            pwm-stop
            PIN_SPEED_1 GPIO_HIGH gpio-write
            PIN_SPEED_2 GPIO_HIGH gpio-write        
        endof
        pwm-duty
        pwm-start   
    endcase ;

: brake ( -- ) 0 speed ;


medium init-variable: current-speed
8000 constant: PORT
PORT wifi-ip netcon-udp-server constant: server-socket
1 buffer: command

: command-loop ( task -- )
    activate    
    begin
        server-socket 1 command netcon-read
        -1 <>
    while
        command c@
        case
            [ char: F ] literal of 
                forward direction current-speed @ speed
            endof
            [ char: B ] literal of
                back direction current-speed @ speed
            endof
            [ char: L ] literal of 
                left direction current-speed @ speed
            endof
            [ char: R ] literal of 
                right direction current-speed @ speed
            endof
            [ char: S ] literal of 
                brake
            endof
            [ char: I ] literal of 
               current-speed @ 10 + full min
               current-speed !
               current-speed @ speed
            endof
            [ char: D ] literal of 
                current-speed @ 10 - 0 max
                current-speed !
                current-speed @ speed
            endof            
            [ char: E ] literal of
                engine-start
            endof
            [ char: H ] literal of
                engine-stop
            endof
            [ char: T ] literal of
                lamp-toggle
            endof
        endcase
    repeat 
    deactivate ;
    
0 task: tank-task

: tank-server-start ( -- )
    multi
    engine-start
    6 0 do lamp-toggle 200 ms loop
    tank-task command-loop ;

repl-start
tank-server-start