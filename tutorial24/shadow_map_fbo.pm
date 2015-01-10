package shadow_map_fbo;

use OpenGL::Debug qw(
  GL_TEXTURE_2D
  GL_DEPTH_COMPONENT
  GL_DEPTH_COMPONENT32
  GL_FLOAT
  GL_TEXTURE_MIN_FILTER
  GL_LINEAR
  GL_TEXTURE_MAG_FILTER
  GL_TEXTURE_WRAP_S
  GL_CLAMP
  GL_CLAMP_TO_EDGE
  GL_TEXTURE_WRAP_T
  GL_DRAW_FRAMEBUFFER
  GL_DEPTH_ATTACHMENT
  GL_NONE
  GL_FRAMEBUFFER
  GL_FRAMEBUFFER_COMPLETE
  GL_TEXTURE_COMPARE_MODE
  glGenFramebuffersEXT_p
  glGenTextures_p
  glBindTexture
  glTexImage2D_c
  glTexParameterf
  glTexParameteri
  glBindFramebufferEXT
  glFramebufferTexture2DEXT
  glDrawBuffer
  glReadBuffer
  glCheckFramebufferStatusEXT
  glActiveTextureARB
);

use Moo;

has [qw(fbo shadowMap)] => ( is => "rw" );

sub Init {
    my ( $self, $WindowWidth, $WindowHeight ) = @_;

    # Create the FBO
    $self->fbo( glGenFramebuffersEXT_p( 1 ) );

    # Create the depth buffer
    $self->shadowMap( glGenTextures_p( 1 ) );
    glBindTexture( GL_TEXTURE_2D, $self->shadowMap );
    glTexImage2D_c( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, $WindowWidth, $WindowHeight, 0, GL_DEPTH_COMPONENT,
        GL_FLOAT, 0 );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,   GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,   GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

    glBindFramebufferEXT( GL_FRAMEBUFFER, $self->fbo );
    glFramebufferTexture2DEXT( GL_DRAW_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, $self->shadowMap, 0 );

    # Disable writes to the color buffer
    glDrawBuffer( GL_NONE );
    glReadBuffer( GL_NONE );

    my $Status = glCheckFramebufferStatusEXT( GL_FRAMEBUFFER );

    if ( $Status != GL_FRAMEBUFFER_COMPLETE ) {
        printf( "FB error, status: 0x%x\n", $Status );
        return;
    }

    return 1;
}

sub BindForWriting {
    my ( $self ) = @_;
    glBindFramebufferEXT( GL_DRAW_FRAMEBUFFER, $self->fbo );
}

sub BindForReading {
    my ( $self, $TextureUnit ) = @_;
    glActiveTextureARB( $TextureUnit );
    glBindTexture( GL_TEXTURE_2D, $self->shadowMap );
}

1;
