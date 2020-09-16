use 5.18.0;no strict;use Term::Cap; use Term::ReadKey; sub p{say"@_"}
use Time::HiRes qw(usleep);
use Data::Dumper;
binmode STDOUT, ":encoding(UTF-8)";
$| = 1;
$t=Term::Cap->Tgetent;
p`tput civis`; #hide cursor
p`stty -echo`; #don't show input on screen

$ents=undef;
$dynents=undef;

sub loadent {
    $name=@_[0];
    open(r,"<:utf8","$name.tex")||die"Could not open sprite file $name.tex";
    $ents->{$name}->{sprite}="";
    $ents->{$name}->{xbb}=0;
    $ents->{$name}->{ybb}=0;
    #$ents->{$name}->{xvel}=0; #REPLACE
    #$ents->{$name}->{yvel}=0; #REPLACE
    #$ents->{$name}->{xpos}=0; #REPLACE
    #$ents->{$name}->{ypos}=0; #REPLACE
    #$ents->{$name}->{dir}=0; #REPLACE
    map{
        $ents->{$name}->{sprite}.=$_;
        $ents->{$name}->{ybb}++;
        length$_ > $ents->{$name}->{xbb} && ($ents->{$name}->{xbb}=length$_);
    }<r>;
}

sub rendermap {
    $ix=@_[0];
    map{
        print substr $_,  $ix;
        print " " x ($ents->{map}->{xbb} - length$_);
        p substr $_, 0, $ix;
    }split/\n/,$ents->{map}->{sprite};
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

sub spawnwave {
    print
}

sub updatedynents {
    print
}

sub newdynent {
    $ops="@_";
    %ops=split/ /,$ops;
    map{
        $dynents->{$ops{ent}}->{$_}=$ops{$_};
        p"Key: $_";
        p"Value: $ops{$_}";
    }keys%ops;
    #properties: name, sprite, xvel, yvel, xpos, ypos, dir
}

sub handleinputs {
    $tick=@_[0];
    ReadMode 'cbreak';
    $rstr = ReadKey .000001;
    ReadMode 'normal';
    $rstr=~/w/ && ($dynents->{ship}->{ypos}-=2);
    $rstr=~/s/ && ($dynents->{ship}->{ypos}+=2);
    $rstr=~/\[/ && $dynents->{ship}->{xvel} < 10 && ($ship_lastaccel=$tick) && ($dynents->{ship}->{xvel}++);
    $rstr!~/\[/ && $tick - $ship_lastaccel > 5 && ($ship_lastaccel=$tick) && $dynents->{ship}->{xvel} > 0 && ($dynents->{ship}->{xvel}--);
}

#load main entities
loadent("map");
loadent("ship");
loadent("laser");
newdynent(ent=>"ship",
    xpos=>$ents->{map}->{xbb}/2,
    ypos=>20,
    xvel=>0,
    yvel=>0,
    dir=>1
    );

p"xpos";
p$dynents->{ship}->{xpos};
p"ypos";
p$dynents->{ship}->{ypos};
p"xvel";
p$dynents->{ship}->{xvel};
p"yvel";
p$dynents->{ship}->{yvel};
p"dir";
p$dynents->{ship}->{dir};

say Dumper $dynents;
$ship_lastaccel=0;

#main render loop

$lbase=0;

#exit 0;

map{
    print`clear`;
    rendermap$lbase;
    p "Frame: $_";
    #handle user inputs
    handleinputs$_;
    #render objects on top of map
    renderdynent $ents->{ship}->{sprite}, $dynents->{ship}->{xpos}, $dynents->{ship}->{ypos};
    usleep(60000);
    $lbase+=$dynents->{ship}->{xvel};
    $lbase > $ents->{map}->{xbb} && ($lbase=0); # once we reach the end of the map, wrap back to the start
}0..5000;

#TODO BUG
# Some tearing happens when (it SEEMS) we reach the end one complete cycle of going over the map (i.e. when we reach $map_maxl
# this may be the difference between character and byte length of these characters????

#for varying speed traversing over the map:
#We need to nail down a specific framerate to run the game at
#To move across the map faster, we need to move the geometry by more than one column per frame
