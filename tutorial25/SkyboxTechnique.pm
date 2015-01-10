package SkyboxTechnique;

use strictures;

use OpenGL::Debug qw(
  GL_VERTEX_SHADER GL_FRAGMENT_SHADER GL_TRUE
  glUniformMatrix4fvARB_s glUniform1iARB
);
use ogldev_util 'INVALID_UNIFORM_LOCATION';
use Technique;

use Moo;

extends "Technique";

has $_ => ( is => 'rw' ) for qw( WVPLocation textureLocation );

sub Init {
    my ( $self ) = @_;

    if ( !$self->SUPER::Init ) {
        return;
    }

    if ( !$self->AddShader( GL_VERTEX_SHADER, "skybox.vs" ) ) {
        return;
    }

    if ( !$self->AddShader( GL_FRAGMENT_SHADER, "skybox.fs" ) ) {
        return;
    }

    if ( !$self->Finalize ) {
        return;
    }

    $self->WVPLocation( $self->GetUniformLocation( "gWVP" ) );
    $self->textureLocation( $self->GetUniformLocation( "gCubemapTexture" ) );

    if (   $self->WVPLocation == INVALID_UNIFORM_LOCATION
        || $self->textureLocation == INVALID_UNIFORM_LOCATION )
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
