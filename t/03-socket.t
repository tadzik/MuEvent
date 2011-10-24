use Test;
use MuEvent;
plan 13;

my $l = IO::Socket::INET.new(
    :localhost('localhost'),
    :localport(6666),
    :listen
);

my $start;
my $last-sent-message;

sub socket-cb(:$sock) {
    my $s = $sock.accept;

    MuEvent::socket(
        socket => $s, 
        poll   => 'r',
        params => { sock => $s },
        cb     => sub (:$sock) {
            my $a = $sock.recv;
            if $a {
                is $a, $last-sent-message, 'data received';
                return True;
            } else {
                pass 'disconnected';
                $sock.close;
                return False;
            }
        }
    );

    return True;
}

my $c1 = IO::Socket::INET.new(:host('localhost'), :port(6666));
my $c2 = IO::Socket::INET.new(:host('localhost'), :port(6666));

MuEvent::socket(
    socket => $l,
    poll   => 'r',
    cb     => &socket-cb,
    params => { sock => $l },
);

MuEvent::socket(
    socket => $l,
    poll   => 'r',
    cb     => &socket-cb,
    params => { sock => $l },
);

MuEvent::timer(
    after => 2,
    cb    => sub {
        ok ($start + 2 <= time <= $start + 3), 'after 2';
        $last-sent-message = 'foobar';
        $c1.send('foobar');
    }
);

MuEvent::timer(
    after => 3,
    cb    => sub {
        ok ($start + 3 <= time <= $start + 4), 'after 3';
        $last-sent-message = 'bar';
        $c2.send('bar');
    }
);

MuEvent::timer(
    after => 4,
    cb    => sub {
        ok ($start + 4 <= time <= $start + 5), 'after 4';
        $last-sent-message = 'baz';
        $c2.send('baz');
    }
);

MuEvent::timer(
    after => 5,
    cb    => sub {
        ok ($start + 5 <= time <= $start + 6), 'after 5';
        $last-sent-message = 'foo';
        $c1.send('foo');
    }
);

MuEvent::timer(
    after => 6,
    cb    => sub {
        ok ($start + 6 <= time <= $start + 7), 'after 6';
        $c1.close;
    }
);

MuEvent::timer(
    after => 7,
    cb    => sub {
        ok ($start + 7 <= time <= $start + 8), 'after 7';
        $c2.close;
    }
);

MuEvent::timer(
    after => 8,
    cb    => sub {
        ok ($start + 8 <= time <= $start + 9), 'after 8';
        exit 0;
    }
);

$start = time;
MuEvent::run;
