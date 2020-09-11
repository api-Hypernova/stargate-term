use 5.18.0;no strict;use Term::Cap; use Term::ReadKey; sub p{say"@_"}
use Time::HiRes qw(usleep);
binmode STDOUT, ":encoding(UTF-8)";
$| = 1;
$t=Term::Cap->Tgetent;
p`tput civis`; #hide cursor
p`stty -echo`; #don't show input on screen

$ents=undef;

sub loadent {
    $name=@_[0];
    open(r,"<:utf8","$name.tex")||die"Could not open sprite file $name.tex";
    $ents->{$name}->{sprite}="";
    $ents->{$name}->{xbb}=0;
    $ents->{$name}->{ybb}=0;
    $ents->{$name}->{xvel}=0;
    $ents->{$name}->{yvel}=0;
    $ents->{$name}->{xpos}=0;
    $ents->{$name}->{ypos}=0;
    $ents->{$name}->{dir}=0;
    map{
        $ents->{$name}->{sprite}.=$_;
        $ents->{$name}->{ybb}++;
        length$_ > $ents->{$name}->{xbb} && ($ents->{$name}->{xbb}=length$_);
    }<r>;
}


sub rendermap {
    $ix=@_[0];
    #$frame="";
    map{
        print substr $_,  $ix;
        print " " x ($ents->{map}->{xbb} - length$_);
        p substr $_, 0, $ix;
        #$frame.="\n";
        #$x=<>;
    }split/\n/,$ents->{map}->{sprite};
    #p $frame;
    p"";
}

sub renderdynent {
    $tex=@_[0];
    $x=@_[1];
    $y=@_[2];
    p"ENT POS: $x,$y";
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
    $rstr=~/w/ && ($ents->{ship}->{ypos}-=2);
    $rstr=~/s/ && ($ents->{ship}->{ypos}+=2);
    $rstr=~/\[/ && $ents->{ship}->{xvel} < 10 && ($ship_lastaccel=$tick) && ($ents->{ship}->{xvel}++);
    $rstr!~/\[/ && $tick - $ship_lastaccel > 5 && ($ship_lastaccel=$tick) && $ents->{ship}->{xvel} > 0 && ($ents->{ship}->{xvel}--);
}

#load main entities
loadent("map");
loadent("ship");
$ents->{ship}->{ypos}=20;
$ship_lastaccel=0;


#main render loop

$lbase=0;

map{
    print`clear`;
    rendermap$lbase;
    p "Frame: $_";
    #handle user inputs
    handleinputs$_;
    #render objects on top of map
    renderdynent $ents->{ship}->{sprite}, $ents->{map}->{xbb}/2, $ents->{ship}->{ypos};
    usleep(60000);
    $lbase+=$ents->{ship}->{xvel};
    $lbase > $ents->{map}->{xbb} && ($lbase=0); # once we reach the end of the map, wrap back to the start
}0..10000;

#TODO BUG
# Some tearing happens when (it SEEMS) we reach the end one complete cycle of going over the map (i.e. when we reach $map_maxl
# this may be the difference between character and byte length of these characters????

#for varying speed traversing over the map:
#We need to nail down a specific framerate to run the game at
#To move across the map faster, we need to move the geometry by more than one column per frame
