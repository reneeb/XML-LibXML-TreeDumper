package XML::LibXML::TreeDumper;

# ABSTRACT: print a tree of libxml elements

use strict;
use warnings;

use Carp;
use XML::LibXML;
use Moo;

our $VERSION = 0.01;

has data => ( is => 'rw', trigger => \&_parse );
has node => ( is => 'rw', lazy    => 1, builder => \&_parse);

sub dump {
    my ($self, $xpath) = @_;

    my @nodes  = $xpath ? $self->node->findnodes( $xpath ) : $self->node;
    my $string = '';
    for my $node ( @nodes ) {
        $self->_dump_node( $node, \$string );
    }

    return $string;
}

sub _parse {
    my ($self) = @_;

    my $parser = XML::LibXML->new;

    my $doc;
    if ( ref $self->data ) {
        $doc = $parser->parse_string( ${ $self->data } );
    }
    else {
        $doc = $parser->parse_file( $self->data );
    }

    $self->node( $doc->getDocumentElement );
}

sub _dump_node {
    my ($self, $node, $out, $indent) = @_;

    $indent //= '';

    my $name = $node->getName;

    my $text = $node->isa( 'XML::LibXML::Text' ) ? $node->getData : '';
    if ( length $text ) {
        $text =~ s/\\/\\\\/g;
        $text =~ s/"/\\"/g;
        #$text =~ s/([[:cntrl:]])/quotemeta($1)/eg;
        $name = sprintf '"%s"', $text;
    }

    $$out .=  $indent . ref( $node ) . '         ' . $name . "\n";
    my @children = $node->childNodes;
    for my $child ( @children ) {
        $self->_dump_node( $child, $out, $indent . ( ' ' x 4 ) );
    } 
}

1;

=head1 SYNOPSIS

  my $dumper = XML::LibXML::TreeDumper->new;
  
  my $xml = <<XML;
  <test>
    <string>hallo</string>
  </test>
  XML
  
  $dumper->data( \$xml );
  
  say $dumper->dump('/test/string');

or

  use XML::LibXML::TreeDumper;
  
  my $dumper = XML::LibXML::TreeDumper->new;
  
  my $dir = dirname __FILE__;
  my $file = File::Spec->catfile( $dir, 'test.xml' );
  
  $dumper->data( $file );
  
  $dumper->dump;


