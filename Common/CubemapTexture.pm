package CubemapTexture;

use strictures;

use OpenGL::Image;
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
  GL_TEXTURE_CUBE_MAP
  GL_TEXTURE_WRAP_S
  GL_CLAMP_TO_EDGE
  GL_TEXTURE_WRAP_T
  GL_TEXTURE_WRAP_R
  GL_TEXTURE_CUBE_MAP_POSITIVE_X
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z

  glGenTextures_p
  glBindTexture
  glTexImage2D_c
  glTexParameterf
  glActiveTextureARB
  glTexParameteri
);

use Moo;

has $_ => ( is => 'ro', required => 1 )
  for qw( Directory PosXFilename NegXFilename PosYFilename NegYFilename PosZFilename NegZFilename );

has textureObj => ( is => 'rw' );

has fileNames => ( is => 'lazy', builder => 1 );

my @types = ( GL_TEXTURE_CUBE_MAP_POSITIVE_X, GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
    GL_TEXTURE_CUBE_MAP_POSITIVE_Y, GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
    GL_TEXTURE_CUBE_MAP_POSITIVE_Z, GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
);

sub _build_fileNames {
    my ( $self ) = @_;

    my $BaseDir = $self->Directory;
    $BaseDir .= '/' if $BaseDir !~ m|/$|;

    return [
        $BaseDir . $self->PosXFilename,
        $BaseDir . $self->NegXFilename,
        $BaseDir . $self->PosYFilename,
        $BaseDir . $self->NegYFilename,
        $BaseDir . $self->PosZFilename,
        $BaseDir . $self->NegZFilename,
    ];
}

sub Load {
    my ( $self ) = @_;

    $self->textureObj( glGenTextures_p( 1 ) );
    glBindTexture( GL_TEXTURE_CUBE_MAP, $self->textureObj );

    my @fileNames = @{ $self->fileNames };
    for my $i ( 0 .. $#types ) {
        my $img = Image::Magick->new;
        $img->Read( $fileNames[$i] );
        my ( $w, $h ) = $img->Get( 'width', 'height' );
        my ( $ifmt, $fmt, $type ) = $self->img_data( $img );
        my $elements = $w * $h * 4;
        my $oga = OpenGL::Array->new_pointer( $type, $img->GetImagePixels( rows => $h ), $elements );

        glTexImage2D_c( $types[$i], 0, $ifmt, $w, $h, 0, $fmt, $type, $oga->ptr );
    }

    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S,     GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T,     GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R,     GL_CLAMP_TO_EDGE );

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
    glBindTexture( GL_TEXTURE_CUBE_MAP, $self->textureObj );
}

1;
