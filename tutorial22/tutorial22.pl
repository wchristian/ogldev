use strictures;

package tutorial22;

use lib '../arcsyn/framework';

use OpenGL::Debug qw(
  glutInit
  glutInitDisplayMode
  GLUT_DOUBLE
  GLUT_RGBA
  glutInitWindowSize
  glutInitWindowPosition
  glutCreateWindow
  glutDisplayFunc
  glClearColor
  glutMainLoop
  glClear
  GL_COLOR_BUFFER_BIT
  glutSwapBuffers

  GL_FLOAT
  glGenBuffersARB_p
  glBindBufferARB
  GL_ARRAY_BUFFER
  glBufferDataARB_s
  GL_STATIC_DRAW
  glEnableVertexAttribArrayARB
  glBindBufferARB
  glVertexAttribPointerARB_c
  GL_FLOAT
  GL_FALSE
  glDrawArrays
  GL_POINTS
  glDisableVertexAttribArrayARB

  GL_TRIANGLES

  GLUT_RGB
  glGetString
  GL_VERSION
  glCreateProgramObjectARB
  GL_VERTEX_SHADER
  GL_FRAGMENT_SHADER
  glCreateShaderObjectARB
  glShaderSourceARB_p
  glCompileShaderARB
  glGetShaderiv_p
  GL_COMPILE_STATUS
  glGetShaderInfoLog_p
  glAttachShader
  glLinkProgramARB
  glGetProgramiv_p
  GL_LINK_STATUS
  glGetInfoLogARB_p
  glValidateProgramARB
  GL_VALIDATE_STATUS
  glUseProgramObjectARB

  glutIdleFunc
  glGetUniformLocationARB_p
  glUniform1fARB

  glUniformMatrix4fvARB_s
  GL_TRUE

  glGenBuffersARB_p
  GL_ELEMENT_ARRAY_BUFFER
  glDrawElements_c
  GL_UNSIGNED_INT

  glutSpecialFunc

  glutGameModeString
  glutEnterGameMode
  glutPassiveMotionFunc
  glutKeyboardFunc
  glutLeaveMainLoop

  GL_TEXTURE0
  GL_CW
  GL_BACK
  GL_CULL_FACE
  GL_TEXTURE_2D
  glFrontFace
  glCullFace
  glEnable
  glUniform1iARB

  GL_DEPTH_BUFFER_BIT
);

use 5.010;

use PDL;
use PDL::Core 'howbig';
use lib '../Common';
use pipeline;
use camera;
use ogldev_texture;
use BasicLightingTechnique;
use glut_backend;
use mesh;
use ogldev_keys qw( OGLDEV_KEY_ESCAPE OGLDEV_KEY_q OGLDEV_KEY_a OGLDEV_KEY_s OGLDEV_KEY_z OGLDEV_KEY_x );
use constant ASSERT        => 0;
use constant WINDOW_WIDTH  => 300;
use constant WINDOW_HEIGHT => 187.5;
use constant FieldDepth    => 10;

use Moo;

extends "ICallbacks";

has $_ => ( is => 'rw' ) for qw( pGameCamera VBO_vertex_size VBO_tex_offset VBO_normal_offset VBO pEffect pMesh);
has scale => ( is => 'rw', default => sub { 0 } );
has directionalLight => (
    is      => 'rw',
    default => sub {
        {
            Color            => [ 1,    1,  1 ],
            AmbientIntensity => 1,
            DiffuseIntensity => 0.01,
            Direction        => pdl( 1, -1, 0 )
        };
    }
);

main();

sub Init {
    my ( $self ) = @_;

    my $Pos    = pdl( 3, 7,    -10 );
    my $Target = pdl( 0, -0.2, 1 );
    my $Up     = pdl( 0, 1,    0 );

    $self->pGameCamera(
        camera->new(
            windowWidth  => WINDOW_WIDTH,
            windowHeight => WINDOW_HEIGHT,
            Pos          => $Pos,
            Target       => $Target,
            Up           => $Up
        )
    );

    $self->pEffect( BasicLightingTechnique->new );

    if ( !$self->pEffect->Init ) {
        warn "Error initializing the lighting technique";
        return;
    }

    $self->pEffect->Enable;

    $self->pEffect->SetColorTextureUnit( 0 );

    $self->pMesh( mesh->new );

    return $self->pMesh->LoadMesh( "../Content/phoenix_ugv.md2" );
}

