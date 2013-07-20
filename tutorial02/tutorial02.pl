use strictures;

package tutorial02;

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

);

use PDL;    # pdl
use PDL::Core 'howbig';
use B;

my $VBO;

main();

sub RenderSceneCB {
    glClear( GL_COLOR_BUFFER_BIT );

    glEnableVertexAttribArrayARB( 0 );
    glBindBufferARB( GL_ARRAY_BUFFER, $VBO );
    glVertexAttribPointerARB_c( 0, 3, GL_FLOAT, GL_FALSE, 0, 0 );

    glDrawArrays( GL_POINTS, 0, 1 );

    glDisableVertexAttribArrayARB( 0 );

    glutSwapBuffers();

    return;
}

sub InitializeGlutCallbacks {
    glutDisplayFunc( \&RenderSceneCB );
    return;
}

sub CreateVertexBuffer {
    my $v = pdl( 0, 0, 0 )->float;

    $VBO = glGenBuffersARB_p( 1 );
    glBindBufferARB( GL_ARRAY_BUFFER, $VBO );
    glBufferDataARB_s( GL_ARRAY_BUFFER, $v->nelem * howbig( $v->get_datatype ), $v->get_dataref, GL_STATIC_DRAW );

    return;
}

sub main {
    glutInit();
    glutInitDisplayMode( GLUT_DOUBLE | GLUT_RGBA );
    glutInitWindowSize( 1024, 768 );
    glutInitWindowPosition( 100, 100 );
    glutCreateWindow( "Tutorial 02" );

    InitializeGlutCallbacks();

    glClearColor( 0, 0, 0, 0 );

    CreateVertexBuffer();

    glutMainLoop();

    return;
}
