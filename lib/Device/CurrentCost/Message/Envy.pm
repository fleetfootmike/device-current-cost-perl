package Device::CurrentCost::Message::Envy;

use strict;
use warnings;

# ABSTRACT: Perl modules for Current Cost energy monitor messages - new (Envy) format

=head1 SYNOPSIS

  use Device::CurrentCost::Message;
  my $msg = Device::CurrentCost::Message->new(message => '<msg>...</msg>');
  print 'Device: ', $msg->device, ' ', $msg->device_version, "\n";
  if ($msg->has_readings) {
    print 'Sensor: ', $msg->sensor, '.', $msg->id, ' (', $msg->type, ")\n";
    print 'Total: ', $msg->value, ' ', $msg->units, "\n";
    foreach my $phase (1..3) {
      print 'Phase ', $phase, ': ',
        $msg->value($phase)+0, " ", $msg->units, "\n";
    }
  }

  use Data::Dumper;
  print Data::Dumper->Dump([$msg->history]) if ($msg->has_history);

  # or
  print $msg->summary, "\n";

=head1 DESCRIPTION

=cut

use constant {
  DEBUG => $ENV{DEVICE_CURRENT_COST_DEBUG},
};

use Carp qw/croak carp/;
use Device::CurrentCost::Constants;
use List::Util qw/min/;

=method C<new(%parameters)>

This constructor returns a new Current Cost message object.
The supported parameters are:

=over

=item message

The message data.  Usually a string like 'C<< <msg>...</msg> >>'.
This parameter is required.

=back

=cut

sub new {
  my ($pkg, %p) = @_;
  croak $pkg.'->new: message parameter is required' unless (exists $p{message});
  croak $pkg.'->new: xml parameter is required' unless (exists $p{xml});
  my $self = bless { %p }, $pkg;
  $self;
}

=method C<device_type()>

Returns the type of the device that created the message.

=cut

sub device_type { CURRENT_COST_ENVY; }

=method C<device()>

Returns the name of the device that created the message.

=cut

sub device {
  my $self = shift;
  return $self->_find_device->[0]
}

=method C<device_version()>

Returns the version of the device that created the message.

=cut

sub device_version {
  my $self = shift;
  return $self->_find_device->[1]
}

sub _find_device {
  my $self = shift;
  return [ split /-/, $self->{xml}->{src}, 2 ];
}

=method C<message()>

Returns the raw data of the message.

=cut

sub message { shift->{message} }

=method C<dsb()>

Returns the days since boot field of the message.

=cut

sub dsb { shift->{xml}->{dsb} }


=method C<days_since_boot()>

Returns the days since boot field of the message.

=cut

sub days_since_boot { shift->dsb }

=method C<time()>

Returns the time field of the message in C<HH:MM:SS> format.

=cut

sub time { shift->{xml}->{time}; }

=method C<time_in_seconds()>

Returns the time field of the message in seconds.

=cut

sub time_in_seconds {
  my $self = shift;
  my ($h, $m, $s) = split /:/, $self->time, 3;
  $self->{time_in_seconds} = $h*3600 + $m*60 + $s;
}

=method C<boot_time()>

Returns the time since boot reported by the message in seconds.

=cut

sub boot_time {
  my $self = shift;
  $self->days_since_boot * 86400 + $self->time_in_seconds
}

=method C<sensor()>

Returns the sensor number field of the message.  A classic monitor
supports only one sensor so 0 is returned.

=cut

sub sensor { shift->{xml}->{sensor} }

=method C<id()>

Returns the id field of the message.

=cut

sub id { shift->{xml}->{id} }

=method C<type()>

Returns the sensor type field of the message.

=cut

sub type { shift->{xml}->{type} }

=method C<tmpr()>

Returns the tmpr/temperature field of the message.

=cut

sub tmpr { shift->{xml}->{tmpr} }

=method C<temperature()>

Returns the temperature field of the message.

=cut

sub temperature { shift->tmpr }

=method C<has_history()>

Returns true if the message contains history data.

=cut

sub has_history { exists shift->{xml}->{hist} }

=method C<has_readings()>

Returns true if the message contains current data.

=cut

