#!/usr/bin/perl 
# Copyright (C) 2010 Serpro
# Author: Nilson Morais <nilson.morais-filho@serpro.gov.br>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
package Perlgst;

use warnings;
use GStreamer;
use Data::Dumper;
GStreamer -> init();
my $loop = Glib::MainLoop -> new();

# Creating elements
my $player = 	GStreamer::Pipeline->new("player");

#shout2cast
my $sink = 		GStreamer::ElementFactory->make(shout2send => "icecastsink");
$sink->set_property(
	'ip' => '10.200.158.173',
	'username' => 'source',
	'password' => 'gst@assiste',
	'port' => 8000,
	'mount' => 'perl.ogg',
	);

#Audio
my $audiosrc = 		GStreamer::ElementFactory -> make(pulsesrc => "pulsesrc");
my $audioenc = 		GStreamer::ElementFactory -> make(vorbisenc => "vorbisenc");
$audioenc->set_property('quality' => '0.1');
my $audioconv = 	GStreamer::ElementFactory -> make(audioconvert => "audioconvert");
my $aqueue = 		GStreamer::ElementFactory -> make(queue => "aqueue");
my $oggmux = 		GStreamer::ElementFactory -> make(oggmux => "oggmux");

#linking pipes
$player	-> add($audiosrc,$audioenc,$audioconv,$oggmux,$sink);
$audiosrc->link($audioconv) or die "Erro: link audio";
$audioconv->link($audioenc) or die "Erro: link audio";
$audioenc->link($oggmux) or die "Erro: link audio";
$oggmux->link($sink) or die "Erro: link audio";

#running
$player -> set_state("playing");
print "Running..\n";
eventLoop($player); #lookup for messages 
$loop -> run(); #loop

sub eventLoop {
  my ($pipe) = @_;
  my $bus = $pipe->get_bus();
  while (1) {
    my $message = $bus->poll("any", -1);
    if ($message->type & "warning") {
      print "Warning: ".$message -> error."\n";
    } elsif ($message->type & "error") {
      $audiosrc->set_state("null");
      $audioconv->set_state("null");
      $audioenc->set_state("null");
      $player->set_state("null");
      print "Warning: ".$message -> error."\n";
      die $message -> error;
    }
  }
}
1;
