use strict;
use warnings;
use 5.014;

use Path::Class;

#use GetOpt::Long;
#GetOptions();


for my $file (@ARGV) {
    analyze($file);
}

sub analyze {
    my $filename = shift;

    my $binary = file($filename)->slurp(iomode => '<:raw');

    die 'this is not png file' unless $binary =~ /\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/;

    $binary = substr($binary, 8);
    my @chunks;
    while (length $binary) {
        my $len = vec($binary, 0, 32);
        my $name = substr($binary, 4, 4);
        my $data = $len != 0 ? substr($binary, 8, $len) : '';
        my $crc = unpack("H*", substr($binary, 8 + $len, 4));

        push @chunks, +{
            name => $name,
            data => $data,
            crc => $crc,
        };

        $binary = substr($binary, 12 + $len);
    }

    say "file: ". $filename;
    my $index = 0;
    for my $chunk (@chunks) {
        say sprintf "  No.%3d: %4s | data=%6dbytes, CRC=%s",
            $index, $chunk->{name}, length $chunk->{data}, $chunk->{crc};
        $index++;
    }

    say '';
}