sub has_readings { exists shift->{xml}->{ch1} }

=method C<units()>

Returns the units of the current data readings in the message.

=cut

sub units {
  my $ch1 = shift->{xml}->{ch1};
  my @k = keys %$ch1;
  return $k[0];
}

=method C<value( [$channel] )>

Returns the value of the current data reading for the given channel
(phase) in the message.  If no channel is given then the total of all
the current data readings for all channels is returned.

=cut

sub value {
  my ($self, $channel) = @_;

  $self->units || return; # return if no units can be found - historic only
  if ($channel) {
     return exists $self->{xml}->{"ch$channel"} 
      ? $self->{xml}->{"ch$channel"}->{$self->units} : undef;
  }

  return $self->{total} if (exists $self->{total});
  foreach my $channel (1 .. 3) {
    my $value = exists $self->{xml}->{"ch$channel"}
      ? $self->{xml}->{"ch$channel"}->{$self->units} : 0;
    $self->{total} += 0+"$value";
  }
  return $self->{total};
}

=method C<summary( [$prefix] )>

Returns the string summary of the data in the message.  Each line of the
string is prefixed by the given prefix or the empty string if the prefix
is not supplied.

=cut

sub summary {
  my ($self, $prefix) = @_;
  $prefix = '' unless (defined $prefix);
  my $str = $prefix.'Device: '.$self->device.' '.$self->device_version."\n";
  $prefix .= '  ';
  if ($self->has_readings) {
    $str .= $prefix.'Sensor: '.$self->sensor;
    $str .= (' ['.$self->id.','.$self->type."]\n".
             $prefix.'Total: '.$self->value.' '.$self->units."\n");
    foreach my $phase (1..3) {
      my $v = $self->value($phase);
      next unless (defined $v);
      $str .= $prefix.'Phase '.$phase.': '.($v+0)." ".$self->units."\n";
    }
  }
  if ($self->has_history) {
    $str .= $prefix."History\n";
    my $hist = $self->history;
    foreach my $sensor (sort keys %$hist) {
      $str .= $prefix.'  Sensor '.$sensor."\n";
      foreach my $span (sort keys %{$hist->{$sensor}}) {
        foreach my $age (sort { $a <=> $b } keys %{$hist->{$sensor}->{$span}}) {
          $str .= $prefix.'    -'.$age.' '.$span.': '.
            (0+$hist->{$sensor}->{$span}->{$age})."\n";
        }
      }
    }
  }
  $str
}

=method C<history()>

Returns a data structure contain any history data from the message.

=cut

sub history {
  my $self = shift;
  return $self->{history} if (exists $self->{history});
  my %hist = ();
  $self->{history} = \%hist;
  return $self->{history} unless ($self->has_history);
  my $xml = $self->message;
    # envy
    foreach my $data (split qr!</data><data>!, $xml) {
      my ($sensor) = ($data =~ /<sensor>(\d+)</) or next;
      my %rec = ();
      $hist{$sensor} = _parse_history($data);
    }
  \%hist;
}

sub _parse_history {
  my $string = shift;
  my %rec = ();
  foreach my $span (qw/hours days months years/) {
    my $first = substr $span, 0, 1;
    while ($string =~ m!<$first(\d+)>([^<]+)</$first\1>!mg) {
      $rec{$span}->{0+$1} = 0+$2;
    }
  }
  \%rec;
}

1;

__END__

ENVY:

<msg><src>CC128-v0.11</src><dsb>00089</dsb><time>13:02:39</time><tmpr>18.7</tmpr><sensor>1</sensor><id>01234</id><type>1</type><ch1><watts>00345</watts></ch1><ch2><watts>02151</watts></ch2><ch3><watts>00000</watts></ch3></msg>

<msg><src>CC128-v0.11</src><dsb>00596</dsb><time>13:11:20</time><hist><dsw>00597</dsw><type>1</type><units>kwhr</units><data><sensor>0</sensor><h250>7.608</h250><h248>7.163</h248><h246>6.541</h246><h244>3.270</h244></data><data><sensor>1</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>2</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>3</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>4</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>5</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>6</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>7</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>8</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>9</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data></hist></msg>

