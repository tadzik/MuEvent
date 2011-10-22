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
);

sub socket-cb {
    say "Oh gosh a client!";
    my $s = $l.accept;
    MuEvent::socket(
        socket => $s, 
        poll   => 'r',
        cb     => sub {
            my $a = $s.recv;
            if $a {
                print "Incoming transmission: $a";
                return True;
            } else {
                say "Client disconnected";
                $s.close;
                return False;
            }
        }
    );
    return True;
}

MuEvent::run;
