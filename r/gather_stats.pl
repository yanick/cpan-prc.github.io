use 5.20.0;
use strict;

use Path::Tiny;
use File::Serialize;
use List::AllUtils qw/ zip /;

use experimental 'postderef';

my @challenges;
my @prs;

my @m_name = qw/ january february march april may june july august september october november december /; 
my @m_val = 1..12;
my %month = zip @m_name, @m_val;

for my $year( 2015..2018 ) {
    my @files = path('..', $year)->children(qr/\.json$/);

    for my $file ( @files ) {
        my $data = deserialize_file $file;
        my $month = $month{ $file->basename =~ s/\.json//r };
        my %date = ( date => sprintf "%4d-%02d-01", $year, $month );

        for my $entry ( $data->{assignments}->@* ) {
            push @challenges, {
                %date,
                done => $entry->{done},
                assignee => $entry->{assignee}{github_username},
                distname => $entry->{distname},
                dist_author => lc $entry->{released_by}{pause_id},
            };
            for my $pr ( $entry->{pull_requests}->@* ) {
                push @prs, {
                    %date,
                    assignee => $entry->{assignee}{github_username},
                    distname => $entry->{distname},
                    pr => $pr->{relpath},
                    state => $pr->{state},
                };
            }
        }
    }
    
}

my @challenge_fields = qw/ date done assignee distname dist_author /;
unshift @challenges, map { $_ => $_ } 

path( 'challenges.csv' )->spew(
    map { $_ . "\n" }
    map { join ' | ', $_->@{ @challenge_fields } }
    ( { map { ($_)x2 } @challenge_fields } ), @challenges 
);



my @pr_fields = qw/ date assignee distname state pr /;
unshift @prs, map { $_ => $_ } 

path( 'prs.csv' )->spew(
    map { $_ . "\n" }
    map { join ' | ', $_->@{ @pr_fields } }
    ( { map { ($_)x2 } @pr_fields } ), @prs
);
