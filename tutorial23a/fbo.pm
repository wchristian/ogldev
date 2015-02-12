package fbo;

use OpenGL::Debug qw(
  GL_TEXTURE_2D
  GL_DEPTH_COMPONENT
  GL_FLOAT
  GL_TEXTURE_MIN_FILTER
  GL_LINEAR
  GL_TEXTURE_MAG_FILTER
  GL_TEXTURE_WRAP_S
  GL_CLAMP
  GL_TEXTURE_WRAP_T
  GL_DRAW_FRAMEBUFFER
  GL_DEPTH_ATTACHMENT
  GL_NONE
  GL_FRAMEBUFFER
  GL_FRAMEBUFFER_COMPLETE
  glGenFramebuffersEXT_p
  glGenTextures_p
  glBindTexture
  glTexImage2D_c
  glTexParameterf
  glBindFramebufferEXT
  glFramebufferTexture2DEXT
  glDrawBuffer
  glReadBuffer
  glCheckFramebufferStatusEXT
  glActiveTextureARB
  GL_RGBA
  GL_COLOR_ATTACHMENT0_EXT
  GL_BGRA
);

use Moo;

has [qw(fbo depth_texture color_texture)] => ( is => "rw" );

sub Init {
    my ( $self, $WindowWidth, $WindowHeight ) = @_;

    my @dim = ( $WindowWidth, $WindowHeight );

    # color texture
    $self->color_texture( glGenTextures_p( 1 ) );
    glBindTexture( GL_TEXTURE_2D, $self->color_texture );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,     GL_CLAMP );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,     GL_CLAMP );
    glTexImage2D_c( GL_TEXTURE_2D, 0, GL_RGBA, @dim, 0, GL_RGBA, GL_FLOAT, 0 );

    # depth texture
    $self->depth_texture( glGenTextures_p( 1 ) );
    glBindTexture( GL_TEXTURE_2D, $self->depth_texture );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,     GL_CLAMP );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,     GL_CLAMP );
    glTexImage2D_c( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, @dim, 0, GL_DEPTH_COMPONENT, GL_FLOAT, 0 );

    # fbo
    $self->fbo( glGenFramebuffersEXT_p( 1 ) );
    glBindFramebufferEXT( GL_FRAMEBUFFER, $self->fbo );

    # attach textures to fbo
    glFramebufferTexture2DEXT( GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, $self->color_texture, 0 );
    glFramebufferTexture2DEXT( GL_DRAW_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,      GL_TEXTURE_2D, $self->depth_texture, 0 );

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
    my ( $self, $TextureUnit, $texture_store ) = @_;
    glActiveTextureARB( $TextureUnit );
    glBindTexture( GL_TEXTURE_2D, $self->$texture_store );
}

1;
