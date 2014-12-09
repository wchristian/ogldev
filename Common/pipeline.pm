use strictures;

package pipeline;

use Moo;
use Pdl;
use camera;

has $_ => ( is => 'rw' )
  for qw( PerspectiveProj WorldTransformation WPtransformation VPtransformation WVPtransformation );
has $_ => ( is => 'rw', default => sub { [ 0, 0, 0 ] } ) for qw( WorldPos Rotate );
has $_ => ( is => 'rw', isa => \&camera::isa_pdl, default => sub { pdl( [ 0, 0, 0 ] ) } ) for qw( CameraPos Target Up );
has Scale => ( is => 'rw', default => sub { [ 1, 1, 1 ] } );
with "math_3d";

sub GetWorldTrans {
    my ( $self ) = @_;

    my $ScaleTrans       = $self->InitScaleTransform( $self->Scale );
    my $RotateTrans      = $self->InitRotateTransform( $self->Rotate );
    my $TranslationTrans = $self->InitTranslationTransform( $self->WorldPos );

    $self->WorldTransformation( $TranslationTrans x $RotateTrans x $ScaleTrans );
    return $self->WorldTransformation;
}

sub GetWPTrans {
    my ( $self ) = @_;

    my $m_Wtransformation = $self->GetWorldTrans;
    my $PersProjTrans     = $self->InitPerspectiveProj( $self->PerspectiveProj );

    $self->WPtransformation( $PersProjTrans x $m_Wtransformation );
    return $self->WPtransformation;
}

sub GetVPTrans {
    my ( $self ) = @_;

    my $CameraTranslationTrans = $self->InitTranslationTransform( [ list( $self->CameraPos * -1 ) ] );
    my $CameraRotateTrans = $self->InitCameraTransform( [ list( $self->Target ) ], [ list( $self->Up ) ] );
    my $PersProjTrans = $self->InitPerspectiveProj( $self->PerspectiveProj );

    $self->VPtransformation( $PersProjTrans x $CameraRotateTrans x $CameraTranslationTrans );
    return $self->VPtransformation;
}

sub GetWVPTrans {
    my ( $self ) = @_;

    my $m_Wtransformation  = $self->GetWorldTrans;
    my $m_VPtransformation = $self->GetVPTrans;

    $self->WVPtransformation( $m_VPtransformation x $m_Wtransformation );
    return $self->WVPtransformation;
}

1;
