#  Copyright (C) 2010  Stanislav Sinyagin
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

# RDBMS interface for Gerty handlers


package Gerty::DBLink;

use base qw(Gerty::HandlerBase);

use strict;
use warnings;

use DBI;
use Date::Format;

    
sub new
{
    my $class = shift;
    my $options = shift;
    my $self = $class->SUPER::new( $options );    
    return undef unless defined($self);

    if( not defined $options->{'dblink'} )
    {
        $Gerty::log->critical
            ('"dblink" is not provided to Gerty::DBLink->new() ' .
             'for device: ' . $self->sysname);
        return undef;
    }

    $self->{'dblink'} = $options->{'dblink'};
                
    foreach my $param ('dsn', 'username', 'password')
    {
        my $attr = $self->{'dblink'} . '.' . $param;        
        my $val = $self->device_attr($attr);
        if( not defined($val) )
        {
            $Gerty::log->critical
                ('Cannot initialize DBLink: attribute "' . $attr  .
                 '" is undefined for device: ' . $self->sysname);
            return undef;            
        }
        $self->{$param} = $val;
    }

    if( lc($self->{'dsn'}) =~ /^dbi:oracle:/ )
    {
        my $attr = $self->{'dblink'} . '.oracle-home';
        my $val = $self->device_attr($attr);
        if( defined($val) )
        {
            $Gerty::log->debug('Setting environment ORACLE_HOME=' . $val);
            $ENV{'ORACLE_HOME'} = $val;
        }
        else
        {
            $Gerty::log->warn
                ($attr . ' is not defined, hopefully DBD::Oracle ' .
                 'will find the libraries by itself');
        }

        my %ora_variables =
            ('tns-admin' => 'TNS_ADMIN',
             'oracle-sid' => 'ORACLE_SID',
             'two-task' => 'TWO_TASK');
        
        while( my($suffix, $env) = each %ora_variables )
        {
            $attr = $self->{'dblink'} . '.' . $suffix;
            $val = $self->device_attr($attr);
            if( defined($val) )
            {
                $Gerty::log->debug('Setting environment ' . $env . '=' . $val);
                $ENV{$env} = $val;
            }
        }
    }
    
    return $self;
}


sub name {return shift->{'dblink'}}
sub dbh {return shift->{'dbh'}}
sub dsn {return shift->{'dsn'}}


sub connect
{
    my $self = shift;    

    if( defined($self->dbh) )
    {
        $self->dbh->disconnect();
    }

    my $dbi_args = {
        'AutoCommit' => 0,
        'RaiseError' => 0,
        'PrintError' => 1,
    };

    $Gerty::log->debug('Connecting to database: ' . $self->{'dsn'});

    my $dbh = DBI->connect( $self->{'dsn'},
                            $self->{'username'},
                            $self->{'password'},
                            $dbi_args );

    if( not defined( $dbh ) )
    {
        $Gerty::log->error
            ('DBLink failed to connect to the database "'.
             $self->{'dsn'} . '" for device "' . $self->sysname .
             '". Error message: ' . $dbh->errstr);
        return undef;
    }

    $self->{'dbh'} = $dbh;
    return $dbh;
}



sub disconnect
{
    my $self = shift;
    
    $Gerty::log->debug('Disconnecting from database: ' . $self->{'dsn'});
    
    if( defined($self->{'dbh'}) )
    {
        $self->{'dbh'}->disconnect();
        $self->{'dbh'} = undef;
    }
}


# Present UNIX time as SQL date.
# At the moment only Oracle and Mysql are supported. Falling back to
# Oracle if nothing else matches

sub sql_unixtime_string
{
    my $self = shift;
    my $unixtime = shift;

    my $ret;
    
    if( $self->dsn =~ /:mysql:/i )
    {
        $ret = 'FROM_UNIXTIME(' . $unixtime . ')';
    }
    else
    {
        $ret = 'to_date(\'' . time2str('%Y%m%d%H%M%S', $unixtime) .
            '\',\'YYYYMMDDHH24MISS\')';
    }

    return $ret;
}


             
1;


# Local Variables:
# mode: perl
# indent-tabs-mode: nil
# perl-indent-level: 4
# End:
