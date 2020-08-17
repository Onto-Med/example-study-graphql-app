use Mojolicious::Lite;
use JSON::PP qw/decode_json/;
use GraphQL::Schema;
use Mojo::Collection qw/c/;

app->config(hypnotoad => { listen => [ 'http://*:3000' ] });

get '/' => { text => 'This is an example app for GraphQL studies. Navigate to /graphql for a graphiql interface.' };

helper get_studies => sub {
    my ($c, $args) = @_;
    my $where   = $args->{where} || {};
    my $options = $args->{options} || {};

    state $studies = get_studies();

    return $studies
        ->head($options->{limit} // 10)
        ->grep(sub { filter_studies($_, $where) })
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
    my $study  = shift;
    my $where  = shift;
    my $result = 1;

    $result = $study->{id} == $where->{id} if (defined $where->{id});

    if (defined (my $pattern = $where->{name})) {
        $result = $study->{name} =~ /^$pattern$/;
    }

    return $result;
}
