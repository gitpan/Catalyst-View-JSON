#line 1
package JSON;

use strict;
use base qw(Exporter);

@JSON::EXPORT = qw(objToJson jsonToObj);

use vars qw($AUTOCONVERT $VERSION $UnMapping $BareKey $QuotApos
            $ExecCoderef $SkipInvalid $Pretty $Indent $Delimiter
            $KeySort $ConvBlessed $SelfConvert $UTF8 $SingleQuote);

$VERSION = '1.05';

$AUTOCONVERT = 1;
$SkipInvalid = 0;
$ExecCoderef = 0;
$Pretty      = 0; # pretty-print mode switch
$Indent      = 2; # (for pretty-print)
$Delimiter   = 2; # (for pretty-print)  0 => ':', 1 => ': ', 2 => ' : '
$UnMapping   = 0; # 
$BareKey     = 0; # 
$QuotApos    = 0; # 
$KeySort     = undef; # Code-ref to provide sort ordering in converter
$UTF8        = 0;
$SingleQuote = 0;

my $USE_UTF8;

BEGIN {
    $USE_UTF8 = $] >= 5.008 ? 1 : 0;
    sub USE_UTF8 {  $USE_UTF8; }
}

use JSON::Parser;
use JSON::Converter;

my $parser; # JSON => Perl
my $conv;   # Perl => JSON


##############################################################################
# CONSTRCUTOR - JSON objects delegate all processes
#                   to JSON::Converter and JSON::Parser.
##############################################################################

sub new {
    my $class = shift;
    my %opt   = @_;
    bless {
        conv   => undef,  # JSON::Converter [perl => json]
        parser => undef,  # JSON::Parser    [json => perl]
        # below fields are for JSON::Converter
        autoconv    => $AUTOCONVERT,
        skipinvalid => $SkipInvalid,
        execcoderef => $ExecCoderef,
        pretty      => $Pretty     ,
        indent      => $Indent     ,
        delimiter   => $Delimiter  ,
        keysort     => $KeySort    ,
        convblessed => $ConvBlessed,
        selfconvert => $SelfConvert,
        singlequote => $SingleQuote,
        # below fields are for JSON::Parser
        unmapping   => $UnMapping,
        quotapos    => $QuotApos ,
        barekey     => $BareKey  ,
        # common options
        utf8        => $UTF8     ,
        # overwrite
        %opt,
    }, $class;
}


##############################################################################
# METHODS
##############################################################################

*parse_json = \&jsonToObj;

*to_json    = \&objToJson;

sub jsonToObj {
    my $self = shift;
    my $js   = shift;

    if(!ref($self)){ # class method
        my $opt = __PACKAGE__->_getParamsForParser($js);
        $js = $self;
        $parser ||= new JSON::Parser;
        $parser->jsonToObj($js, $opt);
    }
    else{ # instance method
        my $opt = $self->_getParamsForParser($_[0]);
        $self->{parser} ||= ($parser ||= JSON::Parser->new);
        $self->{parser}->jsonToObj($js, $opt);
    }
}


sub objToJson {
    my $self = shift || return;
    my $obj  = shift;

    if(ref($self) !~ /JSON/){ # class method
        my $opt = __PACKAGE__->_getParamsForConverter($obj);
        $obj  = $self;
        $conv ||= JSON::Converter->new();
        $conv->objToJson($obj, $opt);
    }
    else{ # instance method
        my $opt = $self->_getParamsForConverter($_[0]);
        $self->{conv}
         ||= JSON::Converter->new( %$opt );
        $self->{conv}->objToJson($obj, $opt);
    }
}


#######################


sub _getParamsForParser {
    my ($self, $opt) = @_;
    my $params;

    if(ref($self)){ # instance
        my @names = qw(unmapping quotapos barekey utf8);
        my ($unmapping, $quotapos, $barekey, $utf8) = @{$self}{ @names };
        $params = {
            unmapping => $unmapping, quotapos => $quotapos,
            barekey   => $barekey,   utf8     => $utf8,
        };
    }
    else{ # class
        $params = {
            unmapping => $UnMapping, barekey => $BareKey,
            quotapos  => $QuotApos,  utf8    => $UTF8,
        };
    }

    if($opt and ref($opt) eq 'HASH'){
        for my $key ( keys %$opt ){
            $params->{$key} = $opt->{$key};
        }
    }

    return $params;
}


sub _getParamsForConverter {
    my ($self, $opt) = @_;
    my $params;

    if(ref($self)){ # instance
        my @names
         = qw(pretty indent delimiter autoconv keysort convblessed selfconvert utf8 singlequote);
        my ($pretty, $indent, $delimiter, $autoconv,
                $keysort, $convblessed, $selfconvert, $utf8, $singlequote)
                                                           = @{$self}{ @names };
        $params = {
            pretty      => $pretty,       indent      => $indent,
            delimiter   => $delimiter,    autoconv    => $autoconv,
            keysort     => $keysort,      convblessed => $convblessed,
            selfconvert => $selfconvert,  utf8        => $utf8,
            singlequote => $singlequote,
        };
    }
    else{ # class
        $params = {
            pretty      => $Pretty,       indent      => $Indent,
            delimiter   => $Delimiter,    autoconv    => $AUTOCONVERT,
            keysort     => $KeySort,      convblessed => $ConvBlessed,
            selfconvert => $SelfConvert,  utf8        => $UTF8,
            singlequote => $SingleQuote, 
        };
    }

    if($opt and ref($opt) eq 'HASH'){
        for my $key ( keys %$opt ){
            $params->{$key} = $opt->{$key};
        }
    }

    return $params;
}

##############################################################################
# ACCESSOR
##############################################################################
BEGIN{
    for my $name (qw/autoconv pretty indent delimiter 
                  unmapping keysort convblessed selfconvert singlequote/)
    {
        eval qq{
            sub $name { \$_[0]->{$name} = \$_[1] if(defined \$_[1]); \$_[0]->{$name} }
        };
    }
}

##############################################################################
# NON STRING DATA
##############################################################################

# See JSON::Parser for JSON::NotString.

sub Number {
    my $num = shift;

    return undef if(!defined $num);

    if(    $num =~ /^-?(?:\d+)(?:\.\d*)?(?:[eE][-+]?\d+)?$/
        or $num =~ /^0[xX](?:[0-9a-zA-Z])+$/                 )
    {
        return bless {value => $num}, 'JSON::NotString';
    }
    else{
        return undef;
    }
}

sub True {
    bless {value => 'true'}, 'JSON::NotString';
}

sub False {
    bless {value => 'false'}, 'JSON::NotString';
}

sub Null {
    bless {value => undef}, 'JSON::NotString';
}

##############################################################################
1;
__END__

#line 708


