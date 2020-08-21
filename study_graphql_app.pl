#!/usr/bin/perl

use Mojolicious::Lite;
use JSON::PP qw/decode_json/;
use GraphQL::Schema;
use Mojo::Collection qw/c/;

app->config(hypnotoad => { listen => [ 'http://*:3000' ] });

get '/' => { text => 'This is an example app for GraphQL studies. Navigate to /graphql for a graphiql interface.' };

helper get_studies => sub {
    my ($c, $args) = @_;
    my $filters = $args->{filters} || {};
    my $options = $args->{options} || {};

    state $studies = get_studies();

    return $studies
        ->head($options->{limit} // 10)
        ->grep(sub { filter_studies($_, $filters) })
        ->to_array;
};

my $schema = Mojo::File->new(app->home->child('schema.graphql'))->slurp;
plugin GraphQL => {
    graphiql   => 1,
    schema     => GraphQL::Schema->from_doc($schema),
    root_value => { studies => sub { app->get_studies(shift) } },
};

app->start;


sub get_studies {
    c(@{decode_json(Mojo::File->new(app->home->child('studies.json'))->slurp)});
}

sub filter_studies {
    my $study   = shift;
    my $filters = shift || [];
    my $result  = 1;

    foreach my $filter (@$filters) {
        last unless $result;
        my $operator = transform_operator($filter->{operator}, $filter->{value});
        $result = eval '$study->{$filter->{field}} '. $operator;
    }

    return $result;
}

sub transform_operator {
    my $operator = shift // '';
    my $value = shift // '';

    return "<  $value"   if ($operator eq 'LT');
    return "<= $value"   if ($operator eq 'LE');
    return ">  $value"   if ($operator eq 'GT');
    return "!= $value"   if ($operator eq 'NE');
    return "== $value"   if ($operator eq 'EQ');
    return "eq '$value'" if ($operator eq 'MATCH');
    return "=~ /$value/" if ($operator eq 'REGEX_MATCH');

    return '';
}