sub Run {
    GLUTBackendRun( shift );
}

sub RenderSceneCB {
    my ( $self ) = @_;

    $self->scale( $self->scale + 0.01 );

    $self->pGameCamera->OnRender;

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    my @pl = (
        {
            DiffuseIntensity => 0.25,
            Color            => [ 1, 0.5, 0 ],
            Position         => [ 3, 1, FieldDepth * ( cos( $self->scale ) + 1 ) / 2 ],
            Attenuation      => { Linear => 0.1, Constant => 1, Exp => 0 },
            AmbientIntensity => 0,
        },
        {
            DiffuseIntensity => 0.25,
            Color            => [ 0, 0.5, 1 ],
            Position         => [ 7, 1, FieldDepth * ( sin( $self->scale ) + 1 ) / 2 ],
            Attenuation      => { Linear => 0.1, Constant => 1, Exp => 0 },
            AmbientIntensity => 0,
        }
    );
    $self->pEffect->SetPointLights( 2, \@pl );

    my @sl = (
        {
            DiffuseIntensity => 0.9,
            Color            => [ 0, 1, 1 ],
            Position         => $self->pGameCamera->Pos->unpdl,
            Direction        => $self->pGameCamera->Target->unpdl,
            Attenuation      => { Linear => 0.1, Constant => 1, Exp => 0 },
            AmbientIntensity => 0,
            Cutoff           => 10,
        },
        {
            DiffuseIntensity => 0.75,
            Color            => [ 0, 0.5, 1 ],
            Position         => [ 7, 1, FieldDepth * ( sin( $self->scale ) + 1 ) / 2 ],
            Direction => [ 0, 0, 0 ],
            Attenuation      => { Linear => 0.1, Constant => 1, Exp => 0 },
            AmbientIntensity => 0,
            Cutoff           => 0,
        }
    );
    $self->pEffect->SetSpotLights( 1, \@sl );

    my $p = pipeline->new(
        Scale     => [ 0.1, 0.1,          0.1 ],
        Rotate    => [ 0,   $self->scale, 0 ],
        WorldPos  => [ 0,   0,            10 ],
        CameraPos => $self->pGameCamera->Pos,
        Target    => $self->pGameCamera->Target,
        Up        => $self->pGameCamera->Up,
        PerspectiveProj => { FOV => 60, Width => WINDOW_WIDTH, Height => WINDOW_HEIGHT, zNear => 1, zFar => 100 },
    );

    $self->pEffect->SetWVP( $p->GetWVPTrans );
    $self->pEffect->SetWorldMatrix( $p->GetWorldTrans );
    $self->pEffect->SetDirectionalLight( $self->directionalLight );
    $self->pEffect->SetEyeWorldPos( $self->pGameCamera->Pos );
    $self->pEffect->SetMatSpecularIntensity( 0 );
    $self->pEffect->SetMatSpecularPower( 0 );

    $self->pMesh->Render;

    glutSwapBuffers();

    return;
}

sub KeyboardCB {
    my ( $self, $Key, $x, $y ) = @_;
    my %key_map = (
        OGLDEV_KEY_ESCAPE() => sub { glutLeaveMainLoop() },
        OGLDEV_KEY_q()      => sub { glutLeaveMainLoop() },
        OGLDEV_KEY_a()      => sub { $self->directionalLight->{AmbientIntensity} += 0.05 },
        OGLDEV_KEY_s()      => sub { $self->directionalLight->{AmbientIntensity} -= 0.05 },
        OGLDEV_KEY_z()      => sub { $self->directionalLight->{DiffuseIntensity} += 0.05 },
        OGLDEV_KEY_x()      => sub { $self->directionalLight->{DiffuseIntensity} -= 0.05 },
    );
    my $run = $key_map{$Key} || sub { $self->pGameCamera->OnKeyboard( $Key ) };
    $run->();
}

sub PassiveMouseCB {
    my ( $self, $x, $y ) = @_;
    $self->pGameCamera->OnMouse( $x, $y );
}

sub main {
    GLUTBackendInit( 1, 0 );

    if ( !GLUTBackendCreateWindow( WINDOW_WIDTH, WINDOW_HEIGHT, 0, "Tutorial 22" ) ) {
        return 1;
    }

    my $pApp = tutorial22->new;

    if ( !$pApp->Init ) {
        return 1;
    }

    $pApp->Run;

    return;
}
