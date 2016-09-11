exception: EGAVEUP
variable: data
variable: server

: measure ( -- temperature humidity | EGAVEUP )
    5 0 do
        ['] dht-measure catch ?dup 0<> 
        if
            ex-type cr
            3000 ms
        else
            unloop exit
        then
    loop
    EGAVEUP throw ;

: data! ( temperature humidity -- ) 16 lshift swap or data ! ;
: connect ( -- ) 8005 str: "192.168.0.10" UDP netcon-connect server ! ;
: dispose ( -- ) server @ netcon-dispose ;
: send ( -- ) server @ data 4 netcon-send-buf ;
    
: log ( temperature humidity -- )
    data! 
    connect
    ['] send catch dispose throw ;
    
: log-measurement ( -- )
    { measure log } catch ?dup 0<> 
    if
        ex-type cr
    then ;

log-measurement
5000 ms
1200000000 deep-sleep 
5000 ms
