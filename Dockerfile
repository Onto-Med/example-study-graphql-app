FROM tekki/mojolicious

RUN cpan Mojolicious::Plugin::GraphQL
COPY study_graphql_app.pl .
