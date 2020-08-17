FROM tekki/mojolicious

RUN cpan Mojolicious::Plugin::GraphQL
RUN cpan File::Slurp

COPY study_graphql_app.pl .
COPY schema.graphql .
COPY studies.json .
