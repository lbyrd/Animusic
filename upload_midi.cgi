#!/usr/bin/perl 
use CGI;
use File::Compare;
use DBI;
$use_cgi = 'on';
my $port = 3306;
my $dsn = "DBI:mysql:database=midieval;host=localhost;port=$port";
my $user = "root";
my $password = "midieval";

my $basepath = "/var/www/html";
my $upload_dir = "$basepath/uploads";
$query = new CGI;

my $safe_filename_characters = "a-zA-Z0-9_.-";

my $refresh = $query->param("refresh");
my $path = $query->param("path");
my $filename = $query->param("file");
my $songname = $query->param("name");
$filename =~ s/.*[\/\\](.*)/$1/;
$upload_filehandle = $query->upload("file");
$bid = $query->param("bid");

if(!$filename) { 
	
	print "Content-Type: text/html; charset=UTF-8", "\n\n";

	print qq ~<html><head><script type="text/javascript" src="/jquery.min.js"></script>
	<title>Midi::Eval</title>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
	<link href="/css/bootstrap.min.css" rel="stylesheet">

	</head>~;

	print qq ~<body><br><br><center>~;
	
	get_file();
	exit;
}



$filename =~ s/[^$safe_filename_characters]//g;

if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {
	$filename = $1;
} else {
	print qq ~ERROR: Filename contains invalid characters~;
	die "Filename contains invalid characters";
}

# Checking to see if the file exists

my $newfilename = filefinder23($filename);

my $refresh_ext = "&filename=$newfilename&bid=$bid";

#print "<br> New Filename: $newfilename<br>\n";

# binmode example
#open(my $fh, ">", $ARGV[3]);
#binmode($fh);


  
# Create the DB entry for this file
my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1});
my $affected = $dbh->do("INSERT INTO song(name,filename) VALUES (?, ?)", undef, $songname, $newfilename);
print "affected:$affected<br>\n";
die "$dbh->errstr" if(!$affected);
die "No rows update" if($affected eq '0E0');
#my $sth = $dbh->prepare("INSERT INTO song(name,filename) values (?,?)");
#$sth->execute( $songname, $newfilename);

#$sth->finish;

open UPLOADFILE, ">$upload_dir/$newfilename";
binmode(UPLOADFILE);
while ( <$upload_filehandle> ) { $image .= $_; }
print UPLOADFILE $image;
close UPLOADFILE;

$dbh->disconnect;

print qq ~COMPLETE!<br>\n~;
  
#if($refresh) { $refresh .= $refresh_ext; refresh($refresh); }

# new function
sub filefinder23 {
	my $file;
	my $filename = shift;
	my $num = shift;
	
	my @parts = split(/\./,$filename);
	my $c = @parts;
	$ext = $parts[$c-1];
	delete $parts[$c-1];
	foreach(@parts) {
		$file .= $_;
	}
	
	print "File $file<br> Ext: $ext<br>";

	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$upload_dir/$file$num.$ext");

	if(defined($gid)) {
		# See if the files have the same content
		seek $upload_filehandle, 0, 0;
		if(compare($upload_filehandle,"$upload_dir/$file$num.$ext") == 0) {
			seek $upload_filehandle, 0, 0;
			print qq ~This file is the same as $upload_dir/$file$num.$ext<br>~;
			
			return "$file$num.$ext";  # No need to upload a file, it is already here
		}
		$num++; $filename = filefinder23("$file.$ext", $num); return $filename;
	}

	return $file . $num . "." . $ext;
}

# Old function
sub filefinder2 {
	my $file;
	my $filename = shift;
	my $num = shift;
	
	my @parts = split(/\./,$filename);
	my $c = @parts;
	$ext = $parts[$c-1];
	delete $parts[$c-1];
	foreach(@parts) {
		$file .= $_;
	}
	
#	print "File $file<br> Ext: $ext<br>";

	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$upload_dir/$file$num.$ext");

	if(defined($gid)) { $num++; $filename = filefinder2("$file.$ext", $num); return $filename; }
	
	

	return $file . $num . "." . $ext;
}

sub get_file {
	my $refresh_val = $ENV{'SCRIPT_NAME'};
	
	print qq ~

	<form name="form1" method="POST" action="/cgi-bin/upload_midi.cgi" enctype="multipart/form-data">

	Choose a Song Name: <input type="text" name="name"> AND <br>
	Choose a File: <input type="file" name="file">

	<input type="hidden" name="path" value="$basepath/uploads">
	<input type="hidden" name="refresh" value="$refresh_val?hasfile=1">
	THEN
	<input type="Submit" name="Submit" value="Submit">
	
	</form>
	~;
}
