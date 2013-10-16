use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'PngDiet',
    AUTHOR        => 'Some Person <person@example.com>',
    VERSION_FROM  => 'app.psgi',
    PREREQ_PM     => {
        'Amon2'                           => '5.06',
        'Amon2::Lite'                     => '0.11',
        'Text::Xslate'                    => '1.5006',
        'Plack::Session'                  => '0.14',
    },
    MIN_PERL_VERSION => '5.008001',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
