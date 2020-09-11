use 5.18.0;no strict;use Term::Cap; use Term::ReadKey; sub p{say"@_"}
use Time::HiRes qw(usleep);
binmode STDOUT, ":encoding(UTF-8)";
$| = 1;
$t=Term::Cap->Tgetent;
p`tput civis`; #hide cursor
p`stty -echo`; #don't show input on screen

$mapfile="stargate.map";
$shipfile="ship.tex";
$map="";
$map_maxl=0;
$ship="";
$ship_maxl=0;
$ship_speed=1;
$ship_x=20;
$ship_lastaccel=0;

#load map
open(r,"<:utf8",$mapfile)||die"Could not open $mapfile";
map{
    $map.=$_;
    length$_ > $map_maxl && ($map_maxl=length$_);
}<r>;

#load ship
open(r,"<:utf8",$shipfile)||die"Could not open $shipfile";
map{
    $ship.=$_;
    length$_ > $ship_maxl && ($ship_maxl=length$_);
}<r>;


sub rendermap {
    $ix=@_[0];
    #$frame="";
    map{
        print substr $_,  $ix;
        print " " x ($map_maxl - length$_);
        p substr $_, 0, $ix;
        #$frame.="\n";
        #$x=<>;
    }split/\n/,$map;
    #p $frame;
    p"";
}

sub renderdynent {
    $tex=@_[0];
    $x=@_[1];
    $y=@_[2];
    p"SHIP POS: $x,$y";
    $c=0;
    map{
        print $t->Tgoto("cm",$x,$y+$c);
        print;
        $c++;
    }split/\n/,$tex;
}

sub handleinputs {
    $tick=@_[0];
    ReadMode 'cbreak';
    $rstr = ReadKey .000001;
    ReadMode 'normal';
   # p"Got key: $k";
    $rstr=~/w/ && ($ship_x-=2);
    $rstr=~/s/ && ($ship_x+=2);
    $rstr=~/\[/ && $ship_speed < 10 && ($ship_lastaccel=$tick) && ($ship_speed++);
    $rstr!~/\[/ && $tick - $ship_lastaccel > 5 && ($ship_lastaccel=$tick) && $ship_speed > 0 && ($ship_speed--);
}

#main render loop

$lbase=0;

map{
    print`clear`;
    rendermap$lbase;
    p "Frame: $_";
    #handle user inputs
    handleinputs$_;
    #render objects on top of map
    renderdynent $ship, $map_maxl/2, $ship_x;
    usleep(30000);
    $lbase+=$ship_speed;
    $lbase > $map_maxl && ($lbase=0);
}0..10000;

#TODO BUG
# Some tearing happens when (it SEEMS) we reach the end one complete cycle of going over the map (i.e. when we reach $map_maxl
# this may be the difference between character and byte length of these characters????

#for varying speed traversing over the map:
#We need to nail down a specific framerate to run the game at
#To move across the map faster, we need to move the geometry by more than one column per frame
