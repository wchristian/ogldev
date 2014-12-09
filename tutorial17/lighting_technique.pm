use strictures;

package LightingTechnique;

use Moo;

use technique;

use lib '../arcsyn/framework';
use OpenGL::Debug qw(
  GL_VERTEX_SHADER
  GL_FRAGMENT_SHADER
  GL_TRUE
  glGetUniformLocationARB_p
  glUniform1iARB
  glUniformMatrix4fvARB_s
  glUniform3fARB
  glUniform1fARB
);

has $_ => ( is => 'rw' ) for qw( WVPLocation samplerLocation dirLightColorLocation dirLightAmbientIntensityLocation );

extends "Technique";

my $pVSFileName = "lighting.vs";
my $pFSFileName = "lighting.fs";

sub Init {
    my ( $self ) = @_;

    if ( !$self->SUPER::Init ) {
        return;
    }

    if ( !$self->AddShader( GL_VERTEX_SHADER, $pVSFileName ) ) {
        return;
    }

    if ( !$self->AddShader( GL_FRAGMENT_SHADER, $pFSFileName ) ) {
        return;
    }

    if ( !$self->Finalize() ) {
        return;
    }

    $self->WVPLocation( $self->GetUniformLocation( "gWVP" ) );
    $self->samplerLocation( $self->GetUniformLocation( "gSampler" ) );
    $self->dirLightColorLocation( $self->GetUniformLocation( "gDirectionalLight.Color" ) );
    $self->dirLightAmbientIntensityLocation( $self->GetUniformLocation( "gDirectionalLight.AmbientIntensity" ) );

    if (   $self->dirLightAmbientIntensityLocation == 0xFFFFFFFF
        || $self->WVPLocation == 0xFFFFFFFF
        || $self->samplerLocation == 0xFFFFFFFF
        || $self->dirLightColorLocation == 0xFFFFFFFF )
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
    glUniform1iARB( $self->samplerLocation, $TextureUnit );
}

sub SetDirectionalLight {
    my ( $self, $Light ) = @_;
    glUniform3fARB( $self->dirLightColorLocation, $Light->{Color}[0], $Light->{Color}[1], $Light->{Color}[2] );
    glUniform1fARB( $self->dirLightAmbientIntensityLocation, $Light->{AmbientIntensity} );
}

1;
