use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use MockCollectd;
use JSON qw/ encode_json decode_json /;
use Test::More;

use_ok 'Message::Passing::Filter::Encoder::JSON';
use_ok 'Message::Passing::Output::Test';
use_ok 'Collectd::Plugin::Write::Message::Passing';

open(my $fh, '<', "$Bin/example_data.json") or die $!;

$Collectd::Plugin::Write::Message::Passing::CONFIG{EncoderClass} = 'Message::Passing::Filter::Encoder::JSON';
$Collectd::Plugin::Write::Message::Passing::CONFIG{OutputClass} = 'Message::Passing::Output::Test';
$Collectd::Plugin::Write::Message::Passing::CONFIG{EncoderOptions} = {};
$Collectd::Plugin::Write::Message::Passing::CONFIG{OutputOptions} = {};

my $count = 0;
while (my $line = <$fh>) {
    my $data = decode_json $line;
    Collectd::Plugin::Write::Message::Passing::write(@$data);
    ok $line, $line;
    $count++;
    is $Collectd::Plugin::Write::Message::Passing::OUTPUT->output_to->message_count, $count;
    is_deeply decode_json([$Collectd::Plugin::Write::Message::Passing::OUTPUT->output_to->messages]->[-1]), $data->[1];
}

close($fh);

done_testing;

