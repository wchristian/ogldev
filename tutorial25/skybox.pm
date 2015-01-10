package SkyBox;

use strictures;

use Moo;
use OpenGL::Debug qw(
    GL_CULL_FACE_MODE GL_DEPTH_FUNC GL_FRONT GL_LEQUAL GL_TEXTURE0
    glGetIntegerv_p glCullFace glDepthFunc
);
use SkyboxTechnique;
use CubemapTexture;
use mesh;
use pipeline;
use PDL 'list';

has $_ => ( is => 'ro', required => 1 ) for qw( pGameCamera persProjInfo );

has $_ => ( is => 'rw' ) for qw( pSkyboxTechnique pCubemapTex pMesh );

sub Init {
    my ( $self, $Directory, $PosXFilename, $NegXFilename, $PosYFilename, $NegYFilename, $PosZFilename, $NegZFilename )
      = @_;

    $self->pSkyboxTechnique( SkyboxTechnique->new );

    if ( !$self->pSkyboxTechnique->Init ) {
        warn "Error initializing the skybox technique\n";
        return;
    }

    $self->pSkyboxTechnique->Enable;
    $self->pSkyboxTechnique->SetTextureUnit( 0 );

    $self->pCubemapTex(
        CubemapTexture->new(
            Directory    => $Directory,
            PosXFilename => $PosXFilename,
            NegXFilename => $NegXFilename,
            PosYFilename => $PosYFilename,
            NegYFilename => $NegYFilename,
            PosZFilename => $PosZFilename,
            NegZFilename => $NegZFilename,
        )
    );

    if ( !$self->pCubemapTex->Load ) {
        return;
    }

    $self->pMesh( mesh->new );

    return $self->pMesh->LoadMesh( "../Content/sphere.obj" );
}

sub Render {
    my ( $self ) = @_;

    $self->pSkyboxTechnique->Enable;

    my $OldCullFaceMode  = glGetIntegerv_p( GL_CULL_FACE_MODE );
    my $OldDepthFuncMode = glGetIntegerv_p( GL_DEPTH_FUNC );

    glCullFace( GL_FRONT );
    glDepthFunc( GL_LEQUAL );

    my $p = pipeline->new(
        Scale           => [ 20, 20, 20 ],
        Rotate          => [ 0,  0,  0 ],
        WorldPos        => [ list( $self->pGameCamera->Pos ) ],
        CameraPos       => $self->pGameCamera->Pos,
        Target          => $self->pGameCamera->Target,
        Up              => $self->pGameCamera->Up,
        PerspectiveProj => $self->persProjInfo,
    );

    $self->pSkyboxTechnique->SetWVP( $p->GetWVPTrans );
    $self->pCubemapTex->Bind( GL_TEXTURE0 );
    $self->pMesh->Render;

    glCullFace( $OldCullFaceMode );
    glDepthFunc( $OldDepthFuncMode );

    return;
}

1;
