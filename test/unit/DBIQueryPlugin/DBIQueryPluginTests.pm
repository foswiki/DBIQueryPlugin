# See bottom of file for license and copyright information
use v5.16;
use strict;
use warnings;

package DBIQueryPluginTests;

use strict;
use warnings;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use Foswiki;
use Foswiki::Func;
use CGI;
use File::Temp;
use File::Copy;
use Data::Dumper;

use Foswiki::Plugins::DBIQueryPlugin;

sub new {
    my $this = shift()->SUPER::new(@_);

    $this->generate_test_methods;

    return $this;
}

# Set up the test fixture
sub set_up {
    my $this = shift;

    #say STDERR "THIS: $this";

    $this->SUPER::set_up();

    #say STDERR "set_up done";

    my $temp_dir = $this->{db_test_dir}->dirname;

    $this->registerUser( 'DummyGuest', 'Dummy', 'Guest',
        'nobody@some.domain.org' );
    $this->registerUser( 'JohnSmith', 'Jogn', 'Smith',
        'webmaster@some.domain.org' );

    $this->assert(
        Foswiki::Func::addUserToGroup(
            $this->{session}{user}, 'AdminGroup', 1
        ),
        "Failed to make $this->{session}{user} a new admin"
    );
    $this->assert(
        Foswiki::Func::addUserToGroup( 'DummyGuest', 'DummyGroup', 1 ),
        'Failed to add DummyGuest to DummyGroup' );
    $this->assert( Foswiki::Func::addUserToGroup( 'ScumBag', 'AdminGroup', 0 ),
        'Failed to make ScumBag a new admin' );
}

sub tear_down {
    my $this = shift;

    #say STDERR "tear down";

    delete $this->{db_test_dir};

    $this->SUPER::tear_down();
}

sub loadExtraConfig {
    my $this = shift;

    #say STDERR "SUPER::loadExtraConfig";

    $this->SUPER::loadExtraConfig();

    #say STDERR "loadExtraConfig";

    $this->{db_test_dir}   = File::Temp->newdir('dbiqp_tempXXXX');
    $this->{db_msgb_file}  = 'message_board_test.sqlite';
    $this->{do_test_topic} = $this->{_tests_data}{do}{default_topic};

    $Foswiki::cfg{Plugins}{DBIQueryPlugin}{Enabled}      = 1;
    $Foswiki::cfg{Plugins}{DBIQueryPlugin}{Debug}        = 0;
    $Foswiki::cfg{Plugins}{DBIQueryPlugin}{ConsoleDebug} = 0;
    $Foswiki::cfg{PluginsOrder} =
'TWikiCompatibilityPlugin,DBIQueryPlugin,SpreadSheetPlugin,SlideShowPlugin';

    $Foswiki::cfg{Contrib}{DatabaseContrib}{dieOnFailure}   = 0;
    $Foswiki::cfg{Extensions}{DatabaseContrib}{connections} = {
        mock_connection => {
            driver            => 'Mock',
            database          => 'sample_db',
            codepage          => 'utf8',
            user              => 'unmapped_user',
            password          => 'unmapped_password',
            driver_attributes => {
                mock_unicode   => 1,
                some_attribute => 'YES',
            },
            allow_do => {
                "$this->{test_web}.$this->{do_test_topic}" => [qw(AdminGroup)],
            },
            allow_query => {
                "$this->{test_web}.$this->{test_topic}" =>
                  [qw(DummyGroup AdminGroup)],
            },
            usermap => {
                DummyGroup => {
                    user     => 'dummy_map_user',
                    password => 'dummy_map_password',
                },
            },

            # host => 'localhost',
        },
        sqlite_connection => {
            driver            => 'SQLite',
            database          => $this->{db_test_dir}->dirname . "/db.sqlite",
            codepage          => 'utf8',
            driver_attributes => { sqlite_unicode => 1, },
        },
        msg_board_sqlite => {
            driver   => 'SQLite',
            database => $this->{db_test_dir}->dirname . "/"
              . $this->{db_msgb_file},
            codepage          => 'utf8',
            driver_attributes => { sqlite_unicode => 1, },
        },
    };
}

