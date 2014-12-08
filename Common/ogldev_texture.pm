use strictures;

package Texture;

use lib '../arcsyn/framework';

use Image::Magick;
use OpenGL::Debug qw(
  GL_RGB
  GL_RGBA
  GL_BGRA
  GL_RGBA8
  GL_RGBA16
  GL_UNSIGNED_BYTE
  GL_UNSIGNED_SHORT
  GL_TEXTURE_MIN_FILTER
  GL_LINEAR
  GL_TEXTURE_MAG_FILTER
  GL_TEXTURE_2D
  GL_UNSIGNED_SHORT

  glGenTextures_p
  glBindTexture
  glTexImage2D_c
  glTexParameterf
  glActiveTextureARB
);

use Moo;

has TextureTarget => ( is => 'ro', required => 1 );
has FileName      => ( is => 'ro', required => 1 );
has pImage        => ( is => 'rw' );
has blob          => ( is => 'rw' );
has textureObj    => ( is => 'rw' );

sub Load {
    my ( $self ) = @_;

    my $img = Image::Magick->new;
    $img->Read( $self->FileName );
    my ( $w, $h ) = $img->Get( 'width', 'height' );
    my ( $ifmt, $fmt, $type ) = $self->img_data( $img );
    my $elements = $w * $h * 4;
    my $oga = OpenGL::Array->new_pointer( $type, $img->GetImagePixels( rows => $h ), $elements );

    $self->textureObj( glGenTextures_p( 1 ) );
    glBindTexture( $self->TextureTarget, $self->textureObj );
    glTexImage2D_c( $self->TextureTarget, 0, $ifmt, $w, $h, 0, $fmt, $type, $oga->ptr );
    glTexParameterf( $self->TextureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameterf( $self->TextureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glBindTexture( $self->TextureTarget, 0 );

    return 1;
}

sub img_data {
    my ( $self, $img ) = @_;
    die "need at least IM 6.3.5" if $Image::Magick::VERSION lt '6.3.5';
    my $endian = unpack( "h*", pack( "s", 1 ) ) =~ /01/ || 0;
    my $format = $endian ? GL_RGBA : GL_BGRA;
    my $q = $img->Get( 'quantum' );
    return ( GL_RGBA8,  $format, GL_UNSIGNED_BYTE )  if $q == 8;
    return ( GL_RGBA16, $format, GL_UNSIGNED_SHORT ) if $q == 16;
    die "Unsupported pixel quantum $q\n";
}

sub Bind {
    my ( $self, $TextureUnit ) = @_;
    glActiveTextureARB( $TextureUnit );
    glBindTexture( $self->TextureTarget, $self->textureObj );
}

1;
