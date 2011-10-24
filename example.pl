use MuEvent;

MuEvent::timer(
    after => 2,
    cb    => sub { say "2 seconds have passed" },
);

MuEvent::timer(
    after    => 0,
    interval => 5,
    cb       => sub { say "I run every 5 seconds" },
);

MuEvent::idle(
    cb => sub { say "Nothing better to do"; sleep 1 },
);

my $l = IO::Socket::INET.new(
    :localhost('localhost'),
    :localport(6666),
    :listen
);

MuEvent::socket(
    socket => $l,
    poll   => 'r',
    cb     => &socket-cb,
    params => { sock => $l },
);

sub socket-cb(:$sock) {
    say "Oh gosh a client!";
    my $s = $sock.accept;

    MuEvent::socket(
        socket => $s, 
        poll   => 'r',
        params => { sock => $s },
        cb     => sub (:$sock) {
            my $a = $sock.recv;
            if $a {
                print "Incoming transmission: $a";
                return True;
            } else {
                say "Client disconnected";
                $sock.close;
                return False;
            }
        }
    );
    return True;
}

MuEvent::run;
