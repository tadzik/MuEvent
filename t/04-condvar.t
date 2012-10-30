use Test;
use MuEvent;

plan 5;

my $start = time;
my $plan = 1;

{
    my $cv = MuEvent::condvar;
    ok $cv.send( "foo" ), "send";
    ok $cv.recv ~~ "foo", "recv";
}

{
    my $cv = MuEvent::condvar;

    MuEvent::timer(after => 2, cb => sub { 
        ok $plan++ == 2 && $start+1 <= time <= $start+3, "timer occured";
        $cv.send;
    });

    ok $plan++ == 1 && time - $start < 1, "not block timer";
    $cv.recv;
    ok $plan++ == 3 && $start+1 <= time <= $start+3, "received blocked";
}
