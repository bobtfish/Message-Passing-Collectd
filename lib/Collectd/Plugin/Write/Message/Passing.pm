package Collectd::Plugin::Write::Message::Passing;
use strict;
use warnings;
use Collectd ();
use Data::Dumper;
use JSON;
use Module::Runtime qw/ require_module /;
use String::RewritePrefix ();
use Try::Tiny;
use namespace::clean;

our $OUTPUT;
our %CONFIG;

sub config {
    # {
   # key      => key,
   # values   => [ val1, val2, ... ],
   # children => [ { ... }, { ... }, ... ]
   #}
    %CONFIG = map { $_->{key} => (scalar(@{$_->{values}}) > 1 ? $_->{values} : $_->{values}->[0]) } @{ $_[0]->{children} };
}

sub _output {
    if (!$OUTPUT) {
        try {
            my $out = $CONFIG{OutputClass}->new(
                %{ $CONFIG{OutputOptions} }
            );
            $OUTPUT = $CONFIG{EncoderClass}->new(
                %{ $CONFIG{EncoderOptions} },
                output_to => $out,
            );
        }
        catch {
            Collectd::plugin_log(Collectd::LOG_WARNING, "Got exception building outputs: $_ - DISABLING");
            undef $OUTPUT;
        }
    }
    return $OUTPUT;
}

sub init {
    if (!$CONFIG{OutputClass}) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "No OutputClass config for Message::Passing plugin - disabling");
        return 0;
    }
    $CONFIG{OutputClass} = String::RewritePrefix->rewrite(
        { '' => 'Message::Passing::Output::', '+' => '' },
        $CONFIG{OutputClass}
    );
    if (!eval { require_module($CONFIG{OutputClass}) }) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "Could not load OutputClass=" . $CONFIG{OutputClass} . " error: $@");
        return 0;
    }
    $CONFIG{EncoderClass} ||= '+Message::Passing::Filter::Encoder::JSON';
    $CONFIG{EncoderClass} = String::RewritePrefix->rewrite(
        { '' => 'Message::Passing::Filter::Encoder::', '+' => '' },
        $CONFIG{EncoderClass}
    );
    $CONFIG{OutputOptions} ||= {};
    $CONFIG{EncoderOptions} ||= {};
    return 1;
}

sub write {
    my ($name, $val) = @_;
    # ["load",[{"min":0,"max":100,"name":"shortterm","type":1},{"min":0,"max":100,"name":"midterm","type":1},{"min":0,"max":100,"name":"longterm","type":1}],{"plugin":"load","time":1341655869.22588,"type":"load","values":[0.41,0.13,0.08],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}]
    # "transport.tx.size",[{"min":0,"max":0,"name":"transport.tx.size","type":0}],{"plugin":"ElasticSearch","time":1341655799.77979,"type":"transport.tx.size","values":[9725948078],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}
    my $output = _output() || return undef;
    $output->consume($val);
    return 1;
}

Collectd::plugin_register(
    Collectd::TYPE_INIT, 'Message::Passing', 'Collectd::Plugin::Write::Message::Passing::init'
);
Collectd::plugin_register(
    Collectd::TYPE_CONFIG, 'Message::Passing', 'Collectd::Plugin::Write::Message::Passing::config'
);
Collectd::plugin_register(
    Collectd::TYPE_WRITE, 'Message::Passing', 'Collectd::Plugin::Write::Message::Passing::write'
);

1;

