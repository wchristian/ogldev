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

has $_ => ( is => 'rw' ) for qw( WVPLocation samplerLocation WorldMatrixLocation );
has dirLightLocation => ( is => 'rw', default => sub { {} } );

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
    $self->WorldMatrixLocation( $self->GetUniformLocation( "gWorld" ) );
    $self->samplerLocation( $self->GetUniformLocation( "gSampler" ) );
    $self->dirLightLocation->{Color}            = $self->GetUniformLocation( "gDirectionalLight.Color" );
    $self->dirLightLocation->{AmbientIntensity} = $self->GetUniformLocation( "gDirectionalLight.AmbientIntensity" );
    $self->dirLightLocation->{Direction}        = $self->GetUniformLocation( "gDirectionalLight.Direction" );
    $self->dirLightLocation->{DiffuseIntensity} = $self->GetUniformLocation( "gDirectionalLight.DiffuseIntensity" );

    if (   $self->dirLightLocation->{AmbientIntensity} == 0xFFFFFFFF
        || $self->WVPLocation == 0xFFFFFFFF
        || $self->WorldMatrixLocation == 0xFFFFFFFF
        || $self->samplerLocation == 0xFFFFFFFF
        || $self->dirLightLocation->{Color} == 0xFFFFFFFF
        || $self->dirLightLocation->{DiffuseIntensity} == 0xFFFFFFFF
        || $self->dirLightLocation->{Direction} == 0xFFFFFFFF )
    {
        return;
    }

    return 1;
}

sub SetWVP {
    my ( $self, $WVP ) = @_;
    glUniformMatrix4fvARB_s( $self->WVPLocation, 1, GL_TRUE, $WVP->get_dataref );
}

sub SetWorldMatrix {
    my ( $self, $WorldInverse ) = @_;
    glUniformMatrix4fvARB_s( $self->WorldMatrixLocation, 1, GL_TRUE, $WorldInverse->get_dataref );
}

sub SetTextureUnit {
    my ( $self, $TextureUnit ) = @_;
    glUniform1iARB( $self->samplerLocation, $TextureUnit );
}

sub SetDirectionalLight {
    my ( $self, $Light ) = @_;
    glUniform3fARB( $self->dirLightLocation->{Color}, $Light->{Color}[0], $Light->{Color}[1], $Light->{Color}[2] );
    glUniform1fARB( $self->dirLightLocation->{AmbientIntensity}, $Light->{AmbientIntensity} );
    my $Direction = $Light->{Direction}->norm;
    glUniform3fARB(
        $self->dirLightLocation->{Direction},
        $Direction->at( 0 ),
        $Direction->at( 1 ),
        $Direction->at( 2 )
    );
    glUniform1fARB( $self->dirLightLocation->{DiffuseIntensity}, $Light->{DiffuseIntensity} );
}

1;
