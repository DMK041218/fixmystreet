use strict;
use warnings;
use PPI;

my @files = (
    'perllib/FixMyStreet/App/Controller/Reports.pm',
    'perllib/FixMyStreet/App/Controller/Around.pm',
    'perllib/FixMyStreet/App/Controller/My.pm',
    'perllib/FixMyStreet/Map.pm',
    'perllib/FixMyStreet/DB/ResultSet/Problem.pm',
    'perllib/FixMyStreet/DB/ResultSet/Nearby.pm',
    'perllib/FixMyStreet/Cobrand/Bromley.pm',
);
my @edges = (
    [ 'Reports.pm', 'ward', 'stash_report_filter_status', 'load_and_group_problems', 'ajax' ],
    [ 'Reports.pm', 'load_and_group_problems', 'stash_report_sort', 'sort_order', 'munge_load_and_group_problems', 'include_comment_counts' ],
    [ 'Reports.pm', 'stash_report_sort', 'comments-desc', 'sort_key', 'report_age_field', 'sort_order' ],
    [ 'Around.pm', 'display_location', 'map_features' ],
    [ 'Around.pm', 'ajax', 'map_features', '/reports/ajax' ],
    [ 'Around.pm', 'map_features', '/reports/stash_report_sort', 'FixMyStreet::Map::map_features', 'sort_order' ],
    [ 'My.pm', 'my', '/reports/stash_report_sort', 'get_problems' ],
    [ 'My.pm', 'planned', '/reports/stash_report_sort', 'get_problems' ],
    [ 'My.pm', 'get_problems', 'sort_order', 'include_comment_counts' ],
    [ 'Map.pm', 'map_features', 'around_map', 'nearby' ],
    [ 'Problem.pm', 'around_map', 'order_by', 'report_age_field', 'include_comment_counts' ],
    [ 'Problem.pm', 'include_comment_counts', 'order_by', '-desc', 'comment_count' ],
    [ 'Nearby.pm', 'nearby', 'report_age_field', 'order_by', 'distance' ],
    [ 'Bromley.pm', 'munge_load_and_group_problems', 'search' ],
);
printf "PPI %s | Perl source tokens and containing named subroutine\n", $PPI::VERSION;
for my $file (@files) {
    my $doc = PPI::Document->new($file) or die "Cannot parse ${file}: " . PPI::Document->errstr;
    $doc->index_locations;
    my $subs = $doc->find('PPI::Statement::Sub') || [];
    for my $probe (grep { $file =~ m{(?:^|/)\Q$_->[0]\E$} } @edges) {
        my (undef, $name, @needles) = @$probe;
        my ($sub) = grep { ($_->name || '') eq $name } @$subs;
        die "Missing ${file}::$name\n" unless $sub;
        print "\n$file:", $sub->line_number, "  $name\n";
        my $tokens = $sub->find('PPI::Token') || [];
        for my $needle (@needles) {
            my %lines;
            for my $tok (@$tokens) {
                next if $tok->isa('PPI::Token::Comment') || $tok->isa('PPI::Token::Pod');
                my $val = $tok->content;
                next unless $val =~ /(?<![\w:])\Q$needle\E(?![\w:])/;
                $lines{$tok->line_number} = 1;
            }
            die "Missing token $needle in ${file}::$name\n" unless %lines;
            printf "  %-35s %s\n", $needle, join(', ', sort { $a <=> $b } keys %lines);
        }
    }
}
