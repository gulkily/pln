#!/usr/bin/perl -T

$ENV{PATH}="/bin:/usr/bin"; #this is needed for -T to work

use strict;
use warnings;
use 5.010;

use Cwd qw(cwd);
use Digest::SHA qw(sha1_hex);

# tell the browser we're working on the request
print "HTTP/1.1 200 OK\n";
print "Content-Type: text/html\n";
print "\n";

# define paths
my $myPath = '~/pln';
my $logFile = "$myPath/python3.log";

# get contents of log file and split into an array @log
my $logContents = `cat $logFile`;
my @log = split("\n", $logContents);

my $existingFiles = `find .`;

for my $line (@log) {
	#print "hi";
	#print $line;

	if (index($line, 'post') == -1) {
		next;
	}

	my $lineHash = sha1_hex($line);
	chomp $lineHash;
	if ($lineHash =~ m/^([0-9a-f]+)$/) {
		$lineHash = $1;
	}

	if (index($existingFiles, $lineHash) == -1) {
		my $fileTime = `date +%s`;
		chomp $fileTime;
		if ($fileTime =~ m/^([0-9]+)$/) {
			$fileTime = $1;
		}

		my $filePath = "/home/ilyag/pln/txt";
		open(my $fh, ">", "$filePath/$fileTime-$lineHash.txt");
		print $fh $line;
		close($fh);

		my $fileHash = `sha1sum $filePath/$fileTime-$lineHash.txt | cut -d ' ' -f 1`;
		chomp $fileHash;
		if ($fileHash =~ m/^([0-9a-f]+)$/) {
			$fileHash = $1;
		}

		if ($fileHash eq $lineHash) {
			# print "cool";
		} else {
			# print "bad";
		}
#
#		if ($fileHash) {
#			if (index($existingFiles, $fileHash) == -1) {
#				# `mv $filePath/$fileTime.txt $filePath/$fileHash.txt`;
#				`mv $filePath/$fileTime.txt $filePath/$fileTime-$fileHash.txt`;
#			} else {
#				`rm $filePath/$fileTime.txt`;
#			}
#		}
	}
}

`perl -T cgi-bin/make_links.pl`;

print "done";
print "<br>";
print "<a href=/>home</a>";
print "<script>window.location.href='/cgi-bin/make_links.pl';</script>";

1;
