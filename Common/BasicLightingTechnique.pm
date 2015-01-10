use strictures;

package BasicLightingTechnique;

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
use PDL;
use constant MAX_POINT_LIGHTS => 2;
use constant MAX_SPOT_LIGHTS  => 2;
use ogldev_util 'INVALID_UNIFORM_LOCATION';

has $_ => ( is => 'rw' ) for qw( WVPLocation colorTextureLocation WorldMatrixLocation eyeWorldPosLocation matSpecularIntensityLocation matSpecularPowerLocation numPointLightsLocation numSpotLightsLocation);
has dirLightLocation    => ( is => 'rw', default => sub { {} } );
has pointLightsLocation => ( is => 'rw', default => sub { [ ( undef ) x MAX_POINT_LIGHTS ] } );
has spotLightsLocation  => ( is => 'rw', default => sub { [ ( undef ) x MAX_SPOT_LIGHTS ] } );

extends "Technique";

sub Init {
    my ( $self ) = @_;

    if ( !$self->SUPER::Init ) {
        return;
    }

    if ( !$self->AddShader( GL_VERTEX_SHADER, "../Common/Shaders/basic_lighting.vs" ) ) {
        return;
    }

    if ( !$self->AddShader( GL_FRAGMENT_SHADER, "../Common/Shaders/basic_lighting.fs" ) ) {
        return;
    }

    if ( !$self->Finalize() ) {
        return;
    }

    $self->WVPLocation( $self->GetUniformLocation( "gWVP" ) );
    $self->WorldMatrixLocation( $self->GetUniformLocation( "gWorld" ) );
    $self->colorTextureLocation( $self->GetUniformLocation( "gColorMap" ) );
    $self->eyeWorldPosLocation( $self->GetUniformLocation( "gEyeWorldPos" ) );
    $self->dirLightLocation->{Color}            = $self->GetUniformLocation( "gDirectionalLight.Base.Color" );
    $self->dirLightLocation->{AmbientIntensity} = $self->GetUniformLocation( "gDirectionalLight.Base.AmbientIntensity" );
    $self->dirLightLocation->{Direction}        = $self->GetUniformLocation( "gDirectionalLight.Direction" );
    $self->dirLightLocation->{DiffuseIntensity} = $self->GetUniformLocation( "gDirectionalLight.Base.DiffuseIntensity" );
    $self->matSpecularIntensityLocation( $self->GetUniformLocation( "gMatSpecularIntensity" ) );
    $self->matSpecularPowerLocation( $self->GetUniformLocation( "gSpecularPower" ) );
    $self->numPointLightsLocation( $self->GetUniformLocation( "gNumPointLights" ) );
    $self->numSpotLightsLocation( $self->GetUniformLocation( "gNumSpotLights" ) );

    if (   $self->dirLightLocation->{AmbientIntensity} == INVALID_UNIFORM_LOCATION
        || $self->WVPLocation == INVALID_UNIFORM_LOCATION
        || $self->WorldMatrixLocation == INVALID_UNIFORM_LOCATION
        || $self->colorTextureLocation == INVALID_UNIFORM_LOCATION
        || $self->eyeWorldPosLocation == INVALID_UNIFORM_LOCATION
        || $self->dirLightLocation->{Color} == INVALID_UNIFORM_LOCATION
        || $self->dirLightLocation->{DiffuseIntensity} == INVALID_UNIFORM_LOCATION
        || $self->dirLightLocation->{Direction} == INVALID_UNIFORM_LOCATION
        || $self->matSpecularIntensityLocation == INVALID_UNIFORM_LOCATION
        || $self->matSpecularPowerLocation == INVALID_UNIFORM_LOCATION
        || $self->numPointLightsLocation == INVALID_UNIFORM_LOCATION
        || $self->numSpotLightsLocation == INVALID_UNIFORM_LOCATION )
    {
        return;
    }

    for my $i ( 0 .. $#{ $self->pointLightsLocation } ) {
        my $light = $self->pointLightsLocation->[$i] ||= {};

        $light->{Color} = $self->GetUniformLocation( "gPointLights[$i].Base.Color" );

        $light->{AmbientIntensity} = $self->GetUniformLocation( "gPointLights[$i].Base.AmbientIntensity" );

        $light->{Position} = $self->GetUniformLocation( "gPointLights[$i].Position" );

        $light->{DiffuseIntensity} = $self->GetUniformLocation( "gPointLights[$i].Base.DiffuseIntensity" );

        $light->{Atten}{Constant} = $self->GetUniformLocation( "gPointLights[$i].Atten.Constant" );

        $light->{Atten}{Linear} = $self->GetUniformLocation( "gPointLights[$i].Atten.Linear" );

        $light->{Atten}{Exp} = $self->GetUniformLocation( "gPointLights[$i].Atten.Exp" );

        if (   $light->{Color} == INVALID_UNIFORM_LOCATION
            || $light->{AmbientIntensity} == INVALID_UNIFORM_LOCATION
            || $light->{Position} == INVALID_UNIFORM_LOCATION
            || $light->{DiffuseIntensity} == INVALID_UNIFORM_LOCATION
            || $light->{Atten}->{Constant} == INVALID_UNIFORM_LOCATION
            || $light->{Atten}->{Linear} == INVALID_UNIFORM_LOCATION
            || $light->{Atten}->{Exp} == INVALID_UNIFORM_LOCATION )
        {
            return;
        }
    }

    for my $i ( 0 .. $#{ $self->spotLightsLocation } ) {
        my $light = $self->spotLightsLocation->[$i] ||= {};

        $light->{Color} = $self->GetUniformLocation( "gSpotLights[$i].Base.Base.Color" );

        $light->{AmbientIntensity} = $self->GetUniformLocation( "gSpotLights[$i].Base.Base.AmbientIntensity" );

        $light->{Position} = $self->GetUniformLocation( "gSpotLights[$i].Base.Position" );

        $light->{Direction} = $self->GetUniformLocation( "gSpotLights[$i].Direction" );

        $light->{Cutoff} = $self->GetUniformLocation( "gSpotLights[$i].Cutoff" );

        $light->{DiffuseIntensity} = $self->GetUniformLocation( "gSpotLights[$i].Base.Base.DiffuseIntensity" );

        $light->{Atten}{Constant} = $self->GetUniformLocation( "gSpotLights[$i].Base.Atten.Constant" );

        $light->{Atten}{Linear} = $self->GetUniformLocation( "gSpotLights[$i].Base.Atten.Linear" );

        $light->{Atten}{Exp} = $self->GetUniformLocation( "gSpotLights[$i].Base.Atten.Exp" );

        if (   $light->{Color} == INVALID_UNIFORM_LOCATION
            || $light->{AmbientIntensity} == INVALID_UNIFORM_LOCATION
            || $light->{Position} == INVALID_UNIFORM_LOCATION
            || $light->{Direction} == INVALID_UNIFORM_LOCATION
            || $light->{Cutoff} == INVALID_UNIFORM_LOCATION
            || $light->{DiffuseIntensity} == INVALID_UNIFORM_LOCATION
            || $light->{Atten}->{Constant} == INVALID_UNIFORM_LOCATION
            || $light->{Atten}->{Linear} == INVALID_UNIFORM_LOCATION
            || $light->{Atten}->{Exp} == INVALID_UNIFORM_LOCATION )
        {
            return;
        }
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

sub SetColorTextureUnit {
    my ( $self, $TextureUnit ) = @_;
    glUniform1iARB( $self->colorTextureLocation, $TextureUnit );
}

sub SetDirectionalLight {
    my ( $self, $Light ) = @_;
    glUniform3fARB( $self->dirLightLocation->{Color}, $Light->{Color}[0], $Light->{Color}[1], $Light->{Color}[2] );
    glUniform1fARB( $self->dirLightLocation->{AmbientIntensity}, $Light->{AmbientIntensity} );
    my $Direction = $Light->{Direction}->norm;
    glUniform3fARB( $self->dirLightLocation->{Direction}, $Direction->at( 0 ), $Direction->at( 1 ), $Direction->at( 2 ) );
    glUniform1fARB( $self->dirLightLocation->{DiffuseIntensity}, $Light->{DiffuseIntensity} );
}

sub SetEyeWorldPos {
    my ( $self, $EyeWorldPos ) = @_;
    glUniform3fARB( $self->eyeWorldPosLocation, @{ $EyeWorldPos->unpdl } );
}

sub SetMatSpecularIntensity {
    my ( $self, $Intensity ) = @_;
    glUniform1fARB( $self->matSpecularIntensityLocation, $Intensity );
}

sub SetMatSpecularPower {
    my ( $self, $Power ) = @_;
    glUniform1fARB( $self->matSpecularPowerLocation, $Power );
}

sub SetPointLights {
    my ( $self, $NumLights, $pLights ) = @_;
    glUniform1iARB( $self->numPointLightsLocation, $NumLights );

    for my $i ( 0 .. $#$pLights ) {
        glUniform3fARB( $self->pointLightsLocation->[$i]->{Color}, $pLights->[$i]->{Color}->[0], $pLights->[$i]->{Color}->[1], $pLights->[$i]->{Color}->[2] );
        glUniform1fARB( $self->pointLightsLocation->[$i]->{AmbientIntensity}, $pLights->[$i]->{AmbientIntensity} );
        glUniform1fARB( $self->pointLightsLocation->[$i]->{DiffuseIntensity}, $pLights->[$i]->{DiffuseIntensity} );
        glUniform3fARB( $self->pointLightsLocation->[$i]->{Position}, $pLights->[$i]->{Position}->[0], $pLights->[$i]->{Position}->[1], $pLights->[$i]->{Position}->[2] );
        glUniform1fARB( $self->pointLightsLocation->[$i]->{Atten}->{Constant}, $pLights->[$i]->{Attenuation}->{Constant} );
        glUniform1fARB( $self->pointLightsLocation->[$i]->{Atten}->{Linear},   $pLights->[$i]->{Attenuation}->{Linear} );
        glUniform1fARB( $self->pointLightsLocation->[$i]->{Atten}->{Exp},      $pLights->[$i]->{Attenuation}->{Exp} );
    }
}

sub SetSpotLights {
    my ( $self, $NumLights, $pLights ) = @_;
    glUniform1iARB( $self->numSpotLightsLocation, $NumLights );

    for my $i ( 0 .. $#$pLights ) {
        glUniform3fARB( $self->spotLightsLocation->[$i]->{Color}, $pLights->[$i]->{Color}->[0], $pLights->[$i]->{Color}->[1], $pLights->[$i]->{Color}->[2] );
        glUniform1fARB( $self->spotLightsLocation->[$i]->{AmbientIntensity}, $pLights->[$i]->{AmbientIntensity} );
        glUniform1fARB( $self->spotLightsLocation->[$i]->{DiffuseIntensity}, $pLights->[$i]->{DiffuseIntensity} );
        glUniform3fARB( $self->spotLightsLocation->[$i]->{Position}, $pLights->[$i]->{Position}->[0], $pLights->[$i]->{Position}->[1], $pLights->[$i]->{Position}->[2] );
        my $direction = pdl( $pLights->[$i]->{Direction} )->norm;
        glUniform3fARB( $self->spotLightsLocation->[$i]->{Direction}, @{ $direction->unpdl } );
        glUniform1fARB( $self->spotLightsLocation->[$i]->{Cutoff},            cos( math_3d::ToRadian( $pLights->[$i]->{Cutoff} ) ) );
        glUniform1fARB( $self->spotLightsLocation->[$i]->{Atten}->{Constant}, $pLights->[$i]->{Attenuation}->{Constant} );
        glUniform1fARB( $self->spotLightsLocation->[$i]->{Atten}->{Linear},   $pLights->[$i]->{Attenuation}->{Linear} );
        glUniform1fARB( $self->spotLightsLocation->[$i]->{Atten}->{Exp},      $pLights->[$i]->{Attenuation}->{Exp} );
    }
}

1;
