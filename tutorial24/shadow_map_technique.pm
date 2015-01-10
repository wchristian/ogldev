package ShadowMapTechnique;

use OpenGL::Debug qw(
  GL_VERTEX_SHADER
  GL_FRAGMENT_SHADER
  glUniformMatrix4fvARB_s
  GL_TRUE
  glUniform1iARB
);

use Moo;

extends 'Technique';
has [qw(fbo shadowMap WVPLocation textureLocation)] => ( is => "rw" );

sub Init {
    my ( $self ) = @_;

    if ( !$self->SUPER::Init ) {
        return;
    }

    if ( !$self->AddShader( GL_VERTEX_SHADER, "shadow_map.vs" ) ) {
        return;
    }

    if ( !$self->AddShader( GL_FRAGMENT_SHADER, "shadow_map.fs" ) ) {
        return;
    }

    if ( !$self->Finalize() ) {
        return;
    }

    $self->WVPLocation( $self->GetUniformLocation( "gWVP" ) );
    $self->textureLocation( $self->GetUniformLocation( "gShadowMap" ) );

    if (   $self->WVPLocation == 0xFFFFFFFF
        || $self->textureLocation == 0xFFFFFFFF )
    {
        return;
    }

    return 1;
}

sub SetWVP {
    my ( $self, $WVP ) = @_;
    glUniformMatrix4fvARB_s( $self->WVPLocation, 1, GL_TRUE, $WVP->get_dataref );
}

sub SetTextureUnit {
    my ( $self, $TextureUnit ) = @_;
    glUniform1iARB( $self->textureLocation, $TextureUnit );
}

1;
