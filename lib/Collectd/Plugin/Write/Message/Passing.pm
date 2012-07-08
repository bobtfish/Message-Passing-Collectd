package Collectd::Plugin::Write::Message::Passing;
use strict;
use warnings;
use Collectd ();
use JSON;
use Module::Runtime qw/ require_module /;
use String::RewritePrefix ();
use Try::Tiny;
use namespace::clean;

our $OUTPUT;
our %CONFIG;

sub _clean_value {
    my $val = shift;
    scalar(@$val) > 1 ? $val : $val->[0];
}

sub _flatten_item {
    my $item = shift;
    my $val;
    if (scalar(@{$item->{children}})) {
        $val = [ map { my $i = $_; _flatten_item($i) } @{$item->{children}} ];
    }
    else {
        $val = $item->{values};
    }
    return {
        $item->{key} => _clean_value($val)
    }
}

sub config {
    my @items = @{ $_[0]->{children} };
    foreach my $item (@items) {
        %CONFIG = ( %{_flatten_item($item)} , %CONFIG );
    }
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
    if (!eval { require_module($CONFIG{EncoderClass}) }) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "Could not load EncoderClass=" . $CONFIG{EncoderClass} . " error: $@");
        return 0;
    }
    $CONFIG{OutputOptions} ||= {};
    $CONFIG{EncoderOptions} ||= {};
    _output() || return 0;
    return 1;
}

sub write {
    my ($name, $val) = @_;
    # ["load",[{"min":0,"max":100,"name":"shortterm","type":1},{"min":0,"max":100,"name":"midterm","type":1},{"min":0,"max":100,"name":"longterm","type":1}],{"plugin":"load","time":1341655869.22588,"type":"load","values":[0.41,0.13,0.08],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}]
    # "transport.tx.size",[{"min":0,"max":0,"name":"transport.tx.size","type":0}],{"plugin":"ElasticSearch","time":1341655799.77979,"type":"transport.tx.size","values":[9725948078],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}
    my $output = _output() || return 0;
    $output->consume($val);
    return 1;
}

Collectd::plugin_register(
    Collectd::TYPE_INIT, 'Write::Message::Passing', 'Collectd::Plugin::Write::Message::Passing::init'
);
Collectd::plugin_register(
    Collectd::TYPE_CONFIG, 'Write::Message::Passing', 'Collectd::Plugin::Write::Message::Passing::config'
);
Collectd::plugin_register(
    Collectd::TYPE_WRITE, 'Write::Message::Passing', 'Collectd::Plugin::Write::Message::Passing::write'
);

1;

=head1 NAME

Collectd::Plugin::Write::Message::Passing - Write collectd metrics via Message::Passing

=head1 SYNOPSIS

    <LoadPlugin perl>
        Globals true
    </LoadPlugin>
    <Plugin perl>
        BaseName "Collectd::Plugin"
        LoadPlugin "Write::Message::Passing"
        <Plugin "Write::Message::Passing">
            # MANDATORY - You MUST configure an output class
            OutputClass "ZeroMQ"
            <OutputClassOptions>
                connect "tcp://192.168.0.1:5552"
            </OutputClassOptions>
            # OPTIONAL - Defaults to JSON
            #EncoderClass "JSON"
            #<EncoderClassOptions>
            #   pretty "0"
            #</EncoderClassOptions>
        </Plugin>
    </Plugin>

    Will emit metrics like this:

    [{"min":0,"max":100,"name":"shortterm","type":1},{"min":0,"max":100,"name":"midterm","type":1},{"min":0,"max":100,"name":"longterm","type":1}],{"plugin":"load","time":1341655869.22588,"type":"load","values":[0.41,0.13,0.08],"interval":10,"host":"t0m.local"}]

=head1 DESCRIPTION

A collectd plugin to emit metrics from L<collectd|http://collectd.org/> into L<Message::Passing>.

=head1 PACKAGE VARIABLES

=head2 %CONFIG

A hash containing the following:

=head3 OutputClass

The name of the class which will act as the Message::Passing output. Will be used as-is if prefixed with C<+>,
otherwise C<Message::Passing::Output::> will be prepended. Required.

=head3 OutputOptions

The hash of options for the output class. Not required, but almost certainly needed.

=head3 EncoderClass

The name of the class which will act  the Message::Passing encoder. Will be used as-is if prefixed with C<+>,
otherwise C<Message::Passing::Output::> will be prepended. Optional, defaults to L<JSON|Message::Passing::Filter::Encoder::JSON>.

=head3 EncoderOptions

The hash of options for the encoder class.

=head1 FUNCTIONS

=head2 config

Called first with configuration in the config file, munges it into the format expected
and places it into the C<%CONFIG> hash.

=head2 init

Validates the config, and initializes the C<$OUTPUT>

=head2 write

Writes a metric to the output in C<$OUTPUT>.

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Message::Passing::Collectd>.

=cut

