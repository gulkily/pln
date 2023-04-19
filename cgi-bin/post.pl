#!/usr/bin/perl -T

# posts new item, calls update.pl, redirects to home

$ENV{PATH}="/bin:/usr/bin"; #this is needed for -T to work

use strict;
use warnings;
use 5.010;

use Cwd qw(cwd); # current working directory
use Digest::SHA qw(sha1_hex); # SHA1 hash
use CGI qw(param); # gets parameters from request

# tell the browser we're working on the request
print "HTTP/1.1 200 OK\n";
print "Content-Type: text/html\n";
print "\n";

my $text = param('text');
#todo sanity check on $text

sub PutFile { # $line ; writes new file to txt/
    my $line = shift; #todo change name from line to text

    my $existingFiles = `find .`; # listing of existing files
    # we can use this to look for existing copies of the file
    # by searching for the hash of the file

	my $lineHash = sha1_hex($line);
	chomp $lineHash;
	if ($lineHash =~ m/^([0-9a-f]+)$/) {
		$lineHash = $1;
	}
	# hash done with perl module

	if (index($existingFiles, $lineHash) == -1) {
	# hash was not found in existing file listing

		my $fileTime = `date +%s`;
		chomp $fileTime;
		if ($fileTime =~ m/^([0-9]+)$/) {
			$fileTime = $1;
		}
		# $fileTime will be prefix of filename

		my $filePath = "/home/ilyag/pln/txt"; #todo unhardcode path
		open(my $fh, ">", "$filePath/$fileTime-$lineHash.txt");
		print $fh $line;
		close($fh);
		# wrote to file
		# file is named e.g. 1234567890-abcdef0123467890abcdef0123456890.txt

		my $fileHash = `sha1sum $filePath/$fileTime-$lineHash.txt | cut -d ' ' -f 1`;
		chomp $fileHash;
		if ($fileHash =~ m/^([0-9a-f]+)$/) {
			$fileHash = $1;
		}
		# validate that hash made with sha1sum matches the one we made with perl

		if ($fileHash eq $lineHash) {
			# print "cool";
		} else {
			# print "bad";
		}
    }
} # PutFile()

if ($text) {
    PutFile($text);
    `perl -T ./cgi-bin/update.pl`
}

print "<script>window.location.href='/?'+Math.random();</script>";

1;

