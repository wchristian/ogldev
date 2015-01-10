package mesh;

use strictures;

use IO::All;
use JSON;
use OpenGL::Debug qw(
  GL_TEXTURE_2D
  GL_ARRAY_BUFFER
  GL_FLOAT
  GL_FALSE
  GL_ELEMENT_ARRAY_BUFFER
  GL_TEXTURE0
  GL_UNSIGNED_INT
  GL_TRIANGLES
  glEnableVertexAttribArrayARB
  glBindBufferARB
  glVertexAttribPointerARB_c
  glDrawElements_c
  glDisableVertexAttribArrayARB
);
use MeshEntry;
use PDL;
use PDL::Core 'howbig';
use engine_common qw( COLOR_TEXTURE_UNIT );

use Moo;

has [qw( Entries Textures )] => ( is => 'rw', default => sub { [] } );
has [qw( VBO_vertex_size VBO_tex_offset VBO_normal_offset VBO_tangent_offset )] => ( is => 'rw' );

sub Clear { }

sub LoadMesh {
    my ( $self, $Filename ) = @_;

    # Release the previously loaded mesh (if it exists)
    $self->Clear;

    system( "d:\\cpan\\ogldev\\assimp2json-2.0-win32\\assimp2json.exe $Filename $Filename.json" )
      if !-f "$Filename.json";

    my $pScene = decode_json io( "$Filename.json" )->all;

    return $self->InitFromScene( $pScene, $Filename );
}

sub InitFromScene {
    my ( $self, $pScene, $Filename ) = @_;

    # Initialize the meshes in the scene one by one
    for my $i ( 0 .. $#{ $pScene->{meshes} } ) {
        my $paiMesh = $pScene->{meshes}[$i];
        $self->InitMesh( $i, $paiMesh );
    }

    return $self->InitMaterials( $pScene, $Filename );
}

sub InitMesh {
    my ( $self, $Index, $paiMesh ) = @_;

    my $materialindex = $paiMesh->{materialindex};

    my @Vertices;
    my @Indices;

    my $Zero2D = [ 0, 0 ];

    for my $i ( 0 .. ( @{ $paiMesh->{vertices} } / 3 ) - 1 ) {
        my $i3d     = $i * 3;
        my $i2d     = $i * 2;
        my $pPos    = [ map $paiMesh->{vertices}[$_], $i3d, $i3d + 1, $i3d + 2 ];
        my $pNormal = [ map $paiMesh->{normals}[$_], $i3d, $i3d + 1, $i3d + 2 ];
        my $pTexCoord =
          $paiMesh->{texturecoords}[0] ? [ map $paiMesh->{texturecoords}[0][$_], $i2d, $i2d + 1 ] : $Zero2D;
        my $pTangent = [ map $paiMesh->{tangents}[$_], $i3d, $i3d + 1, $i3d + 2 ];

        my $v = [ @$pPos, @$pTexCoord, @$pNormal, @$pTangent ];
        push @Vertices, $v;
    }

    for my $i ( 0 .. $#{ $paiMesh->{faces} } ) {
        my $Face = $paiMesh->{faces}[$i];
        die if @$Face != 3;
        push @Indices, @{$Face};
    }

    $self->Entries->[$Index] = MeshEntry->new( MaterialIndex => $materialindex );
    my $vertices  = pdl( @Vertices )->float;
    my $type_size = howbig( $vertices->get_datatype );
    $self->VBO_vertex_size( $vertices->dim( 0 ) * $type_size );
    $self->VBO_tex_offset( 3 * $type_size );
    $self->VBO_normal_offset( 5 * $type_size );
    $self->VBO_tangent_offset( 8 * $type_size );
    my $indices = pdl( @Indices )->long;
    $self->Entries->[$Index]->Init( $vertices, $indices );
}

sub GetTexture {
    my ( $material, $type, $index ) = @_;
    my $path_prop = ( GetTextures( $material, '$tex.file' ) )[$index];
    return $path_prop->{value};
}

sub GetTextures {
    my ( $material, $type ) = @_;
    return grep { $_->{key} eq $type } @{ $material->{properties} };
}

sub GetTextureCount { scalar GetTextures( @_ ) }

sub InitMaterials {
    my ( $self, $pScene, $Filename ) = @_;

    # Extract the directory part from the file name
    my $Dir = io->catpath( ( io( $Filename )->splitpath )[ 0 .. 1 ] );

    my $Ret = 1;

    # Initialize the materials
    for my $i ( 0 .. $#{ $pScene->{materials} } ) {
        my $pMaterial = $pScene->{materials}[$i];

        if ( GetTextureCount( $pMaterial, '$clr.diffuse' ) > 0 ) {
            if ( my $Path = GetTexture( $pMaterial, '$clr.diffuse', 0 ) ) {
                my $FullPath = $Dir . "/" . $Path;
                $self->Textures->[$i] = Texture->new( TextureTarget => GL_TEXTURE_2D, FileName => $FullPath );

                if ( !$self->Textures->[$i]->Load ) {
                    warn "Error loading texture '$FullPath'";
                    $Ret = 0;
                }
                else {
                    printf "Loaded texture '%s'\n", $FullPath;
                }
            }
        }
    }

    return $Ret;
}

sub Render {
    my ( $self ) = @_;

    glEnableVertexAttribArrayARB( 0 );
    glEnableVertexAttribArrayARB( 1 );
    glEnableVertexAttribArrayARB( 2 );
    glEnableVertexAttribArrayARB( 3 );

    for my $i ( 0 .. $#{ $self->Entries } ) {
        glBindBufferARB( GL_ARRAY_BUFFER, $self->Entries->[$i]->VB );
        my @base = ( GL_FLOAT, GL_FALSE, $self->VBO_vertex_size );
        glVertexAttribPointerARB_c( 0, 3, @base, 0 );                            # position
        glVertexAttribPointerARB_c( 1, 2, @base, $self->VBO_tex_offset );        # texture coordinate
        glVertexAttribPointerARB_c( 2, 3, @base, $self->VBO_normal_offset );     # normal
        glVertexAttribPointerARB_c( 3, 3, @base, $self->VBO_tangent_offset );    # tangent

        glBindBufferARB( GL_ELEMENT_ARRAY_BUFFER, $self->Entries->[$i]->IB );

        my $MaterialIndex = $self->Entries->[$i]->MaterialIndex;

        if ( $MaterialIndex < @{ $self->Textures } and $self->Textures->[$MaterialIndex] ) {
            $self->Textures->[$MaterialIndex]->Bind( COLOR_TEXTURE_UNIT );
        }

        glDrawElements_c( GL_TRIANGLES, $self->Entries->[$i]->NumIndices, GL_UNSIGNED_INT, 0 );
    }

    glDisableVertexAttribArrayARB( 0 );
    glDisableVertexAttribArrayARB( 1 );
    glDisableVertexAttribArrayARB( 2 );
    glDisableVertexAttribArrayARB( 3 );
}

1;
