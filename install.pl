#!/usr/bin/perl

use ExtUtils::MakeMaker qw(prompt);
use File::Copy;
use strict;
use Cwd;

my $cwd      = cwd;
my $readline = $^O =~ /Win32/i ? "Term::ReadLine::Perl" : "Term::ReadLine::Gnu";
my %libs     = map { $_ => 0 } qw/DBI Time::HiRes Term::ReadKey/, $readline;
my %drivers  = map { lc($_) => $_ } qw/
  DBMaker JDBC XBase Illustra Adabas DB2 Solid PrimeBase Ovrimos Fulcrum
  InterBase Ingres Oracle Excel ODBC mysql Unify SQLite Sybase LDAP Informix Pg
  PgPP mysqlPP Empress SearchServer CSV
  /;

&head();
print "Checking for required modules\n\n";

my @inst = &check(keys %libs);
print "\n";

&install(@inst);
print "\n";

my @drivers = sort eval("use DBI; DBI->available_drivers");
delete @drivers{ map { lc($_) } @drivers };
print "\nYou currently have the database drivers for:\n\t"
  . join("\n\t", @drivers) . "\n";
print "Additional available drivers to install:\n\t"
  . join("\n\t", sort values %drivers) . "\n";
print "\nChoose a single driver to install (we will return here later)\n";
print "OR enter nothing to continue installation\n";

while (1)
{
	print "enter> ";
	chomp(my $driver = lc <STDIN>);
	if (!$driver)
	{
		print "\nYou are equipped with the following drivers:\n\t"
		  . join("\n\t", sort eval("use DBI; DBI->available_drivers")) . "\n\n";
		last;
	}
	elsif ($drivers{$driver})
	{
		$libs{"DBD::$drivers{$driver}"} = 0;
		print "\n";
		&install(&check("DBD::$drivers{$driver}"));
	}
	else
	{
		print "No such driver!\n";
	}
}

print "Where should I install sql++ [/usr/local/bin]: ";
chomp(my $dir = <STDIN>);
$dir ||= "/usr/local/bin";
File::Copy::copy("sql++", "$dir/sql++");
chmod(0755, "$dir/sql++");

print
  "Installation complete!  Run `sql++` for help or check files in current directory...\n";
exit;

######################################
#
# subroutines
#
sub head
{
	print "sql++ by Samy Kamkar [code\@samy.pl] -- http://samy.pl/sql++\n\n";
	print "Welcome to the sql++ auto-install script!\n\n";
}

sub install
{
	foreach my $module (@_)
	{
		if (prompt("$module not installed.  Install (y/n)?", "y") =~ /^y/)
		{
			require CPAN;
			CPAN::Shell->install($module);
			delete $libs{$module};
			chdir $cwd or die "Can't chdir back to $cwd: $!";
		}
	}
}

sub check
{
	my @check = @_;
	my @notfound;

	foreach my $module (@check)
	{
		print substr("$module ............................", 0, 30);

		if ($module =~ /^Term::ReadLine::/)
		{
			my $version = eval "use Term::ReadLine; \$${module}::VERSION";
			if (eval("Term::ReadLine->ReadLine eq '$module'"))
			{
				print "found version $version\n";
			}
			else
			{
				print "** FAILED **\n";
				push(@notfound, $module);
			}

			next;
		}

		my $version = eval "use $module; \$${module}::VERSION";
		if ($version)
		{
			print "found version $version\n";
		}
		else
		{
			print "** FAILED **\n";
			push(@notfound, $module);
		}
	}

	return @notfound;
}