sub generate_test_methods {
    my $this = shift;

    my $inclusion_topic_name = "InclusionTestTopic";
    my $do_test_text         = "DBI_DO test ok!";
    my $do_test_topic        = 'Do' . $this->{test_web};
    my $dbi_code_topic       = 'ScriptTestTopic';
    my $do_error_text        = qq(<strong><span class='foswikiRedFG'>ERROR:
<pre>No access to modify mock&#95;connection DB at TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests.$do_test_topic.
</pre></span></strong>);

    $this->{_tests_data} = {
        version => {

            #default_topic => $this->{do_test_topic},
            topics => { default => '%DBI_VERSION%', },
            result => "$Foswiki::Plugins::DBIQueryPlugin::VERSION",
        },
        query => {
            topics => {
                default => q(
%DBI_QUERY{"mock_connection"}%
SELECT col1, col2 FROM test_table
.header
|*Col1*|*Col2*|
.body
|%col1%|%col2%|
%DBI_QUERY%),
            },
            users => {
                ScumBag => q(<nop>
<table border="1" class="foswikiTable" rules="none">
<thead>
    <tr class="foswikiTableOdd foswikiTableRowdataBgSorted0 foswikiTableRowdataBg0">
        <th class="foswikiTableCol0 foswikiFirstCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=0;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">Col1</a> </th>
        <th class="foswikiTableCol1 foswikiLastCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=1;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">Col2</a> </th>
    </tr>
</thead>
<tbody>
    <tr style="display:none;">
        <td></td>
    </tr>
</tbody>
</table>),
                DummyGuest => q(<nop>
<table border="1" class="foswikiTable" rules="none">
<thead>
    <tr class="foswikiTableOdd foswikiTableRowdataBgSorted0 foswikiTableRowdataBg0">
        <th class="foswikiTableCol0 foswikiFirstCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=0;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">Col1</a> </th>
        <th class="foswikiTableCol1 foswikiLastCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=1;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">Col2</a> </th>
    </tr>
</thead>
<tbody>
    <tr style="display:none;">
        <td></td>
    </tr>
</tbody>
</table>),
                JohnSmith => q(<strong><span class='foswikiRedFG'>ERROR:
<pre>No access to query mock&#95;connection DB at TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests.TestTopicDBIQueryPluginTests.
</pre></span></strong>),
            },
        },
        code => {
            topics => {
                default => q(
%DBI_CODE{"script"}%
print 'It works!';
%DBI_CODE%),
            },
            users => {
                ScumBag => q(<table width="100%" border="0" cellspacing="5px">
    <tr>
        <td nowrap> <strong>Script name</strong> </td>
        <td> <code>script</code> </td>
    </tr>
    <tr valign="top">
        <td nowrap> <strong>Script code</strong> </td>
        <td> <pre>
            print 'It works!';
        </pre> </td>
    </tr>
</table>
),
                JohnSmith => q(<table width="100%" border="0" cellspacing="5px">
    <tr>
        <td nowrap> <strong>Script name</strong> </td>
        <td> <code>script</code> </td>
    </tr>
    <tr valign="top">
        <td nowrap> <strong>Script code</strong> </td>
        <td> <pre>
            print 'It works!';
        </pre> </td>
    </tr>
</table>
),
            },
        },
        subquery => {
            topics => {
                default => q(%DBI_CALL{"test_subquery"}%
%DBI_QUERY{"mock_connection" subquery="test_subquery"}%
SELECT f1, f2 FROM test_table
.header
|*First Column*|*Second Column*|
.body
|%f1%|%f2%|
%DBI_QUERY%
),
            },
            users => {
                ScumBag => q(<nop>
<table border="1" class="foswikiTable" rules="none">
    <thead>
        <tr class="foswikiTableOdd foswikiTableRowdataBgSorted0 foswikiTableRowdataBg0">
            <th class="foswikiTableCol0 foswikiFirstCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=0;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">First Column</a> </th>
            <th class="foswikiTableCol1 foswikiLastCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=1;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">Second Column</a> </th>
        </tr>
    </thead>
    <tbody>
        <tr style="display:none;">
            <td></td>
        </tr>
    </tbody>
</table>
),
                DummyGuest => q(<nop>
<table border="1" class="foswikiTable" rules="none">
    <thead>
        <tr class="foswikiTableOdd foswikiTableRowdataBgSorted0 foswikiTableRowdataBg0">
            <th class="foswikiTableCol0 foswikiFirstCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=0;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">First Column</a> </th>
            <th class="foswikiTableCol1 foswikiLastCol foswikiLast"> <a href="/bin//TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests/TestTopicDBIQueryPluginTests?sortcol=1;table=1;up=0#sorted_table" rel="nofollow" title="Sort by this column">Second Column</a> </th>
        </tr>
    </thead>
    <tbody>
        <tr style="display:none;">
            <td></td>
        </tr>
    </tbody>
</table>
),
                JohnSmith => q(<strong><span class='foswikiRedFG'>ERROR:
<pre>No access to query mock&#95;connection DB at TemporaryDBIQueryPluginTestsTestWebDBIQueryPluginTests.TestTopicDBIQueryPluginTests.
</pre></span></strong>),
            },
        },
        do => {
            default_topic => $do_test_topic,
            topics        => {
                default => qq(\%DBI_DO{"mock_connection"}%
\$rc = "$do_test_text";
%DBI_DO%
),
            },
            users => {
                ScumBag    => $do_test_text,
                DummyGuest => $do_error_text,
                JohnSmith  => $do_error_text,
            },
        },
        include => {
            default_topic => $do_test_topic,
            topics        => {
                default =>
                  qq(\%INCLUDE{"$this->{test_web}.$inclusion_topic_name"}%),
                $inclusion_topic_name => qq(\%DBI_DO{"mock_connection"}%
\$rc = "$do_test_text";
%DBI_DO%
),
            },
            users => {
                ScumBag    => $do_test_text,
                DummyGuest => $do_error_text,
                JohnSmith  => $do_error_text,
            },
        },
        crosstopic_do => {
            default_topic => $do_test_topic,
            topics        => {
                default =>
qq(\%DBI_DO{"mock_connection" topic="$this->{test_web}.$dbi_code_topic" script="test_script"}%),
                $dbi_code_topic => qq(\%DBI_CODE{"test_script"}%
\$rc = "$do_test_text";
%DBI_CODE%
),
            },
            users => {
                ScumBag    => $do_test_text,
                DummyGuest => $do_error_text,
                JohnSmith  => $do_error_text,
            },
        },
    };

    # Generate subs for tests
    foreach my $test ( keys %{ $this->{_tests_data} } ) {
        my $test_sub = "sub test_$test { \$_[0]->run_test(\"$test\"); }; 1;";
        die "Cannot generate test `$test': $@" unless eval $test_sub;
    }
}

