use strictures;

package tutorial23a;

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

  GL_FRAMEBUFFER
  glBindFramebufferEXT
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
use fbo;
use ogldev_keys qw( OGLDEV_KEY_ESCAPE OGLDEV_KEY_q OGLDEV_KEY_a OGLDEV_KEY_s OGLDEV_KEY_z OGLDEV_KEY_x );
use constant ASSERT        => 0;
use constant WINDOW_WIDTH  => 300;
use constant WINDOW_HEIGHT => 187.5;

use Moo;

extends "ICallbacks";

has [qw( pGameCamera VBO_vertex_size VBO_tex_offset VBO_normal_offset VBO pEffect pMesh pQuad fbo )] => ( is => 'rw' );
has scale => ( is => 'rw', default => sub { 0 } );
has spotLight => (
    is      => 'rw',
    default => sub {
        {
            Color            => [ 1,    1,  1 ],
            AmbientIntensity => 0,
            DiffuseIntensity => 0.9,
            Direction        => pdl( 1, -1, 0 ),
            Attenuation => { Linear => 0.01 },
            Position  => [ -20, 20, 5 ],
            Direction => [ 1,   -1, 0 ],
            Cutoff    => 20,
        };
    }
);
has directionalLight => (
    is      => 'rw',
    default => sub {
        {
            Color            => [ 1,    1,  1 ],
            AmbientIntensity => 0.6,
            DiffuseIntensity => 0.01,
            Direction        => pdl( 1, -1, 0 )
        };
    }
);

main();

sub Init {
    my ( $self ) = @_;

    $self->fbo( fbo->new );
    if ( !$self->fbo->Init( WINDOW_WIDTH, WINDOW_HEIGHT ) ) {
        return;
    }

    $self->pGameCamera( camera->new( windowWidth => WINDOW_WIDTH, windowHeight => WINDOW_HEIGHT ) );

    $self->pEffect( BasicLightingTechnique->new );

    if ( !$self->pEffect->Init ) {
        warn "Error initializing the lighting technique";
        return;
    }
    $self->pEffect->Enable;
    $self->pEffect->SetDirectionalLight( $self->directionalLight );

    $self->pQuad( mesh->new );

    if ( !$self->pQuad->LoadMesh( "../Content/quad.obj" ) ) {
        return;
    }

    $self->pMesh( mesh->new );

    return $self->pMesh->LoadMesh( "../Content/phoenix_ugv.md2" );
}

sub Run {
    GLUTBackendRun( shift );
}

sub RenderSceneCB {
    my ( $self ) = @_;

    $self->pGameCamera->OnRender;
    $self->scale( $self->scale + 0.05 );

    $self->fbo->BindForWriting;    # render target
    $self->scene_pass;

    glBindFramebufferEXT( GL_FRAMEBUFFER, 0 );    # render target
    $self->pEffect->SetColorTextureUnit( 0 );
    $self->fbo->BindForReading( GL_TEXTURE0, "color_texture" );
    $self->ui_pass;

    glutSwapBuffers();

    return;
}

sub scene_pass {
    my ( $self ) = @_;

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    my $p = pipeline->new(
        Scale     => [ 0.4, 0.4,          0.4 ],
        Rotate    => [ 0,   $self->scale, 0 ],
        WorldPos  => [ 0,   0,            5 ],
        CameraPos => pdl( $self->spotLight->{Position} ),
        Target    => pdl( $self->spotLight->{Direction} ),
        Up => pdl( [ 0, -1, 0 ] ),
        PerspectiveProj => { FOV => 60, Width => WINDOW_WIDTH, Height => WINDOW_HEIGHT, zNear => 1, zFar => 50 },
    );

    $self->pEffect->SetWVP( $p->GetWVPTrans );
    $self->pMesh->Render;
}

sub ui_pass {
    my ( $self ) = @_;

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    my $p = pipeline->new(
        Scale     => [ 5, 5, 5 ],
        WorldPos  => [ 0, 0, 10 ],
        CameraPos => $self->pGameCamera->Pos,
        Target    => $self->pGameCamera->Target,
        Up        => $self->pGameCamera->Up,
        PerspectiveProj => { FOV => 60, Width => WINDOW_WIDTH, Height => WINDOW_HEIGHT, zNear => 1, zFar => 50 },
    );
    $self->pEffect->SetWVP( $p->GetWVPTrans );
    $self->pQuad->Render;
}

sub KeyboardCB {
    my ( $self, $Key, $x, $y ) = @_;
    my %key_map = (
        OGLDEV_KEY_ESCAPE() => sub { glutLeaveMainLoop() },
        OGLDEV_KEY_q()      => sub { glutLeaveMainLoop() },
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

    if ( !GLUTBackendCreateWindow( WINDOW_WIDTH, WINDOW_HEIGHT, 0, "Tutorial 23a" ) ) {
        return 1;
    }

    my $pApp = tutorial23a->new;

    if ( !$pApp->Init ) {
        return 1;
    }

    $pApp->Run;

    return;
}
