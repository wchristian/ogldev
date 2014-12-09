use strictures;

package tutorial20;

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
);

use 5.010;

use PDL;
use PDL::Core 'howbig';
use lib '../Common';
use pipeline;
use camera;
use ogldev_texture;
use lighting_technique;
use glut_backend;
use ogldev_keys qw( OGLDEV_KEY_ESCAPE OGLDEV_KEY_q OGLDEV_KEY_a OGLDEV_KEY_s OGLDEV_KEY_z OGLDEV_KEY_x );
use constant ASSERT        => 0;
use constant WINDOW_WIDTH  => 300;
use constant WINDOW_HEIGHT => 300;
use constant FieldDepth    => 20;
use constant FieldWidth    => 10;

use Moo;

extends "ICallbacks";

has $_ => ( is => 'rw' ) for qw( pGameCamera VBO_vertex_size VBO_tex_offset VBO_normal_offset VBO pEffect pTexture );
has scale => ( is => 'rw', default => sub { 0 } );
has directionalLight => (
    is      => 'rw',
    default => sub {
        {
            Color            => [ 1,    1,  1 ],
            AmbientIntensity => 0,
            DiffuseIntensity => 0.01,
            Direction        => pdl( 1, -1, 0 )
        };
    }
);

main();

sub Init {
    my ( $self ) = @_;

    my $Pos    = pdl( 5, 1, -3 );
    my $Target = pdl( 0, 0, 1 );
    my $Up     = pdl( 0, 1, 0 );

    $self->pGameCamera(
        camera->new(
            windowWidth  => WINDOW_WIDTH,
            windowHeight => WINDOW_HEIGHT,
            Pos          => $Pos,
            Target       => $Target,
            Up           => $Up
        )
    );

    $self->CreateVertexBuffer;

    $self->pEffect( LightingTechnique->new );

    if ( !$self->pEffect->Init ) {
        warn "Error initializing the lighting technique";
        return;
    }

    $self->pEffect->Enable;

    $self->pEffect->SetTextureUnit( 0 );

    $self->pTexture( Texture->new( TextureTarget => GL_TEXTURE_2D, FileName => "../Content/test.png" ) );

    if ( !$self->pTexture->Load ) {
        return;
    }

    return 1;
}

sub Run {
    GLUTBackendRun( shift );
}

sub RenderSceneCB {
    my ( $self ) = @_;

    $self->scale( $self->scale + 0.0057 );

    $self->pGameCamera->OnRender;

    glClear( GL_COLOR_BUFFER_BIT );

    my @pl = (
        {
            DiffuseIntensity => 0.5,
            Color            => [ 1, 0.5, 0 ],
            Position         => [ 3, 1, FieldDepth * ( cos( $self->scale ) + 1 ) / 2 ],
            Attenuation      => { Linear => 0.1, Constant => 1, Exp => 0 },
            AmbientIntensity => 0,
        },
        {
            DiffuseIntensity => 0.5,
            Color            => [ 0, 0.5, 1 ],
            Position         => [ 7, 1, FieldDepth * ( sin( $self->scale ) + 1 ) / 2 ],
            Attenuation      => { Linear => 0.1, Constant => 1, Exp => 0 },
            AmbientIntensity => 0,
        }
    );
    $self->pEffect->SetPointLights( 2, \@pl );

    my $p = pipeline->new(
        WorldPos  => [ 0, 0, 1 ],
        CameraPos => $self->pGameCamera->Pos,
        Target    => $self->pGameCamera->Target,
        Up        => $self->pGameCamera->Up,
        PerspectiveProj => { FOV => 60, Width => WINDOW_WIDTH, Height => WINDOW_HEIGHT, zNear => 1, zFar => 100 },
    );

    $self->pEffect->SetWVP( $p->GetWVPTrans );
    my $WorldTransformation = $p->GetWorldTrans;
    $self->pEffect->SetWorldMatrix( $WorldTransformation );
    $self->pEffect->SetDirectionalLight( $self->directionalLight );
    $self->pEffect->SetEyeWorldPos( $self->pGameCamera->Pos );
    $self->pEffect->SetMatSpecularIntensity( 0 );
    $self->pEffect->SetMatSpecularPower( 0 );

    glEnableVertexAttribArrayARB( 0 );
    glEnableVertexAttribArrayARB( 1 );
    glEnableVertexAttribArrayARB( 2 );
    glBindBufferARB( GL_ARRAY_BUFFER, $self->VBO );
    glVertexAttribPointerARB_c( 0, 3, GL_FLOAT, GL_FALSE, $self->VBO_vertex_size, 0 );
    glVertexAttribPointerARB_c( 1, 2, GL_FLOAT, GL_FALSE, $self->VBO_vertex_size, $self->VBO_tex_offset );
    glVertexAttribPointerARB_c( 2, 3, GL_FLOAT, GL_FALSE, $self->VBO_vertex_size, $self->VBO_normal_offset );
    $self->pTexture->Bind( GL_TEXTURE0 );
    glDrawArrays( GL_TRIANGLES, 0, 6 );

    glDisableVertexAttribArrayARB( 0 );
    glDisableVertexAttribArrayARB( 1 );
    glDisableVertexAttribArrayARB( 2 );

    glutSwapBuffers();

    return;
}

sub KeyboardCB {
    my ( $self, $Key, $x, $y ) = @_;
    glutLeaveMainLoop() if $Key == OGLDEV_KEY_ESCAPE or $Key == OGLDEV_KEY_q;
    $self->directionalLight->{AmbientIntensity} += 0.05 if $Key == OGLDEV_KEY_a;
    $self->directionalLight->{AmbientIntensity} -= 0.05 if $Key == OGLDEV_KEY_s;
    $self->directionalLight->{DiffuseIntensity} += 0.05 if $Key == OGLDEV_KEY_z;
    $self->directionalLight->{DiffuseIntensity} -= 0.05 if $Key == OGLDEV_KEY_x;
}

sub PassiveMouseCB {
    my ( $self, $x, $y ) = @_;
    $self->pGameCamera->OnMouse( $x, $y );
}

sub CreateVertexBuffer {
    my ( $self ) = @_;

    my @normal = ( 0, 1, 0 );

    my $v = pdl(    #
        [ 0,          0, 0,          0, 0, @normal ],
        [ 0,          0, FieldDepth, 0, 1, @normal ],
        [ FieldWidth, 0, 0,          1, 0, @normal ],

        [ FieldWidth, 0, 0,          1, 0, @normal ],
        [ 0,          0, FieldDepth, 0, 1, @normal ],
        [ FieldWidth, 0, FieldDepth, 1, 1, @normal ],
    )->float;

    my $type_size = howbig( $v->get_datatype );
    $self->VBO_vertex_size( $v->dim( 0 ) * $type_size );
    $self->VBO_tex_offset( 3 * $type_size );
    $self->VBO_normal_offset( 5 * $type_size );

    $self->VBO( glGenBuffersARB_p( 1 ) );
    glBindBufferARB( GL_ARRAY_BUFFER, $self->VBO );
    glBufferDataARB_s(
        GL_ARRAY_BUFFER,    #
        $v->nelem * $type_size,
        $v->get_dataref,
        GL_STATIC_DRAW,
    );

    return;
}

sub main {
    GLUTBackendInit( 0, 0 );

    if ( !GLUTBackendCreateWindow( WINDOW_WIDTH, WINDOW_HEIGHT, 0, "Tutorial 20" ) ) {
        return 1;
    }

    my $pApp = tutorial20->new;

    if ( !$pApp->Init ) {
        return 1;
    }

    $pApp->Run;

    return;
}
