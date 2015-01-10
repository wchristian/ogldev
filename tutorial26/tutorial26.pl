use strictures;

package tutorial26;

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
  GL_TEXTURE1
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
use engine_common qw( COLOR_TEXTURE_UNIT NORMAL_TEXTURE_UNIT );
use pipeline;
use camera;
use ogldev_texture;
use lighting_technique;
use glut_backend;
use mesh;
use ogldev_keys qw( OGLDEV_KEY_ESCAPE OGLDEV_KEY_q OGLDEV_KEY_a OGLDEV_KEY_s OGLDEV_KEY_z OGLDEV_KEY_x OGLDEV_KEY_b );
use constant ASSERT        => 0;
use constant WINDOW_WIDTH  => 300;
use constant WINDOW_HEIGHT => 187;

use Moo;

extends "ICallbacks";

has [
    qw( pGameCamera VBO_vertex_size VBO_tex_offset VBO_normal_offset VBO
      pLightingTechnique pSphereMesh pTexture pNormalMap pTrivialNormalMap )
] => ( is => 'rw' );
has persProjInfo => (
    is      => 'rw',
    default => sub { { FOV => 60, Width => WINDOW_WIDTH, Height => WINDOW_HEIGHT, zNear => 1, zFar => 100 } }
);
has scale => ( is => 'rw', default => sub { 0 } );
has dirLight => (
    is      => 'rw',
    default => sub {
        {
            AmbientIntensity => 0.2,
            DiffuseIntensity => 0.8,
            Color            => [ 1, 1, 1 ],
            Direction        => pdl [ 1, 0, 0 ],
        };
    }
);
has bumpMapEnabled => ( is => 'rw', default => sub { 1 } );

main();

sub Init {
    my ( $self ) = @_;

    my $Pos    = pdl [ 0.5, 1.025, 0.25 ];
    my $Target = pdl [ 0,   -0.5,  1 ];
    my $Up     = pdl [ 0,   1,     0 ];

    $self->pGameCamera(
        camera->new(
            windowWidth  => WINDOW_WIDTH,
            windowHeight => WINDOW_HEIGHT,
            Pos          => $Pos,
            Target       => $Target,
            Up           => $Up,
        )
    );

    $self->pLightingTechnique( LightingTechnique->new );

    if ( !$self->pLightingTechnique->Init ) {
        warn "Error initializing the lighting technique";
        return;
    }

    $self->pLightingTechnique->Enable;
    $self->pLightingTechnique->SetDirectionalLight( $self->dirLight );
    $self->pLightingTechnique->SetColorTextureUnit( 0 );
    $self->pLightingTechnique->SetNormalMapTextureUnit( 2 );

    $self->pSphereMesh( mesh->new );

    if ( !$self->pSphereMesh->LoadMesh( "../Content/box.obj" ) ) {
        return;
    }

    $self->pTexture( Texture->new( TextureTarget => GL_TEXTURE_2D, FileName => "../Content/bricks.jpg" ) );

    if ( !$self->pTexture->Load ) {
        return;
    }

    $self->pTexture->Bind( COLOR_TEXTURE_UNIT );

    $self->pNormalMap( Texture->new( TextureTarget => GL_TEXTURE_2D, FileName => "../Content/normal_map.jpg" ) );

    if ( !$self->pNormalMap->Load ) {
        return;
    }

    $self->pTrivialNormalMap( Texture->new( TextureTarget => GL_TEXTURE_2D, FileName => "../Content/normal_up.jpg" ) );

    if ( !$self->pTrivialNormalMap->Load ) {
        return;
    }

    return 1;
}

sub Run {
    GLUTBackendRun( shift );
}

sub RenderSceneCB {
    my ( $self ) = @_;

    $self->pGameCamera->OnRender;
    $self->scale( $self->scale + 0.01 );

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    $self->pLightingTechnique->Enable;

    my $p = pipeline->new(
        Rotate          => [ 0, $self->scale, 0 ],
        WorldPos        => [ 0, 0,            3 ],
        CameraPos       => $self->pGameCamera->Pos,
        Target          => $self->pGameCamera->Target,
        Up              => $self->pGameCamera->Up,
        PerspectiveProj => $self->persProjInfo,
    );

    $self->pTexture->Bind( COLOR_TEXTURE_UNIT );

    if ( $self->bumpMapEnabled ) {
        $self->pNormalMap->Bind( NORMAL_TEXTURE_UNIT );
    }
    else {
        $self->pTrivialNormalMap->Bind( NORMAL_TEXTURE_UNIT );
    }

    $self->pLightingTechnique->SetWVP( $p->GetWVPTrans );
    $self->pLightingTechnique->SetWorldMatrix( $p->GetWorldTrans );

    $self->pSphereMesh->Render;

    glutSwapBuffers();

    return;
}

sub KeyboardCB {
    my ( $self, $Key, $x, $y ) = @_;
    my %key_map = (
        OGLDEV_KEY_ESCAPE() => sub { glutLeaveMainLoop() },
        OGLDEV_KEY_q()      => sub { glutLeaveMainLoop() },
        OGLDEV_KEY_b()      => sub { $self->bumpMapEnabled( !$self->bumpMapEnabled ) }
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

    if ( !GLUTBackendCreateWindow( WINDOW_WIDTH, WINDOW_HEIGHT, 0, "Tutorial 26" ) ) {
        return 1;
    }

    my $pApp = tutorial26->new;

    if ( !$pApp->Init ) {
        return 1;
    }

    $pApp->Run;

    return;
}
