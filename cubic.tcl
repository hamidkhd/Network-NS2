set ns [new Simulator]

$ns color 1 Blue
$ns color 2 Red

set nf [open output/cubic.nam w]
$ns namtrace-all $nf
set tracefile1 [open output/cubicTrace.tr w]
$ns trace-all $tracefile1
set cwndOut [open output/cubic_cwnd.tr w]
set goodputOut [open output/cubic_goodput.tr w]
set rttOut [open output/cubic_rtt.tr w]


proc finish {} {
    global ns nf cwndOut goodputOut rttOut
    $ns flush-trace
    #Close the NAM trace file
    close $nf
    close $cwndOut
    close $goodputOut
    close $rttOut
    exit 0
}

set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

$ns duplex-link $n1 $n3 4000Mb 500ms DropTail
$ns duplex-link $n2 $n3 4000Mb 800ms DropTail
$ns duplex-link $n3 $n4 1000Mb 50ms DropTail
$ns duplex-link $n4 $n5 4000Mb 500ms DropTail  
$ns duplex-link $n4 $n6 4000Mb 800ms DropTail

$ns queue-limit $n3 $n4 10
$ns queue-limit $n4 $n3 10


# NAM

$ns duplex-link-op $n1 $n3 orient right-down
$ns duplex-link-op $n2 $n3 orient right-up
$ns duplex-link-op $n3 $n4 orient right
$ns duplex-link-op $n4 $n5 orient right-up
$ns duplex-link-op $n4 $n6 orient right-down

set tcp1 [new Agent/TCP/Linux]
$ns at 0 "$tcp1 select_ca cubic"
$tcp1 set class_ 1
$tcp1 set ttl_ 64
$tcp1 set packetSize_ 1000 
$tcp1 set windowInit_ 8   # 8 * MSS = 8 * 1000
$tcp1 set window_ 8000

$ns attach-agent $n1 $tcp1
set dst1 [new Agent/TCPSink]
$ns attach-agent $n5 $dst1
$ns connect $tcp1 $dst1
$tcp1 set fid_ 1

set tcp2 [new Agent/TCP/Linux]
$ns at 0 "$tcp2 select_ca cubic"
$tcp2 set class_ 2
$tcp2 set ttl_ 64
$tcp2 set packetSize_ 1000 
$tcp2 set windowInit_ 8   # 8 * MSS = 8 * 1000
$tcp2 set window_ 8000

$ns attach-agent $n2 $tcp2
set dst2 [new Agent/TCPSink]
$ns attach-agent $n6 $dst2
$ns connect $tcp2 $dst2
$tcp2 set fid_ 2


set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1


set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

proc cwndTrace {tcp1 tcp2 outfile} {
    global ns
    set now [$ns now]
    set cwnd1 [$tcp1 set cwnd_]
    set cwnd2 [$tcp2 set cwnd_]
    puts  $outfile  "$now $cwnd1 $cwnd2"
    $ns at [expr $now+1] "cwndTrace $tcp1 $tcp2 $outfile"
}

set prevAck1 -1
set prevAck2 -1
proc goodputTrace {tcp1 tcp2 outfile} {
    global ns
    global prevAck1
    global prevAck2
    set now [$ns now]
    set ack1 [$tcp1 set ack_]
    set ack2 [$tcp2 set ack_]
    puts  $outfile "$now [expr ($ack1-$prevAck1)] [expr ($ack2-$prevAck2)]"
    set prevAck1 $ack1
    set prevAck2 $ack2
    $ns at [expr $now+1] "goodputTrace $tcp1 $tcp2 $outfile"
}

proc rttTrace {tcp1 tcp2 outfile} {
     global ns
     set now [$ns now]
     set rtt1 [$tcp1 set rtt_]
     set rtt2 [$tcp2 set rtt_]
     puts  $outfile  "$now $rtt1 $rtt2"
     $ns at [expr $now+1] "rttTrace $tcp1 $tcp2 $outfile"
}

$ns at 0.0 "$ftp1 start"
$ns at 0.0 "$ftp2 start"
$ns at 0.0  "cwndTrace $tcp1 $tcp2 $cwndOut"
$ns at 0.0  "goodputTrace $tcp1 $tcp2 $goodputOut"
$ns at 0.0  "rttTrace $tcp1 $tcp2 $rttOut"

$ns at 1000.0 "finish"

$ns run
