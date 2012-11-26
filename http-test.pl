use MuEvent;

my @urls = <
    duckduckgo.com
    cpan.org
    kosciol-spaghetti.pl
    perlcabal.org
    perl6.org
>;
my $count = @urls.elems;
my $starttime;

sub http_get_eager(:$url!) is export {
    my $sock = IO::Socket::INET.new(host => $url, port => 80);
    my $req = "GET / HTTP/1.1\r\n"
            ~ "Connection: Close\r\n"
            ~ "Host: $url\r\n"
            ~ "User-Agent: MuEvent/0.0 Perl6/$*PERL<compiler><ver>\r\n"
            ~ "\r\n";
    $sock.send($req);
    $sock.recv;
    $sock.close;
}

say "=== BLOCKING FETCHING ===";
my $last;
$starttime = $last = now;
for @urls -> $url {
    http_get_eager(url => $url);
    say sprintf "%-25s has loaded in %s", $url, now - $last;
    $last = now;
}
say "Finished in {now - $starttime} seconds";


sub handler ($what, $content) {
    say sprintf "%-25s has loaded in %s", $what, now - $starttime;
    unless --$count {
        say "Finished in {now - $starttime} seconds";
        exit 0;
    }
}

say "=== NON-BLOCKING FETCHING ===";
$starttime = now;

for @urls -> $url {
    http_get(url => $url, cb => sub { handler($url, $^content) })
}

MuEvent::run;
