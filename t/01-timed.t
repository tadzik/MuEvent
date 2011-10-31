use Test;
use MuEvent;
plan 9;

my $start;

# 1 test, 2
MuEvent::timer(
    after => 2,
    cb    => sub {
        ok ($start + 2 <= time <= $start + 3), 'after 2';
    }
);

# 3 tests, 3, 5, 7
MuEvent::timer(
    after    => 3,
    interval => 2,
    cb    => sub {
        state $counter; BEGIN { $counter = 3 };
        return if $counter > 7;
        ok ($start + $counter <= time <= $start + $counter + 1),
           'after 3, interval 2';
        $counter += 2;
    }
);

# 3 tests, 4, 6, 8
MuEvent::timer(
    after    => 4,
    interval => 2,
    cb       => sub {
        state $counter; BEGIN { $counter = 4 };
        return if $counter > 9;
        ok ($start + $counter <= time <= $start + $counter + 1),
           'after 4, interval 2';
        $counter += 2;
    }
);

# 1 test, 7
MuEvent::timer(
    after => 7,
    cb    => sub {
        ok ($start + 7 <= time <= $start + 8), 'after 7';
    }
);

# 1 test, 9
MuEvent::timer(
    after => 9,
    cb    => sub {
        ok ($start + 8 <= time <= $start + 9), 'after 9';
        exit 0;
    }
);

$start = time;

MuEvent::run;
