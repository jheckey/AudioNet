#!/usr/bin/perl
#
# $Header:$
#
# extract_hier.pl Copyright (c) 2001 by Matthew Welland
#
# A simple script to extract the hierarchy from a set of verilog files.
#  Many assumptions are made about the coding style and consequentially
#  this script will only work for SOME verilog files.
#
# Typical usage: $ extract_hier .:../library top_level.v > run_top_level.mft
#                $ iverilog -s top_level `cat run_top_level.mft`
#                       OR
#                $ iverilog -s top_level -c run_top_level.mft
#
# Where .mft -> implies manifest file. Note: I usually use the former 
#  invocation of iverilog because I will put switches in the mft file
#  - especially -I../includes
# 
# This script may be distributed under the GNU General Public License.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#  If you enhance this script or make use of it I would love to hear about 
#  it at matt@essentialgoods.com
# 
if (! defined $ARGV[0] && ! defined $ARGV[1]) {
  print "Usage: extract_books.pl path1:path2:path3... top_level.v\n";
  exit(1);
}
($search_path,$file)=@ARGV;

@search_path=split(':',$search_path);

$files{$file}=1;
%modules=();
%books=();
%cantfind=();
%already_done=();
$status=&process($file);
exit($status);

sub process {
  my ($file)=@_;
  my ($full_path,
      $module,
      $usage);
  # print STDERR "Processing file $file\n";
  $full_path=&find_file($file,@search_path);
  if (! $full_path) {
    if (! defined $cantfind{$file}) {
      $cantfind{$file}=1;
      print STDERR "Can't find $file - skipping it.\n";
    }
    return 0;
    $files{$file}=undef;
  } else {
    if (! defined $files{$file}) {
      print "$full_path\n";
      $files{$file}=1;
    }
  }
  open(INF,"$full_path") || die "Problem opening file $full_path: $!\n";

  # tally all the book usages and modules define in this file
  while (<INF>) {
    next if m/^\s*\`/;   # skip any defines
    next if m/^\s*\/\//; # skip comments
    if (/^\s*module\s+([^\s\(]+)/) {
      $module=$1;
      if (defined $modules{$1}) {
	$modules{$1}++;
      } else {
	$modules{$1}=1;
      }
      next;
    } elsif (/^\s*endmodule/) {
      $module=undef;
      next;
    }
    #     LIBARY_ELEMENT_NAME    INSTANCE_NAME (
    if (/^\s*([^\s,\)\(;\`:\*\'\[\]]+)\s+([^\s\)\(;=\`:\*\'\]\[;]+)\s*\({0,1}/) {
      $book=$1;
      # skip builtin logic and misc stuff
      if ($book=~m/^(event|assign|primitive|initial|defparam|integer|nor|always|not|nand|reg|input|output|and|or|wire|parameter|task|else|buf|xor)$/) {
	next;
      }
      if ($book=~/^[0-9\?]$/) { next; } # need more than a single digit for an identifier
      if (defined $books{$1}) {
	$books{$1}++;
      } else { 
	$books{$1}=1;
      }
    }      
  }
  close INF;
  # if we don't yet have a module definitition we need to look for it
  foreach $usage (keys %books) {
    if (! defined $modules{$usage} && ! defined $already_done{$usage}) {
      # Attempt to process a file by the name $usage.v
      &process("$usage.v",@search_path);
      $already_done{$usage}=1;
    }
  }
}
    
sub find_file {
  my ($file,@search_path) = @_;
  my $full_path;
  foreach $path (@search_path) {
    $full_path="$path/$file";
    $full_path=~s/\/+/\//g; # remove any double slashes
    if (-e $full_path) {
      return $full_path;
    }
  }
  return 0;
}
 
# 
# $Log:$
#
