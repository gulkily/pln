#!/usr/bin/perl -T

# writes to index.html a listing of all the files in the repo

$ENV{PATH}="/bin:/usr/bin"; #this is needed for -T to work

use strict;
use warnings;
use 5.010;

use URI::Encode qw(uri_decode);
use HTML::Entities qw(decode_entities);

# tell the browser we're working on the request
print "HTTP/1.1 200 OK\n";
print "Content-Type: text/html\n";
print "\n";

sub encode_entities2 { # returns $string with html entities <>"& encoded
	my $string = shift;
	if (!$string) {
		return;
	}

	#WriteLog('encode_entities2() BEGIN, length($string) is ' . length($string));
	#WriteLog('encode_entities2() BEGIN, $string = ' . $string);

	$string =~ s/&/&amp;/g;
	$string =~ s/\</&lt;/g;
	$string =~ s/\>/&gt;/g;
	$string =~ s/"/&quot;/g;

	return $string;
} # encode_entities2()

sub htmlspecialchars { # $text, encodes supplied string for html output
	# port of php built-in
	my $text = shift;
	$text = encode_entities2($text);
	return $text;
}

# find the files in the current directory
my @files = `find . | grep txt\$ | sort -r`; # list text files first
my @moreFiles = `find . | grep -v txt\$`; # then list all other files
push @files, @moreFiles; # combine the arrays

# write to index.html in current directory
my $filePath = ".";
open(my $fh, ">", "$filePath/index.html");

# put the write form at the top
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

	# store table row to append to file
	my $tableRow = '';

	# print the beginning of the row
	$tableRow .= "<tr>";
	$tableRow .= "<td>";
	$tableRow .= "<a href=$file>";
	$tableRow .= "\n";

	if ($file =~ m/\.html$/) {
		# print names of .html files in bold
		$tableRow .= "<b>$file</b>";
	} elsif($file =~ m/\.txt$/) {
		# for text files, try to summarize them
		# very basic summarize

		# get the file contents using cat utility
		my $fileContent = `cat $file`;
		chomp $fileContent;

		# [17/Apr/2023 07:34:41]
		# "GET /post.html?text=thank+you HTTP/1.1"

		#if ($fileContent =~ m/"GET \/post.html?text=(.+) HTTP\/1\.1"/) {
		if (
			$fileContent =~ m/"GET \/post\.html\?text=(.+) /
		) {
			my $messageOut = $1;
			$messageOut =~ s/\+/ /g;
			$messageOut = uri_decode($messageOut);
			$messageOut = decode_entities($messageOut);
			$messageOut = htmlspecialchars($messageOut);
			$tableRow .= $messageOut;
		} elsif (
			$fileContent =~ m/"GET \/cgi-bin\/post\.pl\?text=(.+) /
		) {
			my $messageOut = $1;
			$messageOut =~ s/\+/ /g;
			$messageOut = uri_decode($messageOut);
			$messageOut = decode_entities($messageOut);
			$messageOut = htmlspecialchars($messageOut);
			$tableRow .= '<small>' . $messageOut . '</small>';
			next;
		} else {
			# fallback to just the file content
			$tableRow .= htmlspecialchars($fileContent);
		}
	} else {
		# for all other files, just print the name
		$tableRow .= htmlspecialchars("$file");
	}

	# print the end of the row, including the file timestamp
	$tableRow .= "\n";
	$tableRow .= "</a>";
	$tableRow .= "<br>";
	$tableRow .= "\n";
	$tableRow .= "</td>";

	$tableRow .= "<td>";
	$tableRow .= $fileModTime;
	$tableRow .= "</td>";

	$tableRow .= "</tr>";

	# output table row to file
	print $fh $tableRow;
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