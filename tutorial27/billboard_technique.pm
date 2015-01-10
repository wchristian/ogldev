package BillboardTechnique;

use strictures;

use OpenGL qw( GL_VERTEX_SHADER GL_GEOMETRY_SHADER GL_FRAGMENT_SHADER GL_TRUE
  glUniformMatrix4fvARB_s glUniform3fARB glUniform1iARB );

use ogldev_util 'INVALID_UNIFORM_LOCATION';

use Moo;

extends "Technique";
has [qw( VPLocation cameraPosLocation colorMapLocation )] => ( is => 'rw' );

sub Init {
    my ( $self ) = @_;
    if ( !$self->SUPER::Init ) {
        return;
    }

    if ( !$self->AddShader( GL_VERTEX_SHADER, "billboard.vs" ) ) {
        return;
    }

    if ( !$self->AddShader( GL_GEOMETRY_SHADER, "billboard.gs" ) ) {
        return;
    }

    if ( !$self->AddShader( GL_FRAGMENT_SHADER, "billboard.fs" ) ) {
        return;
    }

    if ( !$self->Finalize ) {
        return;
    }

    $self->VPLocation( $self->GetUniformLocation( "gVP" ) );
    $self->cameraPosLocation( $self->GetUniformLocation( "gCameraPos" ) );
    $self->colorMapLocation( $self->GetUniformLocation( "gColorMap" ) );

    if (   $self->VPLocation == INVALID_UNIFORM_LOCATION
        || $self->cameraPosLocation == INVALID_UNIFORM_LOCATION
        || $self->colorMapLocation == INVALID_UNIFORM_LOCATION )
    {
        return;
    }

    return 1;
}

sub SetVP {
    my ( $self, $VP ) = @_;
    glUniformMatrix4fvARB_s( $self->VPLocation, 1, GL_TRUE, $VP->get_dataref );
}

sub SetCameraPosition {
    my ( $self, $Pos ) = @_;
    glUniform3fARB( $self->cameraPosLocation, $Pos->at( 0 ), $Pos->at( 1 ), $Pos->at( 2 ) );
}

sub SetColorTextureUnit {
    my ( $self, $TextureUnit ) = @_;
    glUniform1iARB( $self->colorMapLocation, $TextureUnit );
}

1;
