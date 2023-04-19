#!/usr/bin/perl -T

use strict;
use warnings;
use 5.010;

use URI::Encode qw(uri_decode);
use HTML::Entities qw(decode_entities);

# writes to index.html a listing of all the files in the repo

$ENV{PATH}="/bin:/usr/bin"; #this is needed for -T to work

# tell the browser we're working on the request
print "HTTP/1.1 200 OK\n";
print "Content-Type: text/html\n";
print "\n";

# find the files in the current directory
my @files = `find . | grep txt\$ | sort -r`;
my @moreFiles = `find . | grep -v txt\$`;
push @files, @moreFiles;

# write to index.html in current directory
my $filePath = ".";
open(my $fh, ">", "$filePath/index.html");

print $fh `cat write.html`;

# print the table header
print $fh "<table border=1>";
print $fh "<tr><th onclick=SortTable(this)>file</th><th onclick=SortTable(this)>time</th></tr>";

# loop through all the files and write the file list
for my $file (@files) {
	chomp $file;

	# sanitize the file name
	if ($file && $file =~ m/^([0-9a-zA-Z.\-_\/]+)$/) {
		$file = $1;
	} else {
		# bad
		next;
	}

	# ignore dot-files (names begin with a dot)
	if ($file =~ m/^\.\/\./) {
		next;
	}

	# ignore archive directory
	if ($file =~ m/^\.\/archive/) {
		next;
	}

	# ignore directories
	if (-d $file) {
		next;
	}

	# get the timestamp and size of the file
	my @fileStat = stat($file);
	my $fileSize =    $fileStat[7];
	my $fileModTime = $fileStat[9];

	# print the beginning of the row
	print $fh "<tr>";
	print $fh "<td>";
	print $fh "<a href=$file>";
	print $fh "\n";

	if ($file =~ m/\.html$/) {
		# print names of .html files in bold
		print $fh "<b>$file</b>";
	} elsif($file =~ m/\.txt$/) {
		# for text files, try to summarize them
		# very basic summarize

		my $fileContent = `cat $file`;
		chomp $fileContent;

		# [17/Apr/2023 07:34:41]
		# "GET /post.html?text=thank+you HTTP/1.1"
		#if ($fileContent =~ m/"GET \/post.html?text=(.+) HTTP\/1\.1"/) {
		if (
			$fileContent =~ m/"GET \/post\.html\?text=(.+) HTTP\/1\.1"/
			||
			$fileContent =~ m/"GET \/cgi-bin\/post\.pl\?text=(.+) HTTP\/1\.1"/
		) {
			my $messageOut = $1;
			$messageOut =~ s/\+/ /g;
			$messageOut = uri_decode($messageOut);
			$messageOut = decode_entities($messageOut);
			print $fh $messageOut;
		} else {
			# print $fh $file;
			print $fh $fileContent;
		}
	} else {
		# for all other files, just print the name
		print $fh "$file";
	}

	# print the end of the row, including the file timestamp
	print $fh "\n";
	print $fh "</a>";
	print $fh "<br>";
	print $fh "\n";
	print $fh "</td>";

	print $fh "<td>";
	print $fh $fileModTime;
	print $fh "</td>";

	print $fh "</tr>";
}

# close the table
print $fh "</table>";

# inject table sorting js module into page
print $fh '<script>' . `cat ./js/table_sort.js` . '</script>';

# close file handle
close($fh);

# tell the user we're done, return to home page
print "done";
print "<br>";
print "<a href=/>home</a>";
print "<script>window.location.href='/';</script>";