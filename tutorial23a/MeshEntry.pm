package MeshEntry;

use strictures;
use OpenGL::Debug qw(
  GL_ARRAY_BUFFER
  GL_STATIC_DRAW
  GL_ELEMENT_ARRAY_BUFFER

  glGenBuffersARB_p
  glBindBufferARB
  glBufferDataARB_s
);
use PDL::Core 'howbig';

use Moo;

has [qw( VB IB NumIndices MaterialIndex )] => ( is => 'rw' );

sub Init {
    my ( $self, $Vertices, $Indices ) = @_;
    $self->NumIndices( $Indices->dim( 0 ) );

    $self->VB( glGenBuffersARB_p( 1 ) );
    glBindBufferARB( GL_ARRAY_BUFFER, $self->VB );
    glBufferDataARB_s( GL_ARRAY_BUFFER, $Vertices->nelem * howbig( $Vertices->get_datatype ),
        $Vertices->get_dataref, GL_STATIC_DRAW );

    $self->IB( glGenBuffersARB_p( 1 ) );
    glBindBufferARB( GL_ELEMENT_ARRAY_BUFFER, $self->IB );
    glBufferDataARB_s( GL_ELEMENT_ARRAY_BUFFER, $Indices->nelem * howbig( $Indices->get_datatype ),
        $Indices->get_dataref, GL_STATIC_DRAW );
}

1;
