#!/usr/bin/perl -w
use warnings;
use diagnostics;
use strict;
use Getopt::Long;
use DBI;

my $DB_FILE_NAME = 'dbfile';
my $CMD = 'traceroute -n -q %d %s 2>/dev/null';

$|=1;

#--------------------------------------------------- PRELUDE
sub usage {
  print "$0 [-s <sleep seconds>] -t <target> [-t...] ...\n";
  exit(0);
}

my ($sleep_interval,$queries,$help_me) = (60,3,0);
my @targets;

GetOptions( 'target|t=s@' => \@targets, 
            'sleep|s=i'  => \$sleep_interval,
            'queries|q=i'  => \$queries,
            'help|usage|h|u' => \$help_me);
usage() if($help_me || (!scalar(@targets)));

#------------------------------------------------- DB

my $dbargs = {'AutoCommit' => 1,
              'PrintError' => 1};
my $dbh;
my ($q_insert_run,$q_max_run_id,$q_insert_hop);

sub db_table {
  my ($name,$create) = @_;
  # try to check if table exists
  my $q;
  {
    local $SIG{'__WARN__'}=sub{};
    $q = $dbh->prepare("SELECT * FROM $name LIMIT 1");
  }
  if ($dbh->err()) {
    $dbh->do("CREATE TABLE $name ($create)");
    die($dbh->errstr()) if ($dbh->err());
  }
  $q->finish() if($q);
}

sub db_connect {
  # check for existence of SQLite-DB
  my @driver_names = DBI->available_drivers();
  my $found = 0;
  foreach(@driver_names){
    $found = 1 if (/sqlite/i);
  }
  die("did not find support for SQLite\n") unless($found);
  # connect to database
  $dbh = DBI->connect("dbi:SQLite:dbname=$DB_FILE_NAME",'','',$dbargs);
  die("could not connect to database: $! ") unless($dbh);
  # create tables, if not existing
  db_table('run','id INTEGER PRIMARY KEY,timestamp DATE,host TEXT,queries INTEGER');
  db_table('hop','run INTEGER,n INTEGER,ip TEXT,ms FLOAT,error TEXT');
  # queries
  $q_insert_run = $dbh->prepare('INSERT INTO run VALUES(NULL,DATETIME(\'now\'),?,?)');
  $q_max_run_id = $dbh->prepare('SELECT max(id) FROM run');
  $q_insert_hop = $dbh->prepare('INSERT INTO hop VALUES(?,?,?,?,?)');
}

sub db_close {
  $q_insert_run->finish();
  $q_insert_hop->finish();
  $dbh->disconnect();
}

#------------------------------------------------- route

my $quit = 0;
$SIG{'TERM'} = $SIG{'INT'} = sub{ 
  print "terminating...\n";
  $quit = 1;
};

sub make_run {
  my ($host) = @_;
  return unless($host);
  print $host,'..';
  # create new record in 'run'-table
  $q_insert_run->execute($host,$queries);
  $q_max_run_id->execute();
  my ($id) = $q_max_run_id->fetchrow_array();
  $q_max_run_id->finish();
  unless($id) {
    warn("could not create new record for host $host");
    return; 
  }
  # run and parse traceroute
  unless(open(CMD,sprintf($CMD,$queries,$host).' |')) {
    warn("could not run tcpdump: $!");
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
      my ($ip,$ms);
      TOKEN: foreach (split(/\s+/,$data)) {
        # ignore '*'
        next TOKEN if($_ eq '*');
        # store record, if found a time in 'ms'
        if ($_ eq 'ms') {
          $q_insert_hop->execute($id,$hop,$ip,$ms,undef);
          next TOKEN;
        }
        # found value of 'ms'
        if (/^\d+\.\d+$/) {
          $ms=$_;
          next TOKEN;
        }
        # found IP
        if (/^\d+\.\d+\.\d+\.\d+$/) {
          $ip=$_;
          next TOKEN;
        }
        if (/^!\w?/) {
          $q_insert_hop->execute($id,$hop,$ip,undef,$_);
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
  print "done\n";
}

#------------------------------------------------- main

db_connect();
while(! $quit) {
  make_run($_) foreach(@targets);
  # sleeping
  SLEEP: for (0..$sleep_interval) {
    last SLEEP if($quit);
    sleep(1);
  }
}
db_close();

# vim: et
