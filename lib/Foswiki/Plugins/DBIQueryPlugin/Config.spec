#---+ Extensions
#---++ DBIQueryPlugin
# **PERL**
# See the plugin documentation
$Foswiki::cfg{Plugins}{DBIQueryPlugin}{dbi_connections} = {
    connection1 => {
        usermap => {
            AdminGroup => {
                user => 'dbuser1',
                password => 'dbpassword1',
            },
            SpecialGroup => {
                user => 'specialdb',
                password => 'specialpass',
            },
        },
        user => 'guest',
        password => 'guestpass',
        driver => 'mysql',
        database => 'some_db',
        codepage => 'koi8r',
        host => 'your.server.name',
    },
    test => {
        usermap => {
            AdminGroup => {
                user => 'dbuser2',
                password => 'dbpassword2',
            },
            SomeUser => {
                user => 'someuser',
                password => 'somepassword',
            },
        },
        allow_do => {
            default => [qw(AdminGroup)],
            'Sandbox.SomeUserSandbox' => [qw(AdminGroup SpecialGroup)],
        },
        #user => 'nobody',
        #password => 'never',
        driver => 'mysql',
        database => 'test',
        # host => 'localhost',
    }
};


