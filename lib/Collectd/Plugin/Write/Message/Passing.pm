package Collectd::Plugin::Write::Message::Passing;
use strict;
use warnings;
use Collectd ();
use Data::Dumper;
use JSON;

sub write {
    # ["load",[{"min":0,"max":100,"name":"shortterm","type":1},{"min":0,"max":100,"name":"midterm","type":1},{"min":0,"max":100,"name":"longterm","type":1}],{"plugin":"load","time":1341655869.22588,"type":"load","values":[0.41,0.13,0.08],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}]
    # "transport.tx.size",[{"min":0,"max":0,"name":"transport.tx.size","type":0}],{"plugin":"ElasticSearch","time":1341655799.77979,"type":"transport.tx.size","values":[9725948078],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}
}

Collectd::plugin_register(
    Collectd::TYPE_WRITE, 'Message::Passing', 'Collectd::Plugin::Write::Message::Passing::write'
);

1;

