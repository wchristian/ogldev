use strictures;

package camera;

use Moo;
use MooX::Types::MooseLike::Base qw( InstanceOf );
use PDL;    # pdl crossp
use OpenGL qw( glutWarpPointer );
use math_3d;

use ogldev_keys
  qw( OGLDEV_KEY_LEFT OGLDEV_KEY_UP OGLDEV_KEY_RIGHT OGLDEV_KEY_DOWN OGLDEV_KEY_PAGE_UP OGLDEV_KEY_PAGE_DOWN );

use constant STEP_SCALE => 0.1;
use constant EDGE_STEP  => 0.5;
use constant MARGIN     => 10;

has $_ => ( is => 'ro', required => 1 ) for qw( windowWidth windowHeight );

has Pos    => ( is => 'rw', isa => \&isa_pdl, default => sub { pdl [ 0, 0, 0 ] } );
has Target => ( is => 'rw', isa => \&isa_pdl, default => sub { pdl [ 0, 0, 1 ] } );
has Up     => ( is => 'rw', isa => \&isa_pdl, default => sub { pdl [ 0, 1, 0 ] } );
has mousePos => ( is => 'rw', isa => \&isa_pdl, default => sub { pdl [ 0, 1 ] } );

has $_ => ( is => 'rw' ) for qw( AngleH AngleV OnUpperEdge OnLowerEdge OnRightEdge OnLeftEdge );

sub isa_pdl { die "Camera args need to be piddles." if 'PDL' ne ref $_[0] }

sub BUILD {
    my ( $self ) = @_;

    my $target = $self->Target;
    my $HTarget = pdl( $target->at( 0 ), 0.0, $target->at( 2 ) )->norm;

    if ( $HTarget->at( 2 ) >= 0 ) {
        if ( $HTarget->at( 0 ) >= 0 ) {
            $self->AngleH( 360 - math_3d::ToDegree( asin( $HTarget->at( 2 ) ) ) );
        }
        else {
            $self->AngleH( 180 + math_3d::ToDegree( asin( $HTarget->at( 2 ) ) ) );
        }
    }
    else {
        if ( $HTarget->at( 0 ) >= 0 ) {
            $self->AngleH( math_3d::ToDegree( asin( -$HTarget->at( 2 ) ) ) );
        }
        else {
            $self->AngleH( 90 + math_3d::ToDegree( asin( -$HTarget->at( 2 ) ) ) );
        }
    }

    $self->AngleV( -math_3d::ToDegree( asin( $target->at( 1 ) ) ) );

    $self->OnUpperEdge( 0 );
    $self->OnLowerEdge( 0 );
    $self->OnLeftEdge( 0 );
    $self->OnRightEdge( 0 );
    $self->mousePos->set( 0, $self->windowWidth / 2 );
    $self->mousePos->set( 1, $self->windowHeight / 2 );

    return;
}

sub OnKeyboard {
    my ( $self, $key ) = @_;

    my $target = $self->Target;
    my $pos    = $self->Pos;

    if ( $key == OGLDEV_KEY_UP ) {
        $self->Pos( $pos + ( $target * STEP_SCALE ) );
        return 1;
    }

    if ( $key == OGLDEV_KEY_DOWN ) {
        $self->Pos( $pos - ( $target * STEP_SCALE ) );
        return 1;
    }

    if ( $key == OGLDEV_KEY_LEFT ) {
        my $Left = crossp( $target, $self->Up );
        $Left = $Left->norm;
        $Left *= STEP_SCALE;
        $self->Pos( $pos + $Left );
        return 1;
    }

    if ( $key == OGLDEV_KEY_RIGHT ) {
        my $Right = crossp( $self->Up, $target );
        $Right = $Right->norm;
        $Right *= STEP_SCALE;
        $self->Pos( $pos + $Right );
        return;
    }

    if ( $key == OGLDEV_KEY_PAGE_UP ) {
        $pos->set( 1, $pos->at( 1 ) + STEP_SCALE );
        return;
    }

    if ( $key == OGLDEV_KEY_PAGE_DOWN ) {
        $pos->set( 1, $pos->at( 1 ) - STEP_SCALE );
        return;
    }

    return;
}

sub OnMouse {
    my ( $self, $x, $y ) = @_;

    my $DeltaX = $x - $self->mousePos->at( 0 );
    my $DeltaY = $y - $self->mousePos->at( 1 );

    $self->mousePos->set( 0, $x );
    $self->mousePos->set( 1, $y );

    $self->AngleH( $self->AngleH + $DeltaX / 20 );
    $self->AngleV( $self->AngleV + $DeltaY / 20 );

    if ( $DeltaX == 0 ) {
        if ( $x <= MARGIN ) {
            $self->OnLeftEdge( 1 );
        }
        elsif ( $x >= ( $self->windowWidth - MARGIN ) ) {
            $self->OnRightEdge( 1 );
        }
    }
    else {
        $self->OnLeftEdge( 0 );
        $self->OnRightEdge( 0 );
    }

    if ( $DeltaY == 0 ) {
        if ( $y <= MARGIN ) {
            $self->OnUpperEdge( 1 );
        }
        elsif ( $y >= ( $self->windowHeight - MARGIN ) ) {
            $self->OnLowerEdge( 1 );
        }
    }
    else {
        $self->OnUpperEdge( 0 );
        $self->OnLowerEdge( 0 );
    }

    $self->Update;

    return;
}

sub OnRender {
    my ( $self ) = @_;

    my $ShouldUpdate;

    if ( $self->OnLeftEdge ) {
        $self->AngleH( $self->AngleH - EDGE_STEP );
        $ShouldUpdate = 1;
    }
    elsif ( $self->OnRightEdge ) {
        $self->AngleH( $self->AngleH + EDGE_STEP );
        $ShouldUpdate = 1;
    }

    if ( $self->OnUpperEdge ) {
        if ( $self->AngleV > -90 ) {
            $self->AngleV( $self->AngleV - EDGE_STEP );
            $ShouldUpdate = 1;
        }
    }
    elsif ( $self->OnLowerEdge ) {
        if ( $self->AngleV < 90 ) {
            $self->AngleV( $self->AngleV + EDGE_STEP );
            $ShouldUpdate = 1;
        }
    }

    if ( $ShouldUpdate ) {
        $self->Update;
    }
}

sub Update {
    my ( $self ) = @_;

    my $Vaxis = pdl( 0, 1, 0 );

    # Rotate the view vector by the horizontal angle around the vertical axis
    my $View = pdl( 1, 0, 0 );
    $View->rotate( $self->AngleH, $Vaxis );
    $View = $View->norm;

    # Rotate the view vector by the vertical angle around the horizontal axis
    my $Haxis = $Vaxis->crossp( $View );
    $Haxis = $Haxis->norm;
    $View->rotate( $self->AngleV, $Haxis );

    $self->Target( $View->norm );

    $self->Up( $self->Target->crossp( $Haxis ) );
    $self->Up( $self->Up->norm );

    return;
}

1;
