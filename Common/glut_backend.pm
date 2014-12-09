package glut_backend;

use strictures;

use ogldev_keys qw(
  OGLDEV_KEY_F1
  OGLDEV_KEY_F2
  OGLDEV_KEY_F3
  OGLDEV_KEY_F4
  OGLDEV_KEY_F5
  OGLDEV_KEY_F6
  OGLDEV_KEY_F7
  OGLDEV_KEY_F8
  OGLDEV_KEY_F9
  OGLDEV_KEY_F10
  OGLDEV_KEY_F11
  OGLDEV_KEY_F12
  OGLDEV_KEY_LEFT
  OGLDEV_KEY_UP
  OGLDEV_KEY_RIGHT
  OGLDEV_KEY_DOWN
  OGLDEV_KEY_PAGE_UP
  OGLDEV_KEY_PAGE_DOWN
  OGLDEV_KEY_HOME
  OGLDEV_KEY_END
  OGLDEV_KEY_INSERT
  OGLDEV_KEY_DELETE
  OGLDEV_MOUSE_BUTTON_LEFT
  OGLDEV_MOUSE_BUTTON_RIGHT
  OGLDEV_MOUSE_BUTTON_MIDDLE
  OGLDEV_KEY_STATE_PRESS
  OGLDEV_KEY_STATE_RELEASE
  OGLDEV_KEY_UNDEFINED
  OGLDEV_MOUSE_UNDEFINED
);

use OpenGL qw(
  GLUT_KEY_F1
  GLUT_KEY_F2
  GLUT_KEY_F3
  GLUT_KEY_F4
  GLUT_KEY_F5
  GLUT_KEY_F6
  GLUT_KEY_F7
  GLUT_KEY_F8
  GLUT_KEY_F9
  GLUT_KEY_F10
  GLUT_KEY_F11
  GLUT_KEY_F12
  GLUT_KEY_LEFT
  GLUT_KEY_UP
  GLUT_KEY_RIGHT
  GLUT_KEY_DOWN
  GLUT_KEY_PAGE_UP
  GLUT_KEY_PAGE_DOWN
  GLUT_KEY_HOME
  GLUT_KEY_END
  GLUT_KEY_INSERT
  GLUT_KEY_DELETE
);

use OpenGL::Debug qw(
  GLUT_DOUBLE
  GLUT_RGBA
  GLUT_ACTION_ON_WINDOW_CLOSE
  GLUT_ACTION_GLUTMAINLOOP_RETURNS
  GL_CW
  GL_BACK
  GL_CULL_FACE
  glutInit
  glutInitDisplayMode
  glutSetOption
  glutInitWindowSize
  glutCreateWindow
  glClearColor
  glFrontFace
  glCullFace
  glEnable
  glutDisplayFunc
  glutIdleFunc
  glutSpecialFunc
  glutPassiveMotionFunc
  glutKeyboardFunc
  glutMouseFunc
  glutMainLoop
  glutSwapBuffers

  GLUT_DEPTH
  GL_DEPTH_TEST
  GLUT_STENCIL
  GLUT_DOWN
  GLUT_LEFT_BUTTON
  GLUT_RIGHT_BUTTON
  GLUT_MIDDLE_BUTTON
);

use base 'Exporter';
our @EXPORT = qw( GLUTBackendInit GLUTBackendCreateWindow GLUTBackendRun GLUTKeyToOGLDEVKey );

my $s_pCallbacks;

my $sWithDepth;
my $sWithStencil;

sub GLUTKeyToOGLDEVKey {
    my ( $Key ) = @_;

    my %key_map = (
        GLUT_KEY_F1()        => OGLDEV_KEY_F1,
        GLUT_KEY_F2()        => OGLDEV_KEY_F2,
        GLUT_KEY_F3()        => OGLDEV_KEY_F3,
        GLUT_KEY_F4()        => OGLDEV_KEY_F4,
        GLUT_KEY_F5()        => OGLDEV_KEY_F5,
        GLUT_KEY_F6()        => OGLDEV_KEY_F6,
        GLUT_KEY_F7()        => OGLDEV_KEY_F7,
        GLUT_KEY_F8()        => OGLDEV_KEY_F8,
        GLUT_KEY_F9()        => OGLDEV_KEY_F9,
        GLUT_KEY_F10()       => OGLDEV_KEY_F10,
        GLUT_KEY_F11()       => OGLDEV_KEY_F11,
        GLUT_KEY_F12()       => OGLDEV_KEY_F12,
        GLUT_KEY_LEFT()      => OGLDEV_KEY_LEFT,
        GLUT_KEY_UP()        => OGLDEV_KEY_UP,
        GLUT_KEY_RIGHT()     => OGLDEV_KEY_RIGHT,
        GLUT_KEY_DOWN()      => OGLDEV_KEY_DOWN,
        GLUT_KEY_PAGE_UP()   => OGLDEV_KEY_PAGE_UP,
        GLUT_KEY_PAGE_DOWN() => OGLDEV_KEY_PAGE_DOWN,
        GLUT_KEY_HOME()      => OGLDEV_KEY_HOME,
        GLUT_KEY_END()       => OGLDEV_KEY_END,
        GLUT_KEY_INSERT()    => OGLDEV_KEY_INSERT,
        GLUT_KEY_DELETE()    => OGLDEV_KEY_DELETE,
    );

    my $ogldev_key = $key_map{$Key};
    return $ogldev_key if defined $ogldev_key;

    warn "Unimplemented GLUT key";
    return OGLDEV_KEY_UNDEFINED;
}

