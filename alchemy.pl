#!/usr/bin/perl
use strict;
use warnings;

my %items;
sub print_item
{
	my $file = shift;
	my $owner = shift;
	my $item = shift;
	my $ownername = shift;
	my $name = "$ownername-$item"; # - as the delimiter
	my $count = $items{$owner}{ingredients}{$item};
	my $colour = "";
	$colour = "color=\"green\"" if ($items{$item}{purchasable});

	# Check for infinite recursion
	my @things = split(/\-/,$name);
	my $first_thing = pop @things;
	if (grep { $first_thing eq $_ } @things)
	{
		print $file "\"$item\" -> \"$ownername\" [label=\"$count\"];\n";
		return;
	}

	print $file "\"$name\" [label=\"$item\" $colour];\n";
	print $file "\"$name\" -> \"$ownername\" [label=\"$count\"];\n";

	# Print the ingredients of each component ingredients
	for my $ing (keys %{$items{$item}{ingredients}})
	{
		print_item($file,$item,$ing,$name);
	}
};

my $shops_mode = 0;
while(<>)
{
	if (/^\s?\d+\) (.+)/)
	{
		my $item = $1;
		my $ing = <>; chomp $ing;
		$ing =~ s/\=|\+//g;
		while($ing =~ s/\s*(.*?)\s+x\s+(\d+)//)
		{
			$items{$item}{ingredients}{$1} = $2;
			$items{$1}{used} = (exists $items{$1}{used} ? $items{$1}{used}+1 : 0);
		}		
	}
	if (/(~-)+.*(Shops)/)
	{
		$shops_mode = 0;
		$shops_mode = 1 if ($2 eq "Shops");
	}

	if ($shops_mode)
	{
		if (/(.*):/)
		{
			$items{$1}{purchasable} = 1;
		}
	}
}

open(my $index,">","index.html");
print $index <<EOF_INDEX;
<html>
<head>
<title>Dragon Quest 9 Alchemy Dependency Graphs</title>
</head>
<body>
<ul style="column-count:4; -moz-column-count:4; -webkit-column-count:4;">
EOF_INDEX

for my $i (sort keys %items)
{
	# Print only items with ingredients, and don't bother printing items that are resets of something else.
	if (keys %{$items{$i}{ingredients}} and !exists $items{$i}{ingredients}{'Reset stone'})
	{
		my $filename = $i;
		$filename =~ s/'| //g;
		open(my $file, '>',$filename.".dot");
	
		print $file "digraph \"$i\" {\n";
		for my $j (keys %{$items{$i}{ingredients}})
		{
			print_item($file,$i,$j,$i);
		}
		print $file "{rank=max; \"$i\";};\n"; # Makes sure the target item is at the bottom
		print $file "}\n";
		
		close $file;

		print $index "<li><a href=\"images/$filename.svg\">$i</a></li>\n";
	}
}
print $index <<EOF_INDEX2;
</ul>
</body>
</html>
EOF_INDEX2

close $index;
