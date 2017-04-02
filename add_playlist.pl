#!/usr/bin/perl 
use CGI;
use DBI;
$use_cgi = 'on';
my $port = 3306;
my $dsn = "DBI:mysql:database=midieval;host=localhost;port=$port";
my $user = "root";
my $password = "midieval";

$query = new CGI;

my @names = $query->param;
my %f;

#foreach(@names) { 
#	$f{$_} = $query->param($_);
#}

print "Content-Type: text/html; charset=UTF-8", "\n\n";
print qq ~<html><head><script type="text/javascript" src="/jquery.min.js"></script>
	<title>Midi::Eval</title>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
	<link href="/css/bootstrap.min.css" rel="stylesheet">

</head>~;

print qq ~<body>~;

foreach(@names) {
        $f{$_} = $query->param($_);
#        print "$_:$f{$_}<br>\n";
}

#foreach my $key(keys %f) {
#	print "$key: $f{$key}\n";
#}

if($f{name}) {
	$f{table} = "playlist";
	add(\%f);
} elsif($f{playlist_save}) {
	playlist_save($f{playlist_id});
	playlist_control($f{playlist_id});
} elsif($f{playlist_control}) {
	playlist_choose();
} elsif($f{playlist_id}) {
	playlist_control($f{playlist_id});	
} else {
	add_form("playlist");
}

sub playlist_save {
	print qq ~<center><br><br>~;
	my $playlist_id = shift;
	my $position = 0;
	my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1});
	my $affected = $dbh->do("DELETE FROM playlist_song WHERE playlist_id = ?", undef, $playlist_id );
	my @list = split(/,/, $f{serial_order});
	foreach(@list) {
		my $affected = $dbh->do("INSERT INTO playlist_song VALUES(?,?,?)", undef, $playlist_id, $_, $position++ );
	}	
	print "Playlist SAVED!<br>";
	print qq ~<br><a href="/cgi-bin/add_playlist.pl">BACK TO MENU</a>~;
}

sub playlist_choose {
	print qq ~<center><br><br>~;
	# Pick a Playlist to edit from the list
	print qq ~<h1>Pick a Playlist to Edit</h1><br>\n~;
	my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1});
	my $sth = $dbh->prepare('SELECT id,name FROM playlist') 
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute();
	while (@data = $sth->fetchrow_array()) { 
		print qq ~<a href="/cgi-bin/add_playlist.pl?playlist_id=$data[0]">$data[1]</a>&nbsp;&nbsp;&nbsp;<a href="/cgi-bin/add_playlist.pl?playlist_id=$data[0]&delete=on">[delete]</a><br>\n~;
	}
	print qq ~<br><a href="/cgi-bin/add_playlist.pl">BACK TO MENU</a>~;
}