sub GLUTMouseToOGLDEVMouse {
    my ( $button ) = @_;

    my %mouse_map = (
        GLUT_LEFT_BUTTON()   => OGLDEV_MOUSE_BUTTON_LEFT,
        GLUT_RIGHT_BUTTON()  => OGLDEV_MOUSE_BUTTON_RIGHT,
        GLUT_MIDDLE_BUTTON() => OGLDEV_MOUSE_BUTTON_MIDDLE,
    );

    my $ogldev_button = $mouse_map{$button};
    return $ogldev_button if defined $ogldev_button;

    warn "Unimplemented GLUT mouse button";
    return OGLDEV_MOUSE_UNDEFINED;
}

sub SpecialKeyboardCB {
    my ( $Key ) = @_;
    my $OgldevKey = GLUTKeyToOGLDEVKey( $Key );
    $s_pCallbacks->KeyboardCB( $OgldevKey );
}

sub KeyboardCB {
    my ( $Key ) = @_;

    die "Unimplemented GLUT key"
      if ( ( $Key < ord '0' ) or ( $Key > ord '9' ) )
      and ( ( $Key < ord 'A' ) or ( $Key > ord 'Z' ) )
      and ( ( $Key < ord 'a' ) or ( $Key > ord 'z' ) );

    $s_pCallbacks->KeyboardCB( $Key );
}

sub PassiveMouseCB {
    my ( $x, $y ) = @_;
    $s_pCallbacks->PassiveMouseCB( $x, $y );
}

sub RenderSceneCB {
    $s_pCallbacks->RenderSceneCB;
}

sub IdleCB {
    $s_pCallbacks->RenderSceneCB;
}

sub MouseCB {
    my ( $Button, $State, $x, $y ) = @_;
    my $OgldevMouse = GLUTMouseToOGLDEVMouse( $Button );
    my $OgldevKeyState = ( $State == GLUT_DOWN ) ? OGLDEV_KEY_STATE_PRESS : OGLDEV_KEY_STATE_RELEASE;

    $s_pCallbacks->MouseCB( $OgldevMouse, $OgldevKeyState, $x, $y );
}

sub InitCallbacks {
    glutDisplayFunc( \&RenderSceneCB );
    glutIdleFunc( \&IdleCB );
    glutSpecialFunc( \&SpecialKeyboardCB );
    glutPassiveMotionFunc( \&PassiveMouseCB );
    glutKeyboardFunc( \&KeyboardCB );
    glutMouseFunc( \&MouseCB );
}

sub GLUTBackendInit {
    my ( $WithDepth, $WithStencil ) = @_;

    $sWithDepth   = $WithDepth;
    $sWithStencil = $WithStencil;

    glutInit();

    my $DisplayMode = GLUT_DOUBLE | GLUT_RGBA;

    if ( $WithDepth ) {
        $DisplayMode |= GLUT_DEPTH;
    }

    if ( $WithStencil ) {
        $DisplayMode |= GLUT_STENCIL;
    }

    glutInitDisplayMode( $DisplayMode );

    glutSetOption( GLUT_ACTION_ON_WINDOW_CLOSE, GLUT_ACTION_GLUTMAINLOOP_RETURNS );
}

sub GLUTBackendCreateWindow {
    my ( $Width, $Height, $isFullScreen, $pTitle ) = @_;

    if ( $isFullScreen ) {
        my $bpp = 32;
        my $ModeString = sprintf "%dx%d@%d", $Width, $Height, $bpp;
        glutGameModeString( $ModeString );
        glutEnterGameMode();
    }
    else {
        glutInitWindowSize( $Width, $Height );
        glutCreateWindow( $pTitle );
    }

    return 1;
}

sub GLUTBackendRun {
    my ( $pCallbacks ) = @_;
    if ( !$pCallbacks ) {
        warn "callbacks not specified!";
        return;
    }

    glClearColor( 0, 0, 0, 0 );
    glFrontFace( GL_CW );
    glCullFace( GL_BACK );
    glEnable( GL_CULL_FACE );

    if ( $sWithDepth ) {
        glEnable( GL_DEPTH_TEST );
    }

    $s_pCallbacks = $pCallbacks;
    InitCallbacks();
    glutMainLoop();
}

sub GLUTBackendSwapBuffers {
    glutSwapBuffers();
}

sub GLUTBackendLeaveMainLoop {
    glutLeaveMainLoop();
}

1;
