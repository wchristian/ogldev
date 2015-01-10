package BillboardList;

use strictures;

use OpenGL qw(
  GL_TEXTURE_2D GL_ARRAY_BUFFER GL_STATIC_DRAW GL_FLOAT GL_FALSE GL_POINTS
  glGenBuffersARB_p glBindBufferARB glBufferDataARB_s
  glEnableVertexAttribArrayARB
  glBindBufferARB
  glVertexAttribPointerARB_c
  glDrawArrays
  glDisableVertexAttribArrayARB );
use PDL;
use PDL::Core 'howbig';

use billboard_technique;
use engine_common qw( COLOR_TEXTURE_UNIT );

use constant NUM_ROWS    => 10;
use constant NUM_COLUMNS => 10;

use Moo;

has [qw( pTexture VB )] => ( is => 'rw' );
has technique => ( is => 'rw', default => sub { BillboardTechnique->new } );

sub Init {
    my ( $self, $TexFilename ) = @_;
    $self->pTexture( Texture->new( TextureTarget => GL_TEXTURE_2D, FileName => $TexFilename ) );

    if ( !$self->pTexture->Load ) {
        return;
    }

    $self->CreatePositionBuffer;

    if ( !$self->technique->Init ) {
        return;
    }

    return 1;
}

sub CreatePositionBuffer {
    my ( $self ) = @_;
    my @Positions;

    for my $j ( 0 .. NUM_ROWS - 1 ) {
        for my $i ( 0 .. NUM_COLUMNS - 1 ) {
            my $Pos = [ $i, 0, $j ];
            $Positions[ $j * NUM_COLUMNS + $i ] = $Pos;
        }
    }

    my $Positions = pdl( @Positions)->float;

    $self->VB( glGenBuffersARB_p( 1 ) );
    glBindBufferARB( GL_ARRAY_BUFFER, $self->VB );
    glBufferDataARB_s( GL_ARRAY_BUFFER, $Positions->nelem * howbig( $Positions->get_datatype ),
        $Positions->get_dataref, GL_STATIC_DRAW );
}

sub Render {
    my ( $self, $VP, $CameraPos ) = @_;

    $self->technique->Enable;
    $self->technique->SetVP( $VP );
    $self->technique->SetCameraPosition( $CameraPos );

    $self->pTexture->Bind( COLOR_TEXTURE_UNIT );

    glEnableVertexAttribArrayARB( 0 );

    glBindBufferARB( GL_ARRAY_BUFFER, $self->VB );
    glVertexAttribPointerARB_c( 0, 3, GL_FLOAT, GL_FALSE, 0, 0 );    # position

    glDrawArrays( GL_POINTS, 0, NUM_ROWS * NUM_COLUMNS );

    glDisableVertexAttribArrayARB( 0 );
}

1;