sub playlist_control {
	if($f{delete} eq 'on') {
		my $playlist_id = $f{playlist_id};
		my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1});
		my $affected = $dbh->do("DELETE FROM playlist_song WHERE playlist_id = ?", undef, $playlist_id );
			die "$dbh->errstr" if(!$affected);
		my $affected = $dbh->do("DELETE FROM playlist WHERE id = ?", undef, $playlist_id );
			die "$dbh->errstr" if(!$affected);
		print qq ~$affected Playlist Deleted!~;
		playlist_choose(); exit;
	}
	print qq ~<center><br><br>~;
	my $playlist_id = shift;
	# 1. Get how many songs there are, make that the size of the select form
	# 2. Figure out what playlist we are on, use that to load the correct songs in order based on playlist_song.position
	my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1});
	# Check to see if this list already exists
	my $count;
	my $sth = $dbh->prepare('SELECT count(*) FROM song') 
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute();
	while (@data = $sth->fetchrow_array()) { $count = $data[0] }
	
	# Step 2
	my %p; # hash to hold things in playlist
	$sth = $dbh->prepare('SELECT song.id, song.name FROM playlist_song, song WHERE song_id = song.id AND playlist_id = ? ORDER BY position')	
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute($playlist_id);
	my $i = 0;
	while (@data = $sth->fetchrow_array()) { 
		$p{$data[0]} = $data[1];	
		$position[$i++] = $data[0];
	}
	$i--; # # $i is one too many
	# Get the list of songs NOT in the playlist 
	my %s; # hash to hold things not in playlist
	my $sth2 = $dbh->prepare('SELECT song.id, song.name FROM song WHERE not EXISTS (SELECT * FROM playlist_song WHERE song.id = song_id AND playlist_id = ?)')	
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth2->execute($playlist_id);
	while (@data = $sth2->fetchrow_array()) { 
		$s{$data[0]} = $data[1];	
	}
	# Get playlist name
	my $playlist_name;
	$sth = $dbh->prepare('SELECT name FROM playlist WHERE id = ?')
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute($playlist_id);
	while (@data = $sth->fetchrow_array()) { 	
		$playlist_name = $data[0];
	}
	
	
	print qq ~<form name="form1" method="GET">
		<input type="hidden" name="serial_order">
		<input type="hidden" name="playlist_save" value="1">
		<input type="hidden" name="playlist_id" value="$f{playlist_id}">
		<h1>Add and Re-order the tunes in Playlist $playlist_name</h1>
		The Left list are the tunes not in the playlist.  The Right list are the tunes in the playlist <i>in order</i>.<br>
  <fieldset>

    <select name="selectfrom" id="select-from" multiple size="$count">
	~;
	foreach my $key(keys %s) {
		print qq ~<option value="$key">$s{$key}</option>~;
	}
	print qq ~
    </select>
    <a href="JavaScript:void(0);" id="btn-add">Add &raquo;</a>
    <a href="JavaScript:void(0);" id="btn-remove">&laquo; Remove</a>
    <select name="selectto" id="select-to" multiple size="$count">
	~;
	my $serial_order; my $arraysize; my $list = "["; my $j;
	for($j = 0; $j <= $i; $j++) {
		$key = $position[$j];
		print qq ~<option value="$key">$p{$key}</option>~;
		$serial_order .= "$key,";
		$list .= "\"$key\",";
	}
	$arraysize = $j;
	chop $list;
	$list .= "]";
	print qq ~
    </select>
    <a href="JavaScript:void(0);" id="btn-up">Up</a>
    <a href="JavaScript:void(0);" id="btn-down">Down</a>
  </fieldset>
	<input type="Submit" name="Submit" value="Submit">
	<br><a href="/cgi-bin/add_playlist.pl">BACK TO MENU</a>
  </form>~;
  
  
  print qq ~<script language="Javascript">
  var list = new Array;
  var arraysize = 0;
  ~;
  
    if($serial_order) {
		my $e = chop $serial_order; # remove ,
		if($e ne ",") {
			$serial_order .= $e;
		}
		$e = chop $serial_order; # remove ,
		if($e ne ",") {
			$serial_order .= $e;
		}
		print qq ~
		window.document.form1.serial_order.value = "$serial_order";
		arraysize = $arraysize;
		list = $list;
		~;
	}
  
  print qq ~
  \$(document).ready(function() {
    \$('#btn-add').click(function(){
        \$('#select-from option:selected').each( function() {
                \$('#select-to').append("<option value='"+\$(this).val()+"'>"+\$(this).text()+"</option>");
            \$(this).remove();
			list[arraysize++] = \$(this).val();
        });
		window.document.form1.serial_order.value = list;
    });
    \$('#btn-remove').click(function(){
        \$('#select-to option:selected').each( function() {
            \$('#select-from').append("<option value='"+\$(this).val()+"'>"+\$(this).text()+"</option>");
            \$(this).remove();
			for(var i=0; i <= arraysize; i++) {
				if(\$(this).val() === list[i]) {
					list.splice(i, 1);
					arraysize--;
				}
			}
			window.document.form1.serial_order.value = list;
        });
    });
    \$('#btn-up').bind('click', function() {
        \$('#select-to option:selected').each( function() {
            var newPos = \$('#select-to option').index(this) - 1;
            if (newPos > -1) {
                \$('#select-to option').eq(newPos).before("<option value='"+\$(this).val()+"' selected='selected'>"+\$(this).text()+"</option>");
                \$(this).remove();
				var stop = 0;
				for(var i=0; i < arraysize; i++) {
					if(\$(this).val() == list[i] && stop == 0) {
						var tmp = list[i-1]; // swap positions
						list[i-1] = list[i];
						list[i] = tmp;
						stop = 1;
					}
				}
            }
			window.document.form1.serial_order.value = list;
        });
    });
    \$('#btn-down').bind('click', function() {
        var countOptions = \$('#select-to option').size();
        \$('#select-to option:selected').each( function() {
            var newPos = \$('#select-to option').index(this) + 1;
            if (newPos < countOptions) {
                \$('#select-to option').eq(newPos).after("<option value='"+\$(this).val()+"' selected='selected'>"+\$(this).text()+"</option>");
                \$(this).remove();
				var stop = 0;
				for(var i=0; i < arraysize; i++) {
					if(\$(this).val() == list[i] && stop == 0) {
//						alert("Down Loop: " + i);
						var tmp = list[i+1]; // swap positions, bottom on the list has the highest number
						list[i+1] = list[i];
						list[i] = tmp;
						stop = 1;
					}
				}
            }
//									alert(list);
//									alert(arraysize);
			window.document.form1.serial_order.value = list;
        });
    });
	});
	
	</script>~;
}

sub add_form {
	my $table = shift;
	if($table eq "playlist") {
		print qq ~<center><br><br>~;
		print qq ~<form name="form1">~;
#		print qq ~Enter the following values for this $table entry<br>~;
		print qq ~To Create a New Playlist, Enter its' name and Click Submit:<br>~;
		my $i=0;
		my @field = qw(name); # The fields to display to add things
		my @size = qw(50); # the sizes of the fields
		foreach(@field) {
			print qq ~<!--$_:--> <input type="text" name="$_" size="$size[$i++]"><br>\n~;
		}
		print qq ~<input type="Submit" name="Submit" value="Submit"><br>~;
	}
	print qq ~<a href="/cgi-bin/add_playlist.pl?playlist_control=1">Playlist Control</a><br>\n~;
	print qq ~<a href="/cgi-bin/upload_midi.cgi">Upload MIDI File</a><br>\n~;
}


sub add {
	my %r = %{(shift)};
	print qq ~<center><br><br>~;
	my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1});
	# Check to see if this list already exists
	if($r{name}) {
		my $sth = $dbh->prepare('SELECT * FROM '. $r{table} .' WHERE name = ?') # , $r{table}, $r{name} 
			or die "Couldn't prepare statement: " . $dbh->errstr;
		$sth->execute($r{name});
		while (@data = $sth->fetchrow_array()) {
			my $name = $data[1];
			print "ERROR: A $r{table} with this title already exists: $name<br>\n";
			return;
		}
	}	
#	my $affected = $dbh->do("INSERT INTO song(name,filename) VALUES (?, ?)", undef, $songname, $newfilename);
	# It does not exist, add it, ". $r{table} ."
	my $affected = $dbh->do("INSERT INTO playlist(name) VALUES (?)", undef, $r{name} );
	print "Rows Affected:$affected<br>\n";
	die "$dbh->errstr" if(!$affected);
	die "No rows update" if($affected eq '0E0');
	print qq ~<br><a href="/cgi-bin/add_playlist.pl">BACK TO MENU</a>~;
}

