use strictures;

package tutorial01;

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
);

main();

sub RenderSceneCB {
    glClear( GL_COLOR_BUFFER_BIT );
    glutSwapBuffers();
    return;
}

sub InitializeGlutCallbacks {
    glutDisplayFunc( \&RenderSceneCB );
    return;
}

sub main {
    glutInit();
    glutInitDisplayMode( GLUT_DOUBLE | GLUT_RGBA );
    glutInitWindowSize( 1024, 768 );
    glutInitWindowPosition( 100, 100 );
    glutCreateWindow( "Tutorial 01" );

    InitializeGlutCallbacks();

    glClearColor( 0, 0, 0, 0 );

    glutMainLoop();

    return;
}
