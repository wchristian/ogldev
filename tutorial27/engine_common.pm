package engine_common;

use strictures;
use base "Exporter::Tiny";
use OpenGL qw( GL_TEXTURE0 GL_TEXTURE1 GL_TEXTURE2 );

use constant COLOR_TEXTURE_UNIT  => GL_TEXTURE0;
use constant SHADOW_TEXTURE_UNIT => GL_TEXTURE1;
use constant NORMAL_TEXTURE_UNIT => GL_TEXTURE2;

our @EXPORT_OK = qw( COLOR_TEXTURE_UNIT SHADOW_TEXTURE_UNIT NORMAL_TEXTURE_UNIT );

1;
