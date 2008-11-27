#!/usr/bin/perl -w
use warnings;
use diagnostics;
use strict;

$|=1;

#--------------------------------------------------- CONFIG
#{{{
{
package config;

my %vars = ( 'sleep' => 60,
             'queries' => 3,
             'command' => 'traceroute -T -p 80 -n -q %d %s 2>/dev/null',
             'target' => undef,
             'source' => 'localhost');

sub usage {
  print "$0 <config-file>\n";
  exit(0);
}

sub init {
  my ($filename) = @_;
  usage() unless(defined $filename && -f $filename && -s $filename);
  open(CONF,"< $filename") || die("reading config file $filename: $!");
  while(<CONF>) {
    # trim white spaces and comments
    s/^\s+|\s+$//sg;
    s/^#.*//;
    # parse value
    if (/^(\S+)\s+(.*)/) {
      $vars{$1} = $2;
    }
  }
  close(CONF);
}

sub get_db_config {
  return @vars{"db_name","db_host","db_username","db_password"};
}

sub get {
  my ($key,$default) = @_;
  return $vars{$key} if(defined $vars{$key});
  return $default;
}

}

#}}}

#------------------------------------------------- DB
#{{{

{
package db;
use DBI;

my $dbh;
my $session_id;
my %q;

sub init {
  my ($db_name,$db_host,$username,$password) = @_;
  # connect to database
  $dbh = DBI->connect("DBI:mysql:dbname=$db_name:$db_host",$username,$password);
  die("could not connect to database: $! ") unless($dbh);
  # get session id
  $dbh->do('INSERT INTO scriptrun VALUES(NULL,?,?,UNIX_TIMESTAMP(NOW()),UNIX_TIMESTAMP(NOW()),NOW(),NOW(),?,?,?)',undef,
                       config::get('source'),config::get('target'),config::get('command'),config::get('sleep'),config::get('queries'));
  $session_id = $dbh->last_insert_id(undef,undef,qw( scriptrun id ));
  # prepare queries
  $q{'insert_run'} = $dbh->prepare('INSERT INTO trrun VALUES(NULL,?,UNIX_TIMESTAMP(NOW()),NOW())');
  $q{'update_session'} = $dbh->prepare('UPDATE scriptrun SET timeunixstop=UNIX_TIMESTAMP(NOW()),timehumanstop=NOW() WHERE id=?');
}

sub done {
  # finish prepared queries
  foreach (keys %q) {
    $q{$_}->finish();
  }
  # disconnect from DB
  $dbh->disconnect();
}

sub update_session {
  $q{'update_session'}->execute($session_id);
}

sub commit_data {
  return unless(scalar(@_));
  # get ID for this run
  $q{'insert_run'}->execute($session_id);
  my $id = $dbh->last_insert_id(undef,undef,qw( trrun id ));
  return unless($id);
  # submit all records as a bulk-query (faster!)
  $dbh->do('INSERT INTO trrunhop VALUES '.
            join(',',map{"(NULL,$id,".join(',',map{$dbh->quote($_)} @$_).')'} @_));
}

}

#}}}

#------------------------------------------------- route

my $quit = 0;
$SIG{'TERM'} = $SIG{'INT'} = sub{ 
  print "terminating...\n";
  $quit = 1;
};

sub make_run {
  my ($host,$cmd) = @_;
  my @record;

  print $host,'..';
  # run and parse traceroute
  unless(open(CMD,"$cmd |")) {
    warn("could not run $cmd: $!");
    return;
  }
  PARSE: while(<CMD>) {
    # terminate, if CTRL-C was pressed
    last PARSE if($quit);
    # ignore first line
    next PARSE if(/^traceroute to/);
    # get hop counter
    if (/^\s*(\d+)\s+(.*)/) {
      my ($hop,$data) = ($1,$2);
      print $hop,'..';
      # parse lines
      my ($ip,$ms,$probe);
      TOKEN: foreach (split(/\s+/,$data)) {
        # store record, if found a timeout ('*') or error message
        if (/^(\*|!\w*)/) {
          ++$probe;
          push @record, [ $hop, $ip, $probe, undef, $_ ];
          next TOKEN;
        }
        # store record, if found a time in 'ms'
        if ($_ eq 'ms') {
          ++$probe;
          push @record, [ $hop, $ip, $probe, $ms , undef ];
          next TOKEN;
        }
        # found floating value, store for later usage of 'ms'
        if (/^\d+\.\d+$/) {
          $ms=$_;
          next TOKEN;
        }
        # found IP
        if (/^\d+\.\d+\.\d+\.\d+$/) {
          $ip=$_;
          next TOKEN;
        }
        # some other token... ignore
      }
    } else {
      warn("malformed line $.: $_");
    }
  }
  # close external program
  close(CMD);
  # push data to DB
  db::commit_data(@record);
  # finish
  print "done\n";
}

#------------------------------------------------- main

config::init($ARGV[0]);
db::init(config::get_db_config());

my $cmd = config::get('command');
my $host = config::get('target');
my $queries = config::get('queries');
$cmd = sprintf($cmd,$queries,$host);
my $sleep = config::get('sleep');

while(! $quit) {
  make_run($host,$cmd);
  db::update_session();
  # sleeping
  SLEEP: for (0..$sleep) {
    last SLEEP if($quit);
    sleep(1);
  }
}
db::done();

# vim: et foldmethod=marker foldenable foldlevel=0 lbr ai nu fdc=1
