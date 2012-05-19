package Device::CurrentCost::Message;

use strict;
use warnings;

# ABSTRACT: Perl modules for Current Cost energy monitor messages

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
use Device::CurrentCost::Message::Envy;
use Device::CurrentCost::Message::Classic;
use List::Util qw/min/;
use XML::Simple;

=method C<new(%parameters)>

This factory class returns a new Current Cost message object, either a 
C<Device::CurrentCost::Message::Envy> or a C<Device::CurrentCost::Message::Classic>

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
  my $xml;

  eval { 
    $xml = XMLin($p{message});
  };

  croak $pkg.'->new: message is not valid XML - '.$@ if $@;
  my $class =
    (ref $xml->{src} eq 'HASH' && exists $xml->{src}->{name})
      ? "Device::CurrentCost::Message::Classic" 
      : "Device::CurrentCost::Message::Envy";  
  
  return $class->new( message => $p{message}, xml => $xml );
}

1;
__END__

ENVY:

<msg><src>CC128-v0.11</src><dsb>00089</dsb><time>13:02:39</time><tmpr>18.7</tmpr><sensor>1</sensor><id>01234</id><type>1</type><ch1><watts>00345</watts></ch1><ch2><watts>02151</watts></ch2><ch3><watts>00000</watts></ch3></msg>

<msg><src>CC128-v0.11</src><dsb>00596</dsb><time>13:11:20</time><hist><dsw>00597</dsw><type>1</type><units>kwhr</units><data><sensor>0</sensor><h250>7.608</h250><h248>7.163</h248><h246>6.541</h246><h244>3.270</h244></data><data><sensor>1</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>2</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>3</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>4</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>5</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>6</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>7</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>8</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>9</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data></hist></msg>

CLASSIC:

<msg><date><dsb>00001</dsb><hr>12</hr><min>32</min><sec>01</sec></date><src><name>CC02</name><id>12345</id><type>1</type><sver>1.06</sver></src><ch1><watts>07806</watts></ch1><ch2><watts>00144</watts></ch2><ch3><watts>00144</watts></ch3><tmpr>21.1</tmpr></msg>

<msg><date><dsb>00001</dsb><hr>12</hr><min>32</min><sec>13</sec></date><src><name>CC02</name><id>12345</id><type>1</type><sver>1.06</sver></src><ch1><watts>07752</watts></ch1><ch2><watts>00144</watts></ch2><ch3><watts>00144</watts></ch3><tmpr>21.0</tmpr><hist><hrs><h02>001.3</h02><h04>000.0</h04><h06>000.0</h06><h08>000.0</h08><h10>000.0</h10><h12>000.0</h12><h14>000.0</h14><h16>000.0</h16><h18>000.0</h18><h20>000.0</h20><h22>000.0</h22><h24>000.0</h24><h26>000.0</h26></hrs><days><d01>0000</d01><d02>0000</d02><d03>0000</d03><d04>0000</d04><d05>0000</d05><d06>0000</d06><d07>0000</d07><d08>0000</d08><d09>0000</d09><d10>0000</d10><d11>0000</d11><d12>0000</d12><d13>0000</d13><d14>0000</d14><d15>0000</d15><d16>0000</d16><d17>0000</d17><d18>0000</d18><d19>0000</d19><d20>0000</d20><d21>0000</d21><d22>0000</d22><d23>0000</d23><d24>0000</d24><d25>0000</d25><d26>0000</d26><d27>0000</d27><d28>0000</d28><d29>0000</d29><d30>0000</d30><d31>0000</d31></days><mths><m01>0000</m01><m02>0000</m02><m03>0000</m03><m04>0000</m04><m05>0000</m05><m06>0000</m06><m07>0000</m07><m08>0000</m08><m09>0000</m09><m10>0000</m10><m11>0000</m11><m12>0000</m12></mths><yrs><y1>0000000</y1><y2>0000000</y2><y3>0000000</y3><y4>0000000</y4></yrs></hist></msg>
