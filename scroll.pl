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
   # p"ENT POS: $x,$y";
    $c=0;
    map{
        print $t->Tgoto("cm",$x,$y+$c);
        print;
        $c++;
    }split/\n/,$tex;
}

sub spawnwave {
    map{
        newdynent(id=>"lander$_",
            ent=>"lander",
            xpos=>$ents->{map}->{xbb}/3+int(rand($ents->{map}->{xbb}/3))+1,
            ypos=>int(rand($ents->{map}->{ybb}/2)),
            xvel=>int(rand(3))+3,
            yvel=>0,
            dir=>1);
    }1..5;
}

sub checkdynentcollision {
    map{
            $e=$_;
            $dynents->{$e}->{ent} eq "lander"  && p "LANDER" && goto e;
            map{
                    $dynents->{$e}->{ent} eq "laser" && $dynents->{$_}->{ent} eq "laser" && goto e; #lasers don't collide with each other
                    #($dynents->{$e}->{ent} eq "ship" || $dynents->{$e}->{ent} eq "laser") && ($dynents->{$_}->{ent} eq "laser" || $dynents->{$_}->{ent} eq "ship") && goto e; #don't allow ship to collide with laser
                    $dynents->{$e}->{id} eq $dynents->{$_}->{id} && goto e;  #don't allow any ent to collide with itself!

                    if(($dynents->{$e}->{xpos} + $ents->{$dynents->{$e}}->{xbb}) >= $dynents->{$_}->{xpos} &&
                        $dynents->{$e}->{xpos} <= ($dynents->{$e}->{xpos} + $ents->{$dynents->{$e}}->{xbb}) &&
                        ($dynents->{$e}->{ypos} + $ents->{$dynents->{$e}}->{ybb}) >= $dynents->{$_}->{ypos} &&
                        $dynents->{$e}->{ypos} <= ($dynents->{$e}->{ypos} + $ents->{$dynents->{$e}}->{ybb}))
                    {
                        p "COLLISION: $dynents->{$e}->{id}, $dynents->{$_}->{id}";
                        $dynents->{$e}->{ent} ne"ship" && delete $dynents->{$e};
                        $dynents->{$_}->{ent} ne"ship" &&  delete $dynents->{$_};
                    }

            }keys%$dynents;
            e:
    }keys%$dynents;
}

sub updatedynents {
    map{
        $_ eq"ship"&&goto e;
        $dynents->{$_}->{xpos}+=$dynents->{$_}->{xvel}-$dynents->{ship}->{xvel};
        $dynents->{$_}->{ypos}+=$dynents->{$_}->{yvel};
        e:
    }keys%$dynents;
}

sub firelaser {
    $tick=@_[0];
    newdynent(id=>"laser$tick",
        ent=>"laser",
        xpos=>int($dynents->{ship}->{xpos}+$ents->{ship}->{xbb}+2),
        ypos=>int($dynents->{ship}->{ypos}+($ents->{ship}->{ybb}/2)),
        xvel=>10,
        yvel=>0,
        deloffscreen=>1,
        dir=>1);
}

sub newdynent {
    %ops=split/ /,"@_";
    map{
        $dynents->{$ops{id}}->{$_}=$ops{$_};
    }keys%ops;
}

sub renderdynents {
    map{
        if($dynents->{$_}->{xpos} > 0 && $dynents->{$_}->{xpos} < $ents->{map}->{xbb} && $dynents->{$_}->{ypos} > 0 && $dynents->{$_}->{ypos} < $ents->{map}->{ybb}) {
            renderdynent $ents->{$dynents->{$_}->{ent}}->{sprite}, $dynents->{$_}->{xpos}, $dynents->{$_}->{ypos};
        } elsif ($dynents->{$_}->{deloffscreen}) {
            delete $dynents->{$_};
        }
    }keys%$dynents;
}

sub handleinputs {
    $tick=@_[0];
    ReadMode 'cbreak';
    $rstr = ReadKey .000001;
    ReadMode 'normal';
    $rstr=~/w/ && ($dynents->{ship}->{ypos}-=2);
    $rstr=~/s/ && ($dynents->{ship}->{ypos}+=2);
    $rstr=~/\]/ && firelaser($tick);
    $rstr=~/\[/ && $dynents->{ship}->{xvel} < 10 && ($ship_lastaccel=$tick) && ($dynents->{ship}->{xvel}++);
    $rstr!~/\[/ && $tick - $ship_lastaccel > 5 && ($ship_lastaccel=$tick) && $dynents->{ship}->{xvel} > 0 && ($dynents->{ship}->{xvel}--);
}

#load main entities
loadent("map");
loadent("ship");
loadent("laser");
loadent("lander");
newdynent(id=>"ship",
    ent=>"ship",
    xpos=>$ents->{map}->{xbb}/3,
    ypos=>20,
    xvel=>0,
    yvel=>0,
    dir=>1
    );

delete $dynents->{laser3};

p"ents:";
say Dumper $ents;
p"dynents:";
say Dumper $dynents;

p"list of dynents:";
map{
    say;
}keys%$dynents;

p"----";
p$ents->{$dynents->{ship}->{ent}}->{sprite};
$x=<>;

$ship_lastaccel=0;

#main render loop

$lbase=0;
spawnwave;
map{
    print`clear`;
    rendermap$lbase;
    p "Frame: $_";
    #handle user inputs
    handleinputs$_;
    #render objects on top of map
    renderdynents;
    updatedynents;
    checkdynentcollision;
    print $t->Tgoto("cm",99999,99999); #move cursor away to hide input garbage
    usleep(60000);
    $lbase+=$dynents->{ship}->{xvel};
    $lbase > $ents->{map}->{xbb} && ($lbase=0); # once we reach the end of the map, wrap back to the start
    #$x=<>;
}0..2000;

#TODO BUG
# Some tearing happens when (it SEEMS) we reach the end one complete cycle of going over the map (i.e. when we reach $map_maxl
# this may be the difference between character and byte length of these characters????

#for varying speed traversing over the map:
#We need to nail down a specific framerate to run the game at
#To move across the map faster, we need to move the geometry by more than one column per frame
