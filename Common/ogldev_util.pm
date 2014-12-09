package ogldev_util;

use strictures;
use base "Exporter::Tiny";
use OpenGL qw( glGetError GL_NO_ERROR );

use constant INVALID_UNIFORM_LOCATION => 0xffffffff;
use constant INVALID_OGL_VALUE => 0xffffffff;

our @EXPORT_OK = qw( INVALID_UNIFORM_LOCATION INVALID_OGL_VALUE GLCheckError );

sub GLCheckError { glGetError() == GL_NO_ERROR }

1;
