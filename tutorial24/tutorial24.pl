use strictures;

package tutorial24;

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
use pipeline;
use camera;
use ogldev_texture;
use LightingTechnique;
use shadow_map_technique;
use glut_backend;
use mesh;
use shadow_map_fbo;
use ogldev_keys qw( OGLDEV_KEY_ESCAPE OGLDEV_KEY_q OGLDEV_KEY_a OGLDEV_KEY_s OGLDEV_KEY_z OGLDEV_KEY_x );
use constant ASSERT        => 0;
use constant WINDOW_WIDTH  => 300;
use constant WINDOW_HEIGHT => 187;

use Moo;

extends "ICallbacks";

has [
    qw( pGameCamera VBO_vertex_size VBO_tex_offset VBO_normal_offset VBO pLightingEffect pMesh pQuad pShadowMapEffect shadowMapFBO pGroundTex )
] => ( is => 'rw' );
has scale => ( is => 'rw', default => sub { 0 } );
has spotLight => (
    is      => 'rw',
    default => sub {
        {
            AmbientIntensity => 0.1,
            DiffuseIntensity => 0.9,
            Color            => [ 1, 1, 1 ],
            Attenuation      => { Linear => 0.01, Constant => 1, Exp => 0 },
            Position  => [ -20, 20, 1 ],
            Direction => [ 1,   -1, 0 ],
            Cutoff    => 20,
        };
    }
);

main();

sub Init {
    my ( $self ) = @_;

    my $Pos    = pdl [ 3, 8,    -10 ];
    my $Target = pdl [ 0, -0.2, 1 ];
    my $Up     = pdl [ 0, 1,    0 ];

    $self->shadowMapFBO( shadow_map_fbo->new );
    if ( !$self->shadowMapFBO->Init( WINDOW_WIDTH, WINDOW_HEIGHT ) ) {
        return;
    }

    $self->pGameCamera(
        camera->new(
            windowWidth  => WINDOW_WIDTH,
            windowHeight => WINDOW_HEIGHT,
            Pos          => $Pos,
            Target       => $Target,
            Up           => $Up
        )
    );

    $self->pLightingEffect( LightingTechnique->new );

    if ( !$self->pLightingEffect->Init ) {
        warn "Error initializing the lighting technique";
        return;
    }

    $self->pLightingEffect->Enable;
    $self->pLightingEffect->SetSpotLights( 1, [ $self->spotLight ] );
    $self->pLightingEffect->SetColorTextureUnit( 0 );
    $self->pLightingEffect->SetShadowMapTextureUnit( 1 );

    $self->pShadowMapEffect( ShadowMapTechnique->new );

    if ( !$self->pShadowMapEffect->Init ) {
        printf( "Error initializing the shadow map technique\n" );
        return;
    }

    $self->pQuad( mesh->new );

    if ( !$self->pQuad->LoadMesh( "../Content/quad.obj" ) ) {
        return;
    }

    $self->pGroundTex( Texture->new( TextureTarget => GL_TEXTURE_2D, FileName => "../Content/test.png" ) );

    if ( !$self->pGroundTex->Load ) {
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

    $self->ShadowMapPass;
    $self->RenderPass;

    glutSwapBuffers();

    return;
}

sub ShadowMapPass {
    my ( $self ) = @_;
    $self->shadowMapFBO->BindForWriting;

    glClear( GL_DEPTH_BUFFER_BIT );

    $self->pShadowMapEffect->Enable;

    my $p = pipeline->new(
        Scale     => [ 0.1, 0.1,          0.1 ],
        Rotate    => [ 0,   $self->scale, 0 ],
        WorldPos  => [ 0,   0,            3 ],
        CameraPos => pdl( $self->spotLight->{Position} ),
        Target    => pdl( $self->spotLight->{Direction} ),
        Up => pdl( [ 0, 1, 0 ] ),
        PerspectiveProj => { FOV => 60, Width => WINDOW_WIDTH, Height => WINDOW_HEIGHT, zNear => 1, zFar => 50 },
    );

    $self->pShadowMapEffect->SetWVP( $p->GetWVPTrans );
    $self->pMesh->Render;

    glBindFramebufferEXT( GL_FRAMEBUFFER, 0 );
}

sub RenderPass {
    my ( $self ) = @_;

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    $self->pLightingEffect->Enable;

    $self->pLightingEffect->SetEyeWorldPos( $self->pGameCamera->Pos );

    $self->shadowMapFBO->BindForReading( GL_TEXTURE1 );

    my $p = pipeline->new(
        PerspectiveProj => { FOV => 60, Width => WINDOW_WIDTH, Height => WINDOW_HEIGHT, zNear => 1, zFar => 50 },
        Scale     => [ 10, 10, 10 ],
        WorldPos  => [ 0,  0,  1 ],
        Rotate    => [ 90, 0,  0 ],
        CameraPos => $self->pGameCamera->Pos,
        Target    => $self->pGameCamera->Target,
        Up        => $self->pGameCamera->Up,
    );

    $self->pLightingEffect->SetWVP( $p->GetWVPTrans );
    $self->pLightingEffect->SetWorldMatrix( $p->GetWorldTrans );

    $p->CameraPos( pdl $self->spotLight->{Position} );
    $p->Target( pdl $self->spotLight->{Direction} );
    $p->Up( pdl [ 0, 1, 0 ] );

    $self->pLightingEffect->SetLightWVP( $p->GetWVPTrans );
    $self->pGroundTex->Bind( GL_TEXTURE0 );

    $self->pQuad->Render;

    $p->Scale( [ 0.1, 0.1, 0.1 ] );
    $p->Rotate( [ 0, $self->scale, 0 ] );
    $p->WorldPos( [ 0, 0, 3 ] );

    $p->CameraPos( $self->pGameCamera->Pos );
    $p->Target( $self->pGameCamera->Target );
    $p->Up( $self->pGameCamera->Up );

    $self->pLightingEffect->SetWVP( $p->GetWVPTrans );
    $self->pLightingEffect->SetWorldMatrix( $p->GetWorldTrans );

    $p->CameraPos( pdl $self->spotLight->{Position} );
    $p->Target( pdl $self->spotLight->{Direction} );
    $p->Up( pdl [ 0, 1, 0 ] );

    $self->pLightingEffect->SetLightWVP( $p->GetWVPTrans );
    $self->pMesh->Render;
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

    if ( !GLUTBackendCreateWindow( WINDOW_WIDTH, WINDOW_HEIGHT, 0, "Tutorial 24" ) ) {
        return 1;
    }

    my $pApp = tutorial24->new;

    if ( !$pApp->Init ) {
        return 1;
    }

    $pApp->Run;

    return;
}
