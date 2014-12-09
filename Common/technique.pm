use strictures;

package Technique;

use Moo;

use lib '../arcsyn/framework';
use OpenGL::Debug qw(
  GL_COMPILE_STATUS
  GL_LINK_STATUS
  GL_VALIDATE_STATUS
  GL_NO_ERROR
  glCreateProgramObjectARB
  glCreateShaderObjectARB
  glShaderSourceARB_p
  glCompileShaderARB
  glGetShaderiv_p
  glAttachShader
  glLinkProgramARB
  glGetProgramiv_p
  glValidateProgramARB
  glGetProgramiv_p
  glDeleteShader
  glGetUniformLocationARB_p
  glUseProgramObjectARB
  glGetError
  glGetShaderInfoLog_p
);

use IO::All -binary;

use ogldev_util qw( INVALID_UNIFORM_LOCATION GLCheckError );

has shaderProg    => ( is => 'rw', default => sub { 0 } );
has shaderObjList => ( is => 'rw', default => sub { [] } );

sub DESTROY {
    my ( $self ) = @_;

    # Delete the intermediate shader objects that have been added to the program
    # The list will only contain something if shaders were compiled but the object itself
    # was destroyed prior to linking.
    for my $shader ( @{ $self->shaderObjList } ) {
        glDeleteShader( $shader );
    }

    if ( $self->shaderProg != 0 ) {
        glDeleteProgram( $self->shaderProg );
        $self->shaderProg( 0 );
    }
}

sub Init {
    my ( $self ) = @_;

    $self->shaderProg( glCreateProgramObjectARB() );

    if ( $self->shaderProg == 0 ) {
        warn "Error creating shader program";
        return;
    }

    return GLCheckError();
}

# Use this method to add shaders to the program. When finished - call finalize()
sub AddShader {
    my ( $self, $ShaderType, $pFilename ) = @_;

    my $s = io( $pFilename )->all;
    return if !$s;

    my $ShaderObj = glCreateShaderObjectARB( $ShaderType );

    if ( $ShaderObj == 0 ) {
        warn "Error creating shader type $ShaderType";
        return;
    }

    # Save the shader object - will be deleted in the destructor
    push @{ $self->shaderObjList }, $ShaderObj;

    glShaderSourceARB_p( $ShaderObj, $s );

    glCompileShaderARB( $ShaderObj );

    my $success = glGetShaderiv_p( $ShaderObj, GL_COMPILE_STATUS );

    if ( !$success ) {
        my $InfoLog = glGetShaderInfoLog_p( $ShaderObj );
        warn "Error compiling '$pFilename': '$InfoLog'",;
        return;
    }

    glAttachShader( $self->shaderProg, $ShaderObj );

    return 1;
}

# After all the shaders have been added to the program call this function
# to link and validate the program.
sub Finalize {
    my ( $self ) = @_;

    glLinkProgramARB( $self->shaderProg );

    my $Success = glGetProgramiv_p( $self->shaderProg, GL_LINK_STATUS );
    if ( $Success == 0 ) {
        my $ErrorLog = glGetInfoLogARB_p( $self->shaderProg );
        warn "Error linking shader program: '$ErrorLog'";
        return;
    }

    glValidateProgramARB( $self->shaderProg );
    $Success = glGetProgramiv_p( $self->shaderProg, GL_VALIDATE_STATUS );
    if ( !$Success ) {
        my $ErrorLog = glGetInfoLogARB_p( $self->shaderProg );
        warn "Invalid program: '$ErrorLog'";
        return;
    }

    # Delete the intermediate shader objects that have been added to the program
    for my $shader ( @{ $self->shaderObjList } ) {
        glDeleteShader( $shader );
    }

    $self->shaderObjList( [] );

    return 1;
}

sub Enable {
    glUseProgramObjectARB( shift->shaderProg );
}

sub GetUniformLocation {
    my ( $self, $pUniformName ) = @_;

    my $Location = glGetUniformLocationARB_p( $self->shaderProg, $pUniformName );

    if ( $Location == INVALID_UNIFORM_LOCATION ) {
        warn "Warning! Unable to get the location of uniform '$pUniformName'";
    }

    return $Location;
}

sub GetProgramParam { glGetProgramiv_p( shift->shaderProg, shift ) }

1;
