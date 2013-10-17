use strict;
use warnings;
use utf8;
use 5.014;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

use Path::Class;
use File::Copy 'copy';
use File::stat;

use Plack::Builder;

our $VERSION = '1.0';

# put your configuration here
sub load_config {
    my $c = shift;

    my $mode = $c->mode_name || 'development';

    +{ }
}

get '/' => sub {
    my $c = shift;
    return $c->render('index.tx');
};

post '/convert' => sub {
    my $c = shift;

    # get image
    my @images = $c->req->upload('files');

    my $results;
    for my $file (@images) {
        next unless $file->tempname =~ /\.png$/;


        my $output_before = $file->tempname =~ s{.*/(.*)$}{$1}r;
        my $output_after = $output_before =~ s{^(.*)\.png$}{$1_new.png}r;
        copy $file->tempname, dir('tmp/images')->file($output_before)->stringify;

        system 'pngquant', '--ext', '_new.png', '--speed', '1',
            dir('tmp/images')->file($output_before)->stringify;

        my $before_size_kb = sprintf "%.2fKB", $file->size / 1024;
        my $after_size_kb = sprintf "%.2fKB", 
            stat(dir('tmp/images')->file($output_after)->stringify)->size / 1024;

        push @$results, +{
            url => $c->uri_for('/images/' . $output_after),
            filename => $file->filename,
            before_size => $before_size_kb,
            after_size => $after_size_kb,
        };
    }

    return $c->render('index.tx', { results => $results });
};

# load plugins
__PACKAGE__->load_plugin('Web::CSRFDefender' => {
    post_only => 1,
});

__PACKAGE__->enable_session();

__PACKAGE__->template_options(
     syntax => 'Kolon',
);

builder {
    enable "Static", path => qr{^/image}, root => 'tmp/';

    __PACKAGE__->to_app(handle_static => 1);
}

__DATA__

@@ index.tx
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>PngDiet</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<link href="//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css" rel="stylesheet">
<script src="//netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap.min.js"></script>
<style type="text/css">
.quant_image {
    max-width: 480px;
    max-height: 480px;
}
footer {
    text-align: right;
}
body {
    -webkit-background-size: 40px 40px;
    -moz-background-size: 40px 40px;
    background-size: 40px 40px; /* Controls the size of the stripes */

    background-color: #CEF;
    background-image: -webkit-gradient(linear, 0 0, 0 100%, color-stop(.5, rgba(255, 255, 255, .5)), color-stop(.5, transparent), to(transparent));
    background-image: -moz-linear-gradient(rgba(255, 255, 255, .5) 50%, transparent 50%, transparent);
    background-image: -o-linear-gradient(rgba(255, 255, 255, .5) 50%, transparent 50%, transparent);
    background-image: linear-gradient(rgba(255, 255, 255, .5) 50%, transparent 50%, transparent);
}
</style>
</head>

<body>
<div class="container">
<header><h1>PngDiet</h1></header>
<section class="row">
<p>This is a PngDiet</p>

<form id="uploadform" method="post" action="<: uri_for('/convert') :>" enctype="multipart/form-data">
  <fieldset>
    <legend>files</legend>
    <div id="files_countainer">
    </div>
    <span class="help-block">Max upload size: 50MB (total)</span>
    <a id="add_file" class="btn"><i class="icon-plus"></i> Add file</a>
    <button type="submit" class="btn btn-primary"><i class="icon-upload icon-white"></i> Upload</button>
  </fieldset>
</form>

</section>

: if ($results) {
<h2>Result</h2>

: for $results -> $result {
<h3><: $result.filename :> (<: $result.before_size :> -&gt; <: $result.after_size :>)</h3>
<p><a href="<: $result.url :>"><img src="<: $result.url  :>" class="quant_image" /></a></p>
: }

: }

<footer>Powered by <a href="http://pngquant.org">pngquant</a> &amp; <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
</div>

<script type="text/javascript">
    var add_file_input = function() {
  $("#files_countainer").append(
    '<div class="control-group" ><input type="file" name="files"></div>'
  )
}

$("#add_file").click(add_file_input);
add_file_input();

</script>

</body>
</html>