sub expand_source {
    my $tt = $_[0]->{test_topicObject};
    return $tt->renderTML( $tt->expandMacros( $_[1] ) );
}

sub prepare_new_session {
    my $this = shift;
    my ( $user, $web, $topic ) = @_;

    my ( $request, $session );
    $this->assert_not_null( $request = Unit::Request->new(),
        "Failed to create a new request" );
    $request->path_info("/$web/$topic");

    $this->assert_not_null( $session =
          $this->createNewFoswikiSession( $user, $request ),
        "Failed to create a new session" );

    return $session;
}

sub run_test {
    my $this = shift;
    my ($test) = @_;

    my $test_data = $this->{_tests_data}{$test};

    my $default_topic = $test_data->{default_topic} // $this->{test_topic};
    my @users;

    if ( defined $test_data->{users} ) {
        @users = keys %{ $test_data->{users} };
    }
    else {
        @users = qw(ScumBag);
        $test_data->{users}{ScumBag} = $test_data->{result};
    }

    foreach my $user (@users) {
        my $session =
          $this->prepare_new_session( $user, $this->{test_web},
            $default_topic );

        # Propagate test web with topics.
        foreach my $topic ( keys %{ $test_data->{topics} } ) {
            my $new_topic = $topic eq 'default' ? $default_topic : $topic;

            my $new_topic_object = Foswiki::Meta->new(
                $session,   $this->{test_web},
                $new_topic, $test_data->{topics}{$topic}
            );
            $new_topic_object->save;
        }

        my $t_html = $this->expand_source( $test_data->{topics}{default} );

        #say STDERR "Test $test, user $user:\n----\n", $t_html, "\n----";
        $this->assert_html_equals( $test_data->{users}{$user},
            $t_html, "Test $test for user $user: HTML doesn't match" );
    }
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-%$CREATEDYEAR% Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
